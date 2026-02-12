# Implementation Tasks: add-multiplayer-scoring-and-completion

## Task List

### 1. Add score label node references to gameplay_screen.gd
- [x] Add @onready variables for ScoreP1, ScoreP2 labels using get_node() with full paths
- [x] Add @onready variables for FinishGamePopup, WinnerDisplay, FinishGameButton
- [x] Connect FinishGameButton.pressed signal to _on_finish_game_button_pressed handler
- [x] Initialize score labels to "0" in _ready() for multiplayer matches

**Validation:** Open gameplay_screen in editor, verify no errors about missing nodes

---

### 2. Implement score calculation logic
- [x] Create _calculate_score_from_results(container: VBoxContainer) -> int method
- [x] Iterate through container children (result_components)
- [x] Skip components where is_empty == true
- [x] Count results where was_correct == true from stored_results array
- [x] Return total count
- [x] Create _update_score_labels() method that calls calculation for both containers
- [x] Update ScoreP1 and ScoreP2 text with calculated scores

**Validation:** Add debug prints to see scores calculated, verify they match manual count

---

### 3. Update scores after each round completion
- [x] Call _update_score_labels() at end of _display_round_results() method
- [x] Verify scores update for both single-round and multi-round matches
- [x] Test that opponent scores only update after their results are revealed

**Validation:** Play 3-round match, check ScoreP1 increments after each round

---

### 4. Modify match completion logic to set status="finished"
- [x] In _handle_round_completion(), find block where both players finished final round
- [x] Replace UserDatabase.delete_match() call with match_data.status = "finished"
- [x] Call UserDatabase.update_match(match_data) to persist status change
- [x] Remove TransitionManager.change_scene() call from this block
- [x] Call _show_finish_popup() instead
- [x] Add early return after popup display

**Validation:** Complete match, verify it appears in user_database.json with status="finished"

---

### 5. Implement winner determination and popup display
- [x] Create _show_finish_popup() method
- [x] Call _calculate_score_from_results() for both containers
- [x] Compare scores: if p1 > p2, winner is my_username
- [x] Compare scores: if p2 > p1, winner is opponent_username
- [x] If equal, set winner_text to "Draw"
- [x] Format winner text as '"%s" won' % winner_name (with quotes)
- [x] Set winner_display.text to winner_text
- [x] Set finish_game_popup.visible = true

**Validation:** Finish matches with different scores, verify correct winner displayed

---

### 6. Implement finish button handler
- [x] Create _on_finish_game_button_pressed() method
- [x] Call UserDatabase.delete_match(match_id)
- [x] Call TransitionManager.change_scene("res://scenes/ui/main_lobby_screen.tscn")

**Validation:** Click FinishGameButton, verify return to lobby and match removed from list

---

### 7. Add modal overlay to FinishGamePopup
- [x] Open gameplay_screen.tscn in editor
- [x] Add ColorRect as first child of FinishGamePopup MarginContainer
- [x] Set anchors_preset = 15 (full rect)
- [x] Set color to Color(0, 0, 0, 0.5) (semi-transparent black)
- [x] Set mouse_filter = MOUSE_FILTER_STOP
- [x] Move PanelContainer to be sibling after ColorRect (not child)
- [x] Test that clicks on background are blocked when popup is visible

**Validation:** Show popup, try clicking PlayButton behind it, verify no action

---

### 8. Add get_all_matches_for_player() to user_database.gd
- [x] Create new method get_all_matches_for_player(username: String) -> Array
- [x] Iterate through data.multiplayer_matches
- [x] Filter where username in match.players (no status filter)
- [x] Return array of matching matches
- [x] Add documentation comment describing difference from get_active_matches_for_player()

**Validation:** Call method with test data, verify returns both active and finished matches

---

### 9. Update friendly_battle_page to show finished matches
- [x] Change _populate_active_matches() to call get_all_matches_for_player() instead of get_active_matches_for_player()
- [x] In label assignment logic, add condition: if match.status == "finished"
- [x] Set label_text = "Game Finished" for finished matches
- [x] Keep existing "Your Turn" and "{opponent} Turn" logic for active matches

**Validation:** Complete a match, verify it appears on friendly_battles_page with "Game Finished" label

---

### 10. Update friendly_battle_page to handle finished match clicks
- [x] In _on_avatar_clicked(), check match status before navigation
- [x] If status == "finished", navigate to gameplay_screen normally (shows final state with popup)
- [x] Ensure existing validation (match exists check) still works

**Validation:** Click "Game Finished" avatar, verify gameplay_screen opens with FinishGamePopup displayed

---

### 11. Initialize score labels early in match lifecycle
- [x] In gameplay_screen._ready(), ensure _update_score_labels() is called after _load_existing_match_state()
- [x] Verify score labels show "0" for new matches
- [x] Verify score labels show correct totals for resumed matches with completed rounds

**Validation:** Resume an in-progress match, verify scores reflect already-completed rounds

---

### 12. Test complete scoring flow end-to-end
- [x] Start new multiplayer match
- [x] Verify ScoreP1 and ScoreP2 start at "0"
- [x] Complete round 1 with 2/3 correct for P1
- [x] Verify ScoreP1 shows "2"
- [x] Wait for opponent (or test with second account)
- [x] Complete round 2 with 1/3 correct for P1
- [x] Verify ScoreP1 shows "3" (cumulative)
- [x] Complete final round
- [x] Verify FinishGamePopup appears with correct winner
- [x] Verify background is not clickable
- [x] Click FinishGameButton
- [x] Verify return to lobby
- [x] Verify match removed from friendly_battles_page

**Validation:** Full flow works as designed

---

### 13. Test draw scenario
- [x] Set up match where both players get same number of questions correct
- [x] Complete all rounds
- [x] Verify FinishGamePopup shows "Draw" (no quotes, no player name)

**Validation:** Draw text displays correctly

---

### 14. Test score display with varying results
- [x] Play match with 0 correct answers for P1
- [x] Verify ScoreP1 shows "0"
- [x] Play match with all correct answers for P1
- [x] Verify ScoreP1 shows total number of questions in match

**Validation:** Edge case scores display correctly

---

## Dependencies
- Task 2 must complete before tasks 3, 5
- Task 4 must complete before task 6
- Task 8 must complete before task 9
- Task 7 can be done in parallel with other tasks
- Tasks 12-14 are integration tests and should be done last

## Verification Checklist
- [x] openspec validate add-multiplayer-scoring-and-completion --strict passes
- [x] No console errors when opening gameplay_screen
- [x] Score labels update after each round
- [x] FinishGamePopup appears when match completes
- [x] Winner/Draw text is correct based on scores
- [x] FinishGameButton returns to lobby and removes match
- [x] Finished matches display on friendly_battles_page
- [x] Modal overlay blocks background interaction
- [x] Single-player mode is unaffected (scores remain hidden)
