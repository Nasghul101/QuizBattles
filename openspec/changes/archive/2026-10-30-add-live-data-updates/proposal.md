## Why

Screens only load Firestore data once when they are built (e.g. `main_lobby_screen.gd` calls `get_notifications` in `_load_existing_notifications`). When another player changes data that affects you (game invite, friend added, match turn played), you only see it after switching screens and returning. Players must see changes without navigating.

## What Changes

- Add a `LiveUpdateService` autoload (separate from `UserDatabase`, which stays a pure data-access layer) that polls the signed-in user's notifications, friends and matches every 5 seconds while signed in and the app is in the foreground.
- The service diffs each result against its last snapshot and emits `GlobalSignalBus` signals only when something actually changed (added / removed / modified).
- Screens subscribe to those signals and refresh in place on the next frame after the signal. The main lobby shows new notifications immediately (replacing the "switch screens to see it" workaround); friends and matches views refresh the same way.
- Polling pauses when signed out or the app loses focus, and an immediate poll runs on sign-in and on app resume.
- Polling is skipped while a previous poll is still in flight and backs off on errors; failures never interrupt gameplay.

Assumptions: "next possible frame" is interpreted as "next frame after the change is detected", with detection latency bounded by the 5 s poll interval. Real push (RTDB stream / Cloud Function) was considered and rejected for now to avoid new backend infrastructure.

## Capabilities

### New Capabilities
- `live-data-updates`: Background polling service that detects remote changes to notifications, friends and matches and publishes change signals.

### Modified Capabilities
- `global-signal-bus`: Add signals for notifications, friends and matches changes.
- `main-lobby-screen`: Lobby reacts to live change signals by updating notifications (and match list) without a screen switch.

## Impact

- New: `autoload/live_update_service.gd` (registered in `project.godot`).
- Modified: `autoload/global_signal_bus.gd`, `scenes/ui/main_lobby_screen.gd`, and the friends/socials page scripts that load friends.
- No Firestore schema or rules changes. Extra read cost: three queries per 5 s per active client; a per-user "revision" marker document is a possible later optimization.
- Tests: add a GDScript test in `tests/` for snapshot diffing.
