# Local User Database - Spec Delta

## MODIFIED Requirements

### Requirement: Track Total Games Played
The system SHALL store a `total_games` integer field in each user record that tracks the total number of multiplayer matches the user has completed, incremented after each match regardless of outcome (win, loss, or draw).

**Rationale:** Enable calculation of draws (`total_games - wins - losses`) and provide users with a complete count of their match history for display on the account management screen.

**Cross-reference:** Used by `account-management-screen` for statistics display.

#### Scenario: New user receives total_games field
**Given** no user exists with username "NewPlayer"  
**When** `create_user("NewPlayer", "password", "player@example.com")` is called  
**Then** the user record SHALL be created with `total_games: 0`  
**And** `wins: 0` and `losses: 0` (existing fields)

#### Scenario: Total games incremented after match completion
**Given** user "Player1" has `total_games: 10`  
**And** user "Player2" has `total_games: 15`  
**When** `update_player_statistics(match_data)` is called for a completed match between them  
**Then** Player1's `total_games` SHALL be incremented to 11  
**And** Player2's `total_games` SHALL be incremented to 16  
**And** this SHALL occur before determining winner/loser

#### Scenario: Total games incremented even in draw
**Given** user "Player1" has `total_games: 5`  
**And** user "Player2" has `total_games: 8`  
**When** `update_player_statistics(match_data)` is called for a match that ended in a draw  
**Then** Player1's `total_games` SHALL be incremented to 6  
**And** Player2's `total_games` SHALL be incremented to 9  
**And** wins and losses SHALL remain unchanged (draw handling)

#### Scenario: Total games included in display data
**Given** user "Player123" has `total_games: 42`  
**When** `get_user_data_for_display("Player123")` is called  
**Then** the returned dictionary SHALL include `"total_games": 42`  
**And** all other fields (username, avatar_path, wins, losses, current_streak, friend_wins, category_stats) are still included

#### Scenario: Migrate existing users with total_games field
**Given** user database contains user "OldUser" without `total_games` field  
**When** the database is loaded via `_load_database()`  
**Then** `_migrate_user_data()` SHALL add `total_games: 0` to "OldUser"  
**And** the database SHALL be saved with the updated schema

---

### Requirement: Restructure Category Stats to Track Wins and Played
The system SHALL change the `category_stats` dictionary structure from storing simple play counts (`{category: int}`) to storing nested dictionaries with both played counts and win counts (`{category: {"played": int, "wins": int}}`).

**Rationale:** Enable display of category-specific win rates and performance metrics on the account management screen without requiring separate tracking dictionaries.

**Cross-reference:** Used by `account-management-screen` for category statistics display.

**Migration:** Existing `category_stats` entries SHALL be converted to new format with `wins: 0` during database load.

#### Scenario: New user receives empty category stats with new structure
**Given** no user exists with username "NewPlayer"  
**When** `create_user("NewPlayer", "password", "player@example.com")` is called  
**Then** the user record SHALL be created with `category_stats: {}`  
**And** the dictionary SHALL be empty (no default categories)

#### Scenario: Category stats stored in new nested format
**Given** user "Player123" plays a match with categories "History" and "Science"  
**When** category statistics are updated  
**Then** the structure SHALL be `{"History": {"played": X, "wins": Y}, "Science": {"played": Z, "wins": W}}`  
**And** NOT the old format `{"History": X, "Science": Z}`

#### Scenario: Category stats included in display data with new structure
**Given** user "Player123" has `category_stats: {"History": {"played": 20, "wins": 12}}`  
**When** `get_user_data_for_display("Player123")` is called  
**Then** the returned dictionary SHALL include `"category_stats": {"History": {"played": 20, "wins": 12}}`  
**And** the nested structure SHALL be preserved

#### Scenario: Migrate existing category stats to new format
**Given** user "OldUser" has old format `category_stats: {"History": 15, "Science": 8}`  
**When** the database is loaded via `_load_database()`  
**Then** `_migrate_user_data()` SHALL convert to `{"History": {"played": 15, "wins": 0}, "Science": {"played": 8, "wins": 0}}`  
**And** the played count SHALL be preserved from the old single integer  
**And** wins SHALL be initialized to 0 (historical data not available)  
**And** the database SHALL be saved with the updated schema

#### Scenario: Empty category stats remain empty after migration
**Given** user "NewUser" has `category_stats: {}`  
**When** `_migrate_user_data()` runs  
**Then** category_stats SHALL remain `{}`  
**And** no placeholder categories SHALL be added

