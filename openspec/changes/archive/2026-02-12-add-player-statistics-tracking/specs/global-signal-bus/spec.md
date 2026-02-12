# global-signal-bus Spec Delta

## ADDED Requirements

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

## Design Notes
**Signal Definition:**
```gdscript
## Emitted when a player's statistics are updated (wins, losses, current_streak, friend_wins)
## @param username: Username of the player whose statistics changed
signal player_stats_updated(username: String)
```

**Usage Example:**
```gdscript
func _ready() -> void:
    GlobalSignalBus.player_stats_updated.connect(_on_player_stats_updated)

func _on_player_stats_updated(username: String) -> void:
    if username == UserDatabase.current_user.username:
        _refresh_statistics_display()
```
