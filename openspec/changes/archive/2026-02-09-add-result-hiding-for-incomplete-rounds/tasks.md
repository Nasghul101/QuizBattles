# Implementation Tasks

## Preparation
- [x] Review multiplayer-match-system spec requirement for result hiding (line 210)
- [x] Review current gameplay_screen multiplayer flow
- [x] Verify icon_hidden.png asset exists and is properly imported
- [x] Verify icon_hidden is exported in result_button_component.tscn

## ResultButtonComponent Updates
- [x] Add `set_hidden_state()` method to result_button_component.gd
- [x] Set icon to icon_hidden in hidden state
- [x] Set disabled = true in hidden state
- [x] Set modulation to Color(1.0, 1.0, 1.0) (full color, not greyed)
- [x] Add `##` doc comment for `set_hidden_state()` method
- [x] Test that hidden button displays icon_hidden and is non-clickable

## result_component Updates
- [x] Add `hide_results()` method to result_component.gd
- [x] Iterate through all answer_buttons and call `set_hidden_state()`
- [x] Ensure method works regardless of current button state
- [x] Add `##` doc comment for `hide_results()` method
- [x] Test that `hide_results()` successfully hides all buttons

## gameplay_screen Logic Updates
- [x] Update `_load_existing_match_state()` method
- [x] Check `opponent_answered` status for each round before displaying opponent results
- [x] If opponent hasn't answered: call `result_component.hide_results()` instead of displaying
- [x] Update `_handle_round_completion()` for round-complete flow
- [x] When only current player answered: display opponent result_component but call `hide_results()`
- [x] Only display actual opponent results when both have answered
- [x] Add inline comments explaining the hiding logic

## Validation
- [ ] Test single-player mode: results display normally (no hiding)
- [ ] Test multiplayer - Player A answers first:
  - [ ] Player A sees their own results normally
  - [ ] Player A sees opponent's column with empty/grey placeholders (no change from before)
- [ ] Test multiplayer - Player B views after Player A answered:
  - [ ] Player B sees hidden icons (icon_hidden) for Player A's results
  - [ ] Hidden buttons are non-clickable
  - [ ] Player B cannot review Player A's questions
- [ ] Test multiplayer - Both players answered:
  - [ ] Player A sees Player B's actual results (green/red icons)
  - [ ] Player B sees Player A's actual results (green/red icons)
  - [ ] Both players can click to review questions
- [ ] Test round progression: hidden → revealed transition works
- [ ] Verify no console errors or warnings
- [ ] Check all doc comments are present

## Spec Updates
- [x] Review result-button-component spec delta for accuracy
- [x] Review result-component spec delta for accuracy
- [x] Ensure all new requirements have scenarios
- [x] Verify no conflicts with existing specs
