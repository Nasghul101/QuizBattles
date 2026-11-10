## Context

- Matches live in Firestore `matches/{id}`. `UserDatabase.create_match()` builds the document on the client, and `firestore.rules` only lets participants read or write a match (`participant_uids`). One client therefore cannot create a match for two players.
- `functions/index.js` already hosts HTTP functions (`processMatchStatistics`, `sendFeedback`) that `UserDatabase` calls with an auth token.
- `LiveUpdateService` polls notifications, friends and matches every 5 s and emits `GlobalSignalBus.matches_changed` when a match changes.
- `challenge_page.gd` is a stub with a `MatchContainer` (VBoxContainer) that currently holds one `FaceRandomOpponent` instance of `face_random_opponent_display_component` (a `TextureRect` with `NameP1`, `ScoreP1`, `NameP2`, `ScoreP2`, `RoundLabel`, `FaceOpponentLabel`, `ButtonBGHighlighted` and the button). The `CHALLENGE_SCREEN_*` translation keys already exist.
- `friendly_battle_page.gd` lists every match of the player, including future random matches. Its score and opponent helpers are private to that page.

## Goals / Non-Goals

**Goals:**
- Atomic pairing of two waiting players into a 5x3 match, last presser first.
- Automatic 24h expiry of unanswered searches.
- The four card states on the challenge page, kept current by the existing live updates.

**Non-Goals:**
- Manual search cancel (decided out of scope).
- Several random matches at the same time, one waiting search at a time.
- Changing the gameplay screen or round logic.

## Decisions

1. **Pairing in a Cloud Function.** A new HTTP function `findRandomOpponent` (same style and auth-token check as `processMatchStatistics`) runs a Firestore transaction. It reads the oldest unexpired search not owned by the caller and not owned by a player the caller has an active match with (any mode, status `active`; read from the caller's `matches` inside the transaction). If one exists, it deletes that search and writes the match. Otherwise it writes the caller's search. This keeps the match write server-side and makes pairing race-safe. Alternative (client-side transaction) was rejected: the rules would have to let a player write someone else's match.
2. **Search document.** `random_searches/{uid}`: `uid`, `username`, `created_at`. Keying by uid makes a double press idempotent (no second search). The rules let a user read only their own document and forbid client writes.
3. **Expiry.** A scheduled function (`onSchedule`, hourly) deletes searches older than 24h. `findRandomOpponent` also ignores and deletes searches older than 24h, so expiry is correct even between scheduler runs.
4. **Match shape.** The function builds the same document shape as `create_match()`, with `config` 5/3, `mode: "random"`, and `inviter` and `current_turn` set to the caller (last presser). Round category choosers follow the existing alternation from the inviter. Existing matches have no `mode`; readers treat a missing value as `friend`.
5. **Client API.** `UserDatabase.find_random_opponent()` calls the function and returns `{status: "searching" | "matched", match_id?}`. `UserDatabase.has_random_search()` reads the player's own search document.
6. **Live updates.** The challenge page refreshes on `matches_changed`, on page visibility, and after the button press. `LiveUpdateService` also polls the player's own search document so the searching state ends when the search is paired or expires. Pairing makes a new match appear, which already triggers `matches_changed`.
7. **One component, two roles.** `face_random_opponent_display_component` implements all four states and emits a pressed signal. The challenge page always keeps one search card (state 1, or state 2 while searching) and one match card per active `mode == "random"` match (state 3 or 4 from `current_turn`). Cards are keyed by `match_id`: existing cards are updated, new matches get a new instance, finished matches free their card. When pairing succeeds, the search card returns to state 1. Pressing the search card in state 1 calls the function. Pressing a match card opens that match through `TransitionManager`.
8. **Separation from the friend list.** `friendly_battle_page.gd` skips `mode == "random"` matches. The score helper is shared (moved to a small static helper) rather than copied.
9. **Rules.** `firestore.rules` adds `random_searches` (read own, no client write). The matches `create` rule stays unchanged, because the function uses the Admin SDK.

## Risks / Trade-offs

- Polling (5 s) means state changes show with a short delay. This matches the rest of the app.
- Only `active` random matches get a card. When a random match finishes, its card is removed. Showing the result of a finished random match is out of scope here.
- Hourly scheduling needs the Firebase Blaze plan and the Cloud Scheduler API. Lazy expiry in `findRandomOpponent` limits the damage if the scheduler is not deployed.
- Players can never cancel a search; an abandoned search holds a slot for up to 24h, which is accepted by the requirement.
- Exclusion is checked only when a player presses the button. If A waits and B (an active opponent of A) searches, both end up with a waiting search and are not re-paired automatically when their match finishes; one of them has to search again. The search scan is capped at 100 documents.
