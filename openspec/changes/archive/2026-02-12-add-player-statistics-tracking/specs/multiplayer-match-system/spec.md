# multiplayer-match-system Spec Delta

## ADDED Requirements

### Requirement: Track Statistics Processing Status
The system SHALL include a `stats_processed` boolean field in each match record to prevent duplicate statistics updates.

**Rationale:** Ensure player statistics (wins/losses/streaks) are updated exactly once per match, even if multiple systems query match completion status.

**Constraints:**
- `stats_processed` SHALL be a boolean type
- Default value SHALL be `false` when match is created
- SHALL be set to `true` after statistics are updated
- SHALL persist across database saves/loads

#### Scenario: Initialize stats_processed to false
**Given** two players agree to play  
**When** `create_match(inviter, invitee, rounds, questions)` is called  
**Then** the match record includes `stats_processed: false`  
**And** the match is saved to the database

#### Scenario: Persist stats_processed flag
**Given** a match exists with `stats_processed: true`  
**When** the database is saved to disk  
**And** the game is restarted  
**And** the database is loaded  
**Then** the match retains `stats_processed: true`

#### Scenario: Mark statistics as processed after update
**Given** a match is complete with both players finishing all rounds  
**And** the match has `stats_processed: false`  
**When** statistics are updated via `UserDatabase.update_player_statistics(match_data)`  
**Then** the match `stats_processed` field is set to `true`  
**And** the updated match data is saved via `update_match(match_data)`

#### Scenario: Prevent duplicate statistics updates
**Given** a match has `stats_processed: true`  
**When** `UserDatabase.update_player_statistics(match_data)` is called  
**Then** the method detects the flag and returns early  
**And** no player statistics are modified  
**And** a warning is logged
