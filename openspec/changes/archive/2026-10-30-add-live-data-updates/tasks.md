## 1. Signals

- [x] 1.1 Add `notifications_changed`, `friends_changed`, `matches_changed` with `##` docs to `autoload/global_signal_bus.gd`

## 2. LiveUpdateService

- [x] 2.1 Create `autoload/live_update_service.gd` (static typed, UID line) and register it in `project.godot`
- [x] 2.2 Implement 5 s Timer, in-flight guard, backoff (max 30 s), start/stop on sign-in/out, poll on focus regain (`NOTIFICATION_APPLICATION_FOCUS_IN`)
- [x] 2.3 Implement snapshot diffing with silent baseline and emit signals on change

## 3. Screens

- [x] 3.1 `main_lobby_screen.gd`: connect to `notifications_changed`, instantiate added / remove removed components, update indicator; disconnect in `_exit_tree`
- [x] 3.2 `socials_page.gd`, `friendly_battle_page.gd`, `duel_page.gd`: refresh friends/matches on `friends_changed`/`matches_changed`, idempotently

## 4. Tests and docs

- [x] 4.1 Add `tests/live_update_diff_test.gd` covering baseline, add, remove, modify, no-change, and failure-keeps-snapshot
- [x] 4.2 Manually verify with two emulator clients: invite from player 2 appears on player 1's lobby within ~5 s
- [x] 4.3 Note the service in `docs/firebase_emulators.md` (no architecture doc lists the autoloads)
