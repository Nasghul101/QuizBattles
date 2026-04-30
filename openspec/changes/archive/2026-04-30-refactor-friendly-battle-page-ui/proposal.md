# Proposal: Refactor Friendly Battle Page UI

## Summary
Adapt the friendly_battle_page to use new dual-column friendly duel button components (left/right) instead of avatar_component, displaying cumulative match scores, current round, and turn status via highlight/unhighlight functionality.

## Motivation
The UI design for friendly_battle_page has evolved to use specialized button components that provide better visual feedback and game state information. The current implementation uses generic avatar_component instances, but the new design requires:

1. **Dual-column layout**: Separate lists for left and right button variants that alternate
2. **Richer game state display**: Show player points, opponent points, round number, and opponent name directly on the button
3. **Visual turn indicators**: Use highlight/unhighlight functions instead of text labels for turn status
4. **Improved user experience**: Clearer at-a-glance information about match progress

## Scope

### In Scope
- Replace `avatar_component` instantiation with `friendly_duel_button_l` and `friendly_duel_button_r`
- Implement alternating left/right button placement logic
- Calculate and display cumulative scores across all rounds for both players
- Display current round number
- Use `highlight()` when it's the player's turn, `un_highlight()` when it's opponent's turn
- Maintain existing navigation to gameplay_screen on button press
- Filter to show only active matches (exclude finished matches)
- Handle signed-out state and empty match lists

### Out of Scope
- Changes to the friendly_duel_button component API or visual design
- Modifications to gameplay_screen or match data structures
- Changes to how matches are created or stored
- Real-time score updates (scores update on page visibility change as before)

## Success Criteria
1. Friendly battle page displays matches in alternating left/right columns
2. Each button shows correct cumulative scores, round number, and opponent name
3. Turn status is indicated via button highlighting (not text)
4. Clicking any button navigates to the correct match in gameplay_screen
5. Page refreshes match list when becoming visible
6. All existing tests pass
7. `openspec validate refactor-friendly-battle-page-ui --strict` passes with no errors

## Dependencies
- Existing components: `friendly_duel_button_l.tscn`, `friendly_duel_button_r.tscn`, `friendly_duel_button.gd`
- Existing autoload: `UserDatabase` with match data access methods
- Existing spec: `friendly-battle-page` (will be modified)

## Risks
- **Score calculation complexity**: Need to iterate through all rounds to calculate cumulative scores - mitigated by reusing pattern from gameplay_screen._calculate_score_from_results()
- **Alternating logic edge cases**: Odd number of matches requires clear left/right distribution - mitigated by simple modulo logic (left gets extra)
- **Highlight state synchronization**: Must correctly determine whose turn it is from match data - mitigated by existing match.current_turn field
