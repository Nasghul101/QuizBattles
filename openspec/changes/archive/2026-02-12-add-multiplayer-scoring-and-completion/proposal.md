# add-multiplayer-scoring-and-completion

## Why
Multiplayer matches have no scoring system to track player performance across rounds, no clear winner determination logic, and no completion flow that prevents matches from disappearing immediately after the final round. Players cannot see cumulative scores, don't know who won, and matches vanish without closure.

## What Changes
- **Display cumulative scores** - Show running totals of correct answers for both players in ScoreP1/ScoreP2 labels
- **Winner determination** - Compare final scores when all rounds complete and identify the winner or draw
- **Completion flow** - Show FinishGamePopup with winner announcement when match ends
- **Finished match status** - Keep completed matches visible on friendly_battles_page as "Game Finished" until player dismisses them
- **Player orientation** - Ensure logged-in player always appears on left side with their score in ScoreP1
- **Modal blocking** - Prevent interaction with background elements when FinishGamePopup is shown

## Impact
- **Affected specs**: gameplay-screen-initialization, friendly-battle-page, multiplayer-match-system
- **Affected code**:
  - `scenes/ui/gameplay_screen.gd` (score tracking, popup management, winner logic)
  - `scenes/ui/lobby_pages/friendly_battle_page.gd` (finished match display)
  - `autoload/user_database.gd` (get_all_matches_for_player method, status handling)

## Detailed Description

### Approach
- Track cumulative correct answer counts in gameplay_screen by monitoring result_components
- Add score label update logic that recalculates totals after each round completes
- Modify match completion handler to set status="finished" instead of deleting
- Show FinishGamePopup with winner name or "Draw" when both players complete the final round
- Add FinishGameButton handler to delete match and return to lobby
- Update friendly_battles_page to display "Game Finished" label for finished matches
- Use modal overlay to block interaction with background elements when popup is visible

### Goals
- Enable cumulative score tracking across all rounds in multiplayer matches
- Provide clear winner determination based on total correct answers
- Implement proper match completion flow with explicit dismissal
- Maintain finished match visibility until player chooses to clear it
- Ensure consistent player orientation (logged-in player always on left)

### Non-Goals
- Single-player mode scoring (no changes to single-player)
- Speed-based scoring or time bonuses
- Statistics tracking beyond the current match
- Tie-breaking logic (draws are acceptable)
- Animations or visual effects for score updates
- Leaderboards or persistent win/loss records

## Dependencies
- Existing result_component tracking (already stores was_correct for each question)
- Match status field in multiplayer_matches data structure
- FinishGamePopup UI elements (already added to gameplay_screen.tscn)

## Risks
- **Risk:** Counting logic errors if result_components aren't fully loaded
  **Mitigation:** Only calculate scores from confirmed result_component children

- **Risk:** Both players see different winners due to race conditions
  **Mitigation:** Winner is determined client-side from final match state; both players calculate the same result

- **Risk:** Finished matches accumulate if players don't dismiss them
  **Mitigation:** This is intentional - players control when to clear finished matches

## Open Questions
None - all clarifications confirmed with user.
