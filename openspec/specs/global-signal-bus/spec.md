# global-signal-bus Specification

## Purpose
TBD - created by archiving change 2026-02-02-add-notification-system. Update Purpose after archive.
## Requirements
### Requirement: GlobalSignalBus Autoload Singleton
The system SHALL provide a GlobalSignalBus autoload singleton at `autoload/global_signal_bus.gd` that serves as a central hub for application-wide signals.

#### Scenario: GlobalSignalBus is registered in project settings
**Given** the project is configured  
**When** the game launches  
**Then** `GlobalSignalBus` is available as an autoload singleton  
**And** can be accessed from any scene via `GlobalSignalBus`

---

### Requirement: Notification Received Signal
GlobalSignalBus SHALL expose a `notification_received` signal that any scene can emit to send notifications.

#### Scenario: Scene emits notification_received signal
**Given** a scene needs to notify a user  
**When** the scene calls `GlobalSignalBus.notification_received.emit(notification_data)`  
**And** `notification_data` contains `{"recipient_username": "testuser", "message": "Test message", "sender": "sender_name", "has_actions": true, "action_data": {}}`  
**Then** the signal is broadcast to all connected listeners  
**And** the notification data is passed unchanged

---

### Requirement: Notification Action Taken Signal
GlobalSignalBus SHALL expose a `notification_action_taken` signal that is emitted when users interact with notifications.

#### Scenario: User accepts a notification
**Given** a notification is displayed to the user  
**When** the user clicks the accept button  
**Then** `GlobalSignalBus.notification_action_taken.emit(notification_id, "accept")` is called  
**And** all connected listeners receive the notification ID and action string

#### Scenario: User denies a notification
**Given** a notification is displayed to the user  
**When** the user clicks the deny button  
**Then** `GlobalSignalBus.notification_action_taken.emit(notification_id, "deny")` is called  
**And** all connected listeners receive the notification ID and action string

---

### Requirement: Extensible Signal Hub
GlobalSignalBus SHALL be designed to support additional global signals in the future without modifying existing functionality.

#### Scenario: New global signal is added
**Given** a developer needs a new application-wide signal  
**When** they add a new signal definition to `global_signal_bus.gd`  
**Then** existing signals continue to function  
**And** scenes can connect to the new signal without code changes elsewhere

---

### Requirement: Signal Documentation
GlobalSignalBus script SHALL include documentation comments describing each signal's purpose, parameters, and usage patterns.

#### Scenario: Developer reads GlobalSignalBus documentation
**Given** a developer opens `autoload/global_signal_bus.gd`  
**When** they read the file  
**Then** each signal has a documentation comment explaining its purpose  
**And** parameter types and expected data structures are documented  
**And** usage examples are provided

### Requirement: Game Invite Accepted Signal
GlobalSignalBus SHALL expose a `game_invite_accepted` signal that is emitted when a player accepts a game invitation.

#### Scenario: Player accepts game invite
**Given** Player A sends a game invite to Player B  
**And** Player B receives the invite notification  
**When** Player B clicks the Accept button on the invite notification  
**Then** `GlobalSignalBus.game_invite_accepted.emit(inviter_username, invitee_username)` is called  
**And** the signal includes Player A's username as inviter_username  
**And** the signal includes Player B's username as invitee_username  
**And** future multiplayer systems can connect to this signal to initiate game sessions

#### Scenario: Multiple systems can listen to game invite acceptances
**Given** a multiplayer matchmaking system exists in the future  
**When** the system connects to `GlobalSignalBus.game_invite_accepted`  
**Then** it receives all game invite acceptance events  
**And** can use the inviter and invitee usernames to start a game session  
**And** multiple listeners can connect without interfering with each other

---

### Requirement: Player Statistics Updated Signal
The system SHALL provide a `player_stats_updated` signal that emits when a player's statistics (wins, losses, current_streak, friend_wins) are modified.

**Rationale:** Enable UI components (profile screens, lobby displays, leaderboards) to refresh player statistics in real-time when matches complete.

**Constraints:**
- Signal SHALL be named `player_stats_updated`
- Signal SHALL include one parameter: `username: String`
- Signal SHALL emit separately for each affected player
- Signal SHALL emit after statistics are persisted to database

#### Scenario: Emit signal after winner statistics update
**Given** a multiplayer match completes with PlayerA winning  
**When** PlayerA's statistics are updated in the database  
**Then** `GlobalSignalBus.player_stats_updated.emit("PlayerA")` is called  
**And** the signal emits after database save completes

#### Scenario: Emit signal after loser statistics update
**Given** a multiplayer match completes with PlayerB losing  
**When** PlayerB's statistics are updated in the database  
**Then** `GlobalSignalBus.player_stats_updated.emit("PlayerB")` is called  
**And** the signal emits after database save completes

#### Scenario: Emit signal for both players in single update
**Given** a multiplayer match completes  
**When** both players' statistics are updated via `update_player_statistics(match_data)`  
**Then** `player_stats_updated` emits once for PlayerA  
**And** `player_stats_updated` emits once for PlayerB  
**And** both signals emit before the method returns

#### Scenario: No signal emission for draw
**Given** a multiplayer match ends in a draw (equal scores)  
**When** `update_player_statistics(match_data)` processes the match  
**Then** no player statistics are modified  
**And** no `player_stats_updated` signals are emitted

#### Scenario: UI component listens to signal
**Given** a profile screen is displayed showing PlayerA's statistics  
**And** the screen is connected to `GlobalSignalBus.player_stats_updated`  
**When** the signal emits with username "PlayerA"  
**Then** the profile screen refreshes and displays updated statistics

---

