## ADDED Requirements

### Requirement: Live Refresh of Lobby Data
The main lobby screen and its pages (duel, friendly battle, socials) SHALL subscribe to `GlobalSignalBus` change signals while in the scene tree and SHALL update their displayed notifications, friends and matches in place without a screen switch, disconnecting on exit.

#### Scenario: Game invite arrives while in lobby
- **GIVEN** player 1 is on the main lobby screen
- **WHEN** player 2 sends a game invite and the next poll detects it
- **THEN** the lobby shows the notification and updates the notification indicator on the next frame

#### Scenario: Screen leaves the tree
- **WHEN** the lobby is freed
- **THEN** it is no longer connected to the change signals
