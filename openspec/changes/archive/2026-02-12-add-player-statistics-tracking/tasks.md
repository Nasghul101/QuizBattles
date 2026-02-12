# Implementation Tasks

## Phase 1: Database Schema Extension
- [x] Add `friend_wins: Dictionary` field to user schema in UserDatabase
- [x] Extend `_migrate_user_data()` to add `friend_wins: {}` for existing users
- [x] Add `stats_processed: bool` field to match creation in `create_match()`
- [x] Update `get_user_data_for_display()` to return `friend_wins` field
- [x] Test: Verify new users have `friend_wins: {}`
- [x] Test: Verify existing users auto-migrate with empty `friend_wins`

## Phase 2: Statistics Update Logic
- [x] Implement `update_player_statistics(match_data: Dictionary) -> void` in UserDatabase
  - Calculate winner/loser from match results
  - Check `stats_processed` flag to prevent duplicates
  - Update `wins`, `losses`, `current_streak` for both players
  - Update `friend_wins` if players are friends at game end
  - Set `stats_processed = true`
  - Emit `player_stats_updated` for both players
- [x] Add helper method `_calculate_match_winner(match_data: Dictionary) -> Dictionary` returning `{winner: String, loser: String, is_draw: bool}`
- [x] Test: Verify winner stats increment correctly
- [x] Test: Verify loser stats increment and streak resets
- [x] Test: Verify draw leaves stats unchanged
- [x] Test: Verify friend wins tracked only when friendship exists
- [x] Test: Verify stats_processed prevents duplicate updates

## Phase 3: Signal Integration
- [x] Add `signal player_stats_updated(username: String)` to GlobalSignalBus
- [x] Document signal purpose and usage in GlobalSignalBus comments
- [x] Test: Verify signal emits for both players after stat update

## Phase 4: Gameplay Integration
- [x] Identify match completion trigger point in gameplay_screen.gd
- [x] Call `UserDatabase.update_player_statistics(match_data)` when both players finish final round
- [x] Ensure stat update happens before match status changes to "finished"
- [x] Test: Complete full multiplayer match and verify stats update
- [x] Test: Verify stats update only once when both players view results

## Phase 5: Validation & Documentation
- [x] Run `openspec validate add-player-statistics-tracking --strict` and fix all issues
- [x] Add GDScript documentation comments to new methods
- [x] Update user_database.gd class documentation to mention statistics tracking
- [x] Verify all scenarios in spec deltas are testable and complete

## Testing Checklist
- [x] Create two test users who are friends
- [x] Complete multiplayer match where User A wins
- [x] Verify User A: `wins += 1`, `current_streak += 1`, `friend_wins[userB] += 1`
- [x] Verify User B: `losses += 1`, `current_streak = 0`
- [x] Complete another match where User B wins
- [x] Verify User B: `wins += 1`, `current_streak = 1`, `friend_wins[userA] += 1`
- [x] Verify User A: `losses += 1`, `current_streak = 0`
- [x] Complete match ending in draw
- [x] Verify both players: all stats unchanged
- [x] Unfriend users and complete match
- [x] Verify `friend_wins` does NOT increment
- [x] Reload database and verify stats persist correctly

