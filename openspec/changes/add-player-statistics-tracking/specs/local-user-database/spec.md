# local-user-database Spec Delta

## ADDED Requirements

### Requirement: Store Friend-Specific Win Counts
The system SHALL store a `friend_wins` Dictionary in each user record mapping friend usernames to win counts against that friend.

**Rationale:** Enable players to track competitive head-to-head records with specific friends, providing personalized rivalry metrics.

**Constraints:**
- `friend_wins` SHALL be a Dictionary type (compatible with Firebase object structure)
- Keys SHALL be friend usernames (String)
- Values SHALL be win counts (int)
- New users SHALL have `friend_wins` initialized as empty Dictionary `{}`

#### Scenario: New user has empty friend_wins
**Given** no user exists with username "NewPlayer"  
**When** `create_user("NewPlayer", "password", "player@example.com")` is called  
**Then** the user record is created with `friend_wins: {}`  
**And** the user data contains an empty friend_wins Dictionary

#### Scenario: Friend wins persist across sessions
**Given** user "PlayerA" has `friend_wins: {"PlayerB": 3, "PlayerC": 1}`  
**When** the database is saved to disk  
**And** the game is restarted  
**And** the database is loaded  
**Then** user "PlayerA" SHALL have exactly the same friend_wins Dictionary  
**And** `friend_wins["PlayerB"]` equals 3  
**And** `friend_wins["PlayerC"]` equals 1

---

### Requirement: Update Player Statistics on Match Completion
The system SHALL provide an `update_player_statistics(match_data)` method that processes match outcomes and updates winner/loser statistics.

**Rationale:** Centralize statistics update logic to ensure consistent, single-execution updates when multiplayer matches complete.

**Constraints:**
- SHALL only update statistics for multiplayer matches (not single-player)
- SHALL only execute once per match (check `stats_processed` flag)
- SHALL update both players' statistics atomically
- SHALL emit `GlobalSignalBus.player_stats_updated` for each affected player

#### Scenario: Update winner statistics after match completion
**Given** a multiplayer match is complete with PlayerA scoring 12 correct and PlayerB scoring 8 correct  
**And** PlayerA has `wins: 5`, `losses: 2`, `current_streak: 2`  
**And** the match has `stats_processed: false`  
**When** `update_player_statistics(match_data)` is called  
**Then** PlayerA's `wins` is incremented to 6  
**And** PlayerA's `current_streak` is incremented to 3  
**And** PlayerA's `losses` remains unchanged at 2  
**And** the match `stats_processed` flag is set to `true`

#### Scenario: Update loser statistics after match completion
**Given** a multiplayer match is complete with PlayerA scoring 12 correct and PlayerB scoring 8 correct  
**And** PlayerB has `wins: 3`, `losses: 4`, `current_streak: 1`  
**And** the match has `stats_processed: false`  
**When** `update_player_statistics(match_data)` is called  
**Then** PlayerB's `losses` is incremented to 5  
**And** PlayerB's `current_streak` is reset to 0  
**And** PlayerB's `wins` remains unchanged at 3

#### Scenario: Draw leaves statistics unchanged
**Given** a multiplayer match is complete with both players scoring 10 correct  
**And** PlayerA has `wins: 5`, `losses: 2`, `current_streak: 2`  
**And** PlayerB has `wins: 3`, `losses: 4`, `current_streak: 1`  
**And** the match has `stats_processed: false`  
**When** `update_player_statistics(match_data)` is called  
**Then** PlayerA's statistics remain `wins: 5`, `losses: 2`, `current_streak: 2`  
**And** PlayerB's statistics remain `wins: 3`, `losses: 4`, `current_streak: 1`  
**And** the match `stats_processed` flag is set to `true`

#### Scenario: Prevent duplicate statistics updates
**Given** a multiplayer match has `stats_processed: true`  
**When** `update_player_statistics(match_data)` is called again  
**Then** no user statistics are modified  
**And** no signals are emitted  
**And** a warning is logged indicating stats already processed

#### Scenario: Update friend wins when players are friends
**Given** PlayerA and PlayerB are friends (mutual friendship exists)  
**And** a multiplayer match completes with PlayerA winning  
**And** PlayerA has `friend_wins: {"PlayerB": 2}`  
**And** the match has `stats_processed: false`  
**When** `update_player_statistics(match_data)` is called  
**Then** PlayerA's `friend_wins["PlayerB"]` is incremented to 3  
**And** PlayerB's `friend_wins` is not modified (only winner tracks friend wins)

#### Scenario: Skip friend wins when players are not friends
**Given** PlayerA and PlayerB are NOT friends  
**And** a multiplayer match completes with PlayerA winning  
**And** PlayerA has `friend_wins: {}`  
**And** the match has `stats_processed: false`  
**When** `update_player_statistics(match_data)` is called  
**Then** PlayerA's `friend_wins` remains empty `{}`  
**And** no friend-specific wins are recorded

#### Scenario: Initialize friend wins entry on first win against friend
**Given** PlayerA and PlayerB are friends  
**And** PlayerA has `friend_wins: {}` (no previous wins against PlayerB)  
**And** a multiplayer match completes with PlayerA winning  
**And** the match has `stats_processed: false`  
**When** `update_player_statistics(match_data)` is called  
**Then** PlayerA's `friend_wins["PlayerB"]` is created and set to 1

#### Scenario: Emit signals for both players
**Given** a multiplayer match completes with PlayerA winning against PlayerB  
**And** the match has `stats_processed: false`  
**When** `update_player_statistics(match_data)` is called  
**Then** `GlobalSignalBus.player_stats_updated.emit("PlayerA")` is called  
**And** `GlobalSignalBus.player_stats_updated.emit("PlayerB")` is called

---

### Requirement: Migrate Existing Users with Friend Wins
The system SHALL extend `_migrate_user_data()` to add `friend_wins` field for existing users.

**Rationale:** Ensure backward compatibility when adding friend wins tracking to existing databases.

#### Scenario: Add friend_wins to existing user
**Given** user "OldPlayer" exists without a `friend_wins` field  
**When** the database is loaded and migration runs  
**Then** user "OldPlayer" has `friend_wins: {}` added  
**And** the database is saved with the updated schema

#### Scenario: Preserve existing friend_wins data
**Given** user "ExistingPlayer" has `friend_wins: {"Friend1": 5}`  
**When** the database is loaded and migration runs  
**Then** user "ExistingPlayer" retains `friend_wins: {"Friend1": 5}`  
**And** no migration is applied to this field

---

### Requirement: Get User Data Safe for Display
The system SHALL provide a `get_user_data_for_display()` method that returns a sanitized Dictionary containing username, avatar_path, wins, losses, current_streak, and friend_wins for UI display purposes.

**Rationale:** Enable UI components to display user profile information and friend-specific win records while excluding sensitive data like passwords.

#### Scenario: Include friend_wins in display data
**Given** user "PlayerA" exists with `friend_wins: {"PlayerB": 3, "PlayerC": 1}`  
**When** `get_user_data_for_display("PlayerA")` is called  
**Then** the returned Dictionary includes `"friend_wins": {"PlayerB": 3, "PlayerC": 1}`  
**And** all other fields (username, avatar_path, wins, losses, current_streak) are still included
