## Why

The challenge page has a "Face random Opponent" card, but it does nothing. Players without friends online cannot start a duel. Random matchmaking gives them an opponent. Players should also be able to play several random matches at the same time, so each match needs its own card.

## What Changes

- Add a random-opponent search queue. Pressing the search card's button creates a search for the signed-in player, or pairs them with a waiting search.
- When a second player presses the button, a 5-round / 3-question match is created for the two players. The player who pressed last plays first.
- Searches that wait more than 24 hours are cancelled automatically. There is no manual cancel.
- Pairing and expiry run in Cloud Functions. Firestore rules do not let a client write a match for another player.
- `face_random_opponent_display_component` becomes the single card component with four states (idle, searching, opponent's turn, your turn).
- `challenge_page` always shows one search card (idle or searching). When an opponent is found, the search card resets to idle and a new card is instantiated for the match. The match card is removed when the match finishes, so several random matches can run at once.
- Matches carry a `mode` marker (`random`) so the challenge page can find its random matches and the friendly battle page can skip them.

## Capabilities

### New Capabilities
- `random-opponent-matchmaking`: search queue, atomic pairing, 24h expiry, and the `UserDatabase` API used by the client.
- `random-opponent-display-component`: the card component, its four states, and how the challenge page adds and removes cards.

### Modified Capabilities
- `multiplayer-match-system`: matches created by matchmaking use a `mode` field, the last-pressing player takes the first turn, and the config is fixed at 5 rounds and 3 questions.

## Impact

- Code: new logic in `scenes/ui/components/face_random_opponent_display_component.gd` and `.tscn`, `scenes/ui/lobby_pages/challenge_page.gd` and `.tscn`, `autoload/user_database.gd`, `autoload/live_update_service.gd`, `functions/index.js`, `firestore.rules`.
- Tests: `tests/firebase/firestore_rules.test.mjs` and the emulator tests.
- Backend: new Firestore collection `random_searches`, two Cloud Functions (pairing, scheduled expiry).
- Localization: the `CHALLENGE_SCREEN_*` keys already exist in `localization/ui_translations.csv`; no new keys are needed.
