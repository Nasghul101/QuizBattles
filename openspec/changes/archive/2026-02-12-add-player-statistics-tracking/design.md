# Design Document: Player Statistics Tracking

## Overview
This document outlines the architectural decisions and implementation approach for tracking player wins, losses, win streaks, and friend-specific win records in multiplayer quiz duels.

## Architecture

### Data Flow
```
Match Completes (both players finish all rounds)
    ↓
gameplay_screen.gd detects completion
    ↓
Calls UserDatabase.update_player_statistics(match_data)
    ↓
UserDatabase checks stats_processed flag
    ↓
Calculates winner/loser from match results
    ↓
Updates winner stats (wins++, streak++, friend_wins if applicable)
    ↓
Updates loser stats (losses++, streak=0)
    ↓
Sets match.stats_processed = true
    ↓
Saves match via update_match()
    ↓
Emits GlobalSignalBus.player_stats_updated for each player
    ↓
UI components refresh (if connected to signal)
```

### Key Design Decisions

#### 1. Firebase-Compatible Schema
**Decision:** Use Dictionary for `friend_wins` instead of Array of objects

**Rationale:**
- Firebase/Firestore stores objects as key-value maps
- Dictionary access is O(1) vs O(n) array search
- Direct access pattern: `user.friend_wins["opponent_username"]`
- Easier to increment: `friend_wins[opponent] = friend_wins.get(opponent, 0) + 1`

**Schema:**
```gdscript
{
    "username": "PlayerA",
    "wins": 15,
    "losses": 8,
    "current_streak": 3,
    "friend_wins": {
        "PlayerB": 5,
        "PlayerC": 3,
        "PlayerD": 1
    }
}
```

#### 2. Single-Update Guarantee with stats_processed Flag
**Decision:** Add `stats_processed: bool` to match data, check before updating

**Alternatives Considered:**
- Store winner in match_data when last player finishes → Requires complex round completion detection
- Track processed matches in separate collection → Adds storage complexity
- Use match status ("finished" vs "active") → Not granular enough, status might change before stats update

**Chosen Approach:**
- Simple boolean flag in match record
- Check at top of `update_player_statistics()`
- Set to `true` after successful update
- Logged warning if attempting duplicate update

**Benefits:**
- Explicit and self-documenting
- Persists across sessions
- Prevents race conditions if both players trigger update
- Easy to debug (flag visible in database)

#### 3. Winner Calculation Logic
**Decision:** Compare total correct answers across all rounds

**Implementation:**
```gdscript
func _calculate_match_winner(match_data: Dictionary) -> Dictionary:
    var player1 = match_data.players[0]
    var player2 = match_data.players[1]
    var score1 = 0
    var score2 = 0
    
    for round_data in match_data.rounds_data:
        for result in round_data.player_answers[player1].results:
            if result.was_correct:
                score1 += 1
        for result in round_data.player_answers[player2].results:
            if result.was_correct:
                score2 += 1
    
    if score1 > score2:
        return {"winner": player1, "loser": player2, "is_draw": false}
    elif score2 > score1:
        return {"winner": player2, "loser": player1, "is_draw": false}
    else:
        return {"winner": "", "loser": "", "is_draw": true}
```

#### 4. Friend Status at Game End
**Decision:** Check friendship status when stats update (not when match starts)

**Rationale:**
- More accurate reflection of current relationship
- If players unfriend mid-game, they likely don't want rivalry tracking
- Simple to implement: call `are_friends()` during stat update
- Firebase migration will use similar real-time lookup

**Trade-off:** If players re-friend later, past wins aren't backfilled (acceptable)

#### 5. Draw Handling
**Decision:** Draws leave all statistics unchanged (no wins, no losses, no streak change)

