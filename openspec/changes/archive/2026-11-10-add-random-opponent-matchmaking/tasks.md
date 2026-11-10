## 1. Backend

- [x] 1.1 Add `random_searches/{uid}` rules to `firestore.rules`: owner can read, no client create/update/delete
- [x] 1.2 Add `findRandomOpponent` HTTP function in `functions/index.js`: verify auth token, run the pairing transaction, ignore and delete searches older than 24h; an existing own search is left unchanged
- [x] 1.3 Build the paired match in the function with `mode: "random"`, 5 rounds / 3 questions, caller as `inviter` and `current_turn`, `participant_uids` of both players; skip searches of players who share an active match with the caller
- [x] 1.4 Add a scheduled function that deletes searches older than 24h
- [x] 1.5 Add rules tests in `tests/firebase/firestore_rules.test.mjs` for `random_searches` access

## 2. Client data layer

- [x] 2.1 Add `UserDatabase.find_random_opponent()` (calls the function, returns searching/matched) and `UserDatabase.has_random_search()`
- [x] 2.2 Make `LiveUpdateService` also detect changes of the player's own search document and emit `matches_changed`
- [x] 2.3 Treat a missing `mode` as `friend`; skip `random` matches in `friendly_battle_page.gd`
- [x] 2.4 Move the score and opponent-name helpers to a shared helper used by the friendly battle page and the card component

## 3. face_random_opponent_display_component

- [x] 3.1 Add setters for the four states: idle, searching, opponent's turn, player's turn (visibility of `ScoreP1`, `NameP2`, `ScoreP2`, `RoundLabel`, `ButtonBGHighlighted`, `FaceOpponentLabel` text with `CHALLENGE_SCREEN_*`, button disabled flag)
- [x] 3.2 Show the player's name in `NameP1` in every state
- [x] 3.3 Add a match setup function that takes a match Dictionary, fills names, scores and round, and picks state 3 or 4 from `current_turn`
- [x] 3.4 Emit a signal when the button is pressed (search card: start search; match card: open its match) instead of handling it inside the card

## 4. Challenge page

- [x] 4.1 In `challenge_page.gd`, keep one search card (idle or searching) in `MatchContainer`; on press call `UserDatabase.find_random_opponent()` and set the searching state
- [x] 4.2 Instantiate one match card per active `mode == "random"` match, keyed by `match_id`; update an existing card instead of re-creating it
- [x] 4.3 When a search is paired, add the new match card and reset the search card to idle; when a match finishes, free its card
- [x] 4.4 Open the card's match through `TransitionManager` when a match card is pressed
- [x] 4.5 Refresh on `matches_changed`, on page visibility, and when the user signs in or out
- [x] 4.6 Keep the search card first in `MatchContainer`

## 5. Verification

- [x] 5.1 Emulator test: two users pressing the button create one match, last presser has `current_turn`, config is 5/3, search is removed
- [x] 5.2 Emulator test: search older than 24h is ignored and expired
- [x] 5.3 Emulator test: players with an active match are not paired with each other, can pair with others, and can pair again once the match is finished
- [x] 5.4 Manual check of the four card states and of several simultaneous matches with multiple accounts
- [x] 5.5 Update `docs/firebase_emulators.md` if function emulation needs new setup