---

### Requirement: Update Category Statistics After Match Completion
The system SHALL update category statistics (played count and win count) for both players when a match completes, tracking each category that appeared in the match rounds.

**Rationale:** Provide category-level performance tracking to show users their strengths and weaknesses across different quiz categories.

**Implementation:** Category updates occur in `update_player_statistics()` function after winner determination.

#### Scenario: Increment category played count for both players
**Given** user "Player1" has `category_stats: {"History": {"played": 10, "wins": 6}}`  
**And** user "Player2" has `category_stats: {"History": {"played": 8, "wins": 3}}`  
**When** `update_player_statistics(match_data)` is called for a match with one History round  
**Then** Player1's History SHALL be updated to `{"played": 11, "wins": 6}` (or 7 if winner)  
**And** Player2's History SHALL be updated to `{"played": 9, "wins": 3}` (or 4 if winner)

#### Scenario: Increment category win count for winner only
**Given** match with categories ["History", "Science", "Geography"]  
**And** Player1 wins the match  
**When** `update_player_statistics(match_data)` is called  
**Then** Player1's History SHALL increment both `played` and `wins`  
**And** Player1's Science SHALL increment both `played` and `wins`  
**And** Player1's Geography SHALL increment both `played` and `wins`  
**And** Player2's categories SHALL increment only `played`, not `wins`

#### Scenario: Initialize new category with both played and wins
**Given** user "Player1" has `category_stats: {}` (empty)  
**When** `update_player_statistics(match_data)` is called for a match with "History" category  
**Then** Player1's `category_stats` SHALL be updated to `{"History": {"played": 1, "wins": 0 or 1}}`  
**And** the category SHALL be properly initialized with nested structure

#### Scenario: Track multiple categories in single match
**Given** match with 3 rounds using categories ["History", "Science", "History"]  
**When** category statistics are updated  
**Then** History SHALL increment `played` by 2 (appears twice)  
**And** Science SHALL increment `played` by 1  
**And** winner's categories SHALL also increment `wins` by the same amounts

#### Scenario: Handle draw with category updates
**Given** match ends in a draw with categories ["History", "Science"]  
**When** `update_player_statistics(match_data)` is called  
**Then** both players' History and Science SHALL increment `played` by 1  
**And** neither player's `wins` SHALL be incremented (draw means no winner)  
**And** `total_games` SHALL still be incremented for both players

#### Scenario: Extract categories from match rounds_data
**Given** `match_data.rounds_data` contains `[{"category": "History", ...}, {"category": "Science", ...}]`  
**When** categories are extracted for statistics update  
**Then** the system SHALL iterate through `rounds_data`  
**And** extract the `category` field from each round  
**And** build a list of categories to update statistics for

#### Scenario: Save database after category updates
**Given** category statistics have been updated for both players  
**When** `update_player_statistics()` completes  
**Then** `_save_database()` SHALL be called to persist changes  
**And** the match SHALL be updated with `stats_processed: true` flag

---

### Requirement: Category Stats Data Type and Constraints
The `category_stats` field SHALL be a Dictionary where keys are category name Strings and values are nested Dictionaries with integer fields `"played"` and `"wins"`.

**Rationale:** Provide clear data structure for tracking both participation and success in each category.

**Constraints:**
- Keys: String type (category names from game's category list)
- Values: Dictionary type with exactly two keys: `"played"` (int >= 0) and `"wins"` (int >= 0)
- Invariant: `wins` SHALL always be less than or equal to `played` for any category
- Empty dictionary allowed (new users, no games played)

#### Scenario: Valid category stats format
**Given** a user record is being created or updated  
**When** category_stats is set to `{"History": {"played": 10, "wins": 6}}`  
**Then** it SHALL be a Dictionary type  
**And** the key "History" SHALL be a String  
**And** the value SHALL be a Dictionary with "played": 10 and "wins": 6  
**And** both "played" and "wins" SHALL be integers >= 0

#### Scenario: Enforce wins <= played invariant
**Given** category "Science" has `{"played": 20, "wins": 12}`  
**When** wins are incremented  
**Then** wins SHALL never exceed played  
**And** the system SHALL ensure wins <= played at all times

#### Scenario: Reject invalid nested structure
**Given** attempt to set `category_stats: {"History": 15}` (old format)  
**When** validation occurs during migration  
**Then** the system SHALL convert to `{"History": {"played": 15, "wins": 0}}`  
**And** OR reject and require proper nested structure
