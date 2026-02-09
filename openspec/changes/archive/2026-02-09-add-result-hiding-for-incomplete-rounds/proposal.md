# Add Result Hiding for Incomplete Rounds

**Change ID:** `add-result-hiding-for-incomplete-rounds`  
**Status:** Proposed  
**Created:** 2026-02-09  

## Problem Statement

In multiplayer matches, when Player A completes a round but Player B has not yet answered their questions, Player B can currently see Player A's actual correct/incorrect results displayed in the result_component. This violates the multiplayer-match-system requirement (line 210) that states opponent answers should be hidden until both players complete the round.

Current behavior:
- Player A finishes round 1, their results are stored
- Player B loads gameplay_screen and sees Player A's actual results (green checkmarks/red X's)
- Player B can review Player A's questions and identify patterns before answering
- This creates an unfair advantage for the second player to answer

Expected behavior per spec:
- Player B should see placeholder icons instead of actual results
- Results should only be revealed after both players complete the round
- Clicking hidden result buttons should not trigger the review flow

## Proposed Solution

Implement result hiding functionality by:

1. **Add hidden state to ResultButtonComponent**:
   - Add `set_hidden_state()` method that displays `icon_hidden.png`
   - Make hidden buttons non-clickable (disabled)
   - Use existing `icon_hidden` exported texture already added to the component

2. **Add hide utility to result_component**:
   - Add `hide_results()` method to set all buttons to hidden state
   - This method can be called by gameplay_screen when opponent hasn't finished
   - Keeps result_component unaware of player/opponent concepts (maintains separation of concerns)

3. **Update gameplay_screen logic**:
   - In `_load_existing_match_state()`: Check if opponent has answered before displaying their results
   - In `_handle_round_completion()`: When only current player answered, display opponent's result_component with hidden state
   - Only reveal actual results when both players have answered the round

## Impact

### Changed Components
- **result-button-component** (MODIFIED): Add `set_hidden_state()` method
- **result-component** (MODIFIED): Add `hide_results()` utility method
- **multiplayer-match-system** (VALIDATED): Implements existing requirement at line 210

### Benefits
- Fair competitive gameplay - no information leakage
- Maintains component separation (result_component doesn't know about players)
- Reuses existing `icon_hidden.png` asset
- Simple, focused implementation

### Breaking Changes
None - adds new functionality without changing existing behavior:
- All existing result_component methods remain unchanged
- New methods are optional utility functions
- Single-player mode unaffected

## Acceptance Criteria

- [x] ResultButtonComponent has `set_hidden_state()` method
- [x] Hidden buttons display `icon_hidden.png` and are disabled
- [x] result_component has `hide_results()` method
- [x] gameplay_screen checks opponent's answered status before displaying results
- [x] When Player A finishes but Player B hasn't: Player B sees hidden icons for Player A
- [x] When both players finish: both see actual results
- [x] Clicking hidden buttons does not trigger question review
- [x] Single-player mode continues to work normally

## Dependencies

- Requires `icon_hidden.png` asset (already exists per user)
- Requires `icon_hidden` exported in result_button_component.tscn (already exists per user)
- Depends on multiplayer-match-system's `player_answers[username].answered` tracking

## Rollout Plan

1. Add `set_hidden_state()` to ResultButtonComponent
2. Add `hide_results()` to result_component
3. Update gameplay_screen multiplayer logic to check answered status
4. Test multiplayer scenarios:
   - One player answered, other hasn't: hidden icons shown
   - Both answered: actual results shown
   - Review clicks work on revealed results, blocked on hidden ones
5. Validate single-player mode unaffected
6. Archive change after validation