**Rationale:**
- Draw is neither win nor loss, so incrementing either would be misleading
- Streak preservation acknowledges player didn't "lose" their streak
- Consistent with most competitive games (draws don't break streaks)

#### 6. Friend Wins as Subset of Overall Wins
**Decision:** `friend_wins` counts toward overall `wins` statistic

**Rationale:**
- Friend wins are a subset, not a separate category
- Overall wins = total competitive victories
- Friend wins = detailed breakdown of wins against specific friends
- Firebase best practice for aggregate vs detailed statistics

**Example:**
- PlayerA total wins: 20
- PlayerA friend_wins: {"PlayerB": 5, "PlayerC": 3} (8 total)
- PlayerA wins vs non-friends: 12

#### 7. Signal Emission for UI Updates
**Decision:** Emit `player_stats_updated` signal for both players after update

**Rationale:**
- Decouples statistics logic from UI logic
- Allows multiple UI components to react (lobby, profile, leaderboards)
- Firebase will use similar listener pattern with Firestore snapshots
- Emit after database save to ensure consistency

**Signal Design:**
```gdscript
signal player_stats_updated(username: String)
```

Separate emission per player allows targeted UI updates.

## Integration Points

### 1. gameplay_screen.gd
**Trigger Point:** After both players complete final round

**Detection Logic:**
```gdscript
# In _handle_round_completion() or similar
if current_round == num_rounds:
    # Final round - check if both players answered
    if _both_players_completed_match():
        UserDatabase.update_player_statistics(match_data)
```

### 2. user_database.gd
**New Methods:**
- `update_player_statistics(match_data: Dictionary) -> void` - Main entry point
- `_calculate_match_winner(match_data: Dictionary) -> Dictionary` - Helper for winner logic

**Modified Methods:**
- `_migrate_user_data()` - Add `friend_wins` migration
- `get_user_data_for_display()` - Include `friend_wins` in return

### 3. global_signal_bus.gd
**New Signal:**
```gdscript
## Emitted when a player's statistics are updated after match completion
## @param username: Username of the player whose statistics changed
signal player_stats_updated(username: String)
```

## Edge Cases & Error Handling

### 1. Match Data Validation
- Verify `players` array has exactly 2 entries
- Verify `rounds_data` exists and is populated
- Log error and return early if validation fails

### 2. User Existence Check
- Before updating stats, verify both users exist in database
- Handle edge case where user was deleted mid-match
- Log error if user not found, skip their stat update

### 3. Friendship Lookup Timing
- Check friendship AFTER calculating winner (at update time)
- Handle edge case where one user was deleted (no friendship → no friend_wins)

### 4. Database Save Failures
- If stat update succeeds but match save fails, log critical error
- Consider adding transaction-like rollback in future Firebase version

### 5. Signal Emission Failures
- Wrap signal emissions in try/except equivalent (Godot error handling)
- Log warning if signal emit fails but continue execution

## Testing Strategy

### Unit Tests (Manual/GUT Framework)
1. Test `_calculate_match_winner()` with various score combinations
2. Test stat updates with winning, losing, and draw scenarios
3. Test friendship detection at update time
4. Test `stats_processed` flag prevents duplicates
5. Test migration adds `friend_wins` to existing users

### Integration Tests
1. Complete full multiplayer match between friends → verify all stats update
2. Complete match between non-friends → verify no friend_wins update
3. Complete match ending in draw → verify no stats change
4. Trigger duplicate update → verify no double-counting

### Database Tests
1. Save and reload database → verify stats persistence
2. Verify friend_wins Dictionary structure matches Firebase format

## Future Considerations

### Firebase Migration Path
Current local implementation maps directly to Firebase:
```
Local: user.friend_wins = {"opponent1": 5}
Firebase: users/{userId}/friend_wins/{opponent1} = 5
```

Stats update will use Firebase Cloud Function:
```javascript
exports.updateMatchStatistics = functions.firestore
    .document('matches/{matchId}')
    .onUpdate(async (change, context) => {
        // Check stats_processed flag
        // Calculate winner
        // Update user documents atomically
    });
```

### Performance Optimization
- Current implementation updates database twice (users, then match)
- Firebase will use transaction for atomic updates
- Consider batching signal emissions if multiple matches complete simultaneously

### Analytics Integration
When adding Firebase Analytics:
- Log "match_completed" event with winner/loser
- Track "win_streak_milestone" events (5, 10, 25 streak)
- Track "first_win_vs_friend" events for engagement metrics

## Migration Checklist
- [x] Schema compatible with Firebase object structure
- [x] Single-update guarantee mechanism (stats_processed flag)
- [x] Signal-based UI updates (mimics Firestore listeners)
- [x] Friendship lookup at update time (matches real-time Firebase query)
- [x] Friend wins as Dictionary (direct Firebase mapping)
