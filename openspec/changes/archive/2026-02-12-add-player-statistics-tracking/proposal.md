# Change: Add Player Statistics Tracking

## Why
Players cannot track their performance or view competitive records against friends. Without win/loss statistics and streak tracking, the game lacks progression feedback and competitive motivation that are core to quiz duel engagement.

## What Changes
- Extend user schema with `friend_wins: Dictionary` field mapping friend usernames to win counts
- Add `stats_processed: bool` flag to match records to prevent duplicate updates
- Implement `update_player_statistics(match_data)` method in UserDatabase to calculate winners and update stats
- Update winner's `wins`, `current_streak`, and `friend_wins` (if applicable)
- Update loser's `losses` and reset `current_streak`
- Add `player_stats_updated` signal to GlobalSignalBus for UI refresh notifications
- Integrate stat updates into gameplay_screen when multiplayer matches complete
- Extend `get_user_data_for_display()` to include `friend_wins` data

## Impact
**Affected Specs:**
- local-user-database (ADDED friend_wins, update_player_statistics; MODIFIED get_user_data_for_display)
- multiplayer-match-system (ADDED stats_processed flag)
- global-signal-bus (ADDED player_stats_updated signal)

**Affected Code:**
- `autoload/user_database.gd` - Schema, migration, stat update logic
- `autoload/global_signal_bus.gd` - New signal definition
- `scenes/ui/gameplay_screen.gd` - Trigger stat updates on match completion

**Database Schema Changes:**
- User records: Add `friend_wins: {}` (Dictionary)
- Match records: Add `stats_processed: false` (bool)
- Existing `wins`, `losses`, `current_streak` become active (currently unused)

**Migration:**
- Auto-migration adds `friend_wins: {}` for existing users
- No breaking changes to existing functionality

## Scope
**In Scope:**
- Track overall wins, losses, and win streaks for multiplayer matches
- Track per-friend win counts for competitive rivalry metrics
- Ensure single-execution statistics updates (idempotent)
- Firebase-compatible data structures (Dictionary, boolean flags)
- Signal-based UI update notifications

**Out of Scope:**
- UI components to display statistics (profile screens, leaderboards)
- Statistics for single-player mode
- Historical match records or detailed analytics
- Time-based statistics (wins per day, etc.)

## Design Highlights
- **Firebase-compatible schema**: Dictionary for `friend_wins` maps directly to Firestore subcollections
- **Single-update guarantee**: `stats_processed` flag prevents duplicate processing
- **Friendship timing**: Check friendship status at game end (not game start)
- **Draw handling**: Draws leave all statistics unchanged (no win, no loss, streak preserved)
- **Friend wins as subset**: Friend wins count toward overall wins (not separate)
- **Signal-based updates**: UI components can react to stat changes via GlobalSignalBus

See [design.md](design.md) for detailed architectural decisions and Firebase migration path.

## Success Criteria
- [ ] Users have `friend_wins: {}` in database records
- [ ] Matches have `stats_processed: false` on creation
- [ ] Winner stats update correctly after multiplayer match (wins++, streak++, friend_wins)
- [ ] Loser stats update correctly (losses++, streak=0)
- [ ] Draws leave all statistics unchanged
- [ ] Friend wins tracked only when players are friends at game end
- [ ] `player_stats_updated` signal emits for both players
- [ ] Stats update exactly once per match (no duplicates)
- [ ] Validation passes: `openspec validate add-player-statistics-tracking --strict`

## Timeline Estimate
- Spec review: 30 minutes
- Implementation: 2-3 hours
- Testing: 1 hour
- Total: 3.5-4.5 hours
