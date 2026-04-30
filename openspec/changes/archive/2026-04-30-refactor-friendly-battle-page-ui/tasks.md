# Tasks: Refactor Friendly Battle Page UI

## Implementation Order
Tasks are ordered to deliver incremental, verifiable progress. Each task is small enough to complete in one focused session and includes validation steps.

## Checklist
- [x] Task 1: Add score calculation helper function
- [x] Task 2: Update preload constants to use new button components
- [x] Task 3: Refactor _populate_active_matches to use filtered matches
- [x] Task 4: Implement alternating button instantiation logic
- [x] Task 5: Populate button with match data (scores, round, name)
- [x] Task 6: Implement highlight/unhighlight based on turn
- [x] Task 7: Connect button pressed signal to navigation
- [x] Task 8: Remove unused code and update comments
- [x] Task 9: Manual testing across scenarios
- [x] Task 10: Update related documentation

---

### Task 1: Add score calculation helper function
**Objective**: Create a reusable function to calculate cumulative scores from match data

**Steps**:
1. Open `scenes/ui/lobby_pages/friendly_battle_page.gd`
2. Add new private method `_calculate_player_score(match: Dictionary, username: String) -> int`
3. Iterate through `match.rounds_data` array
4. For each round, check if `round.player_answers[username].answered == true`
5. If answered, count correct results in `round.player_answers[username].results` array
6. Return total count of correct answers across all rounds

**Expected Code**:
```gdscript
## Calculate cumulative score for a player across all rounds
##
## @param match: Match Dictionary containing rounds_data
## @param username: Player's username to calculate score for
## @return int: Total number of correct answers across all rounds
func _calculate_player_score(match: Dictionary, username: String) -> int:
    var score = 0
    for round_data in match.rounds_data:
        if round_data.player_answers.has(username):
            var player_answer = round_data.player_answers[username]
            if player_answer.answered:
                for result in player_answer.results:
                    if result.was_correct:
                        score += 1
    return score
```

**Validation**:
- Function compiles without errors
- Returns 0 for player with no answered rounds
- Returns correct count for player with multiple answered rounds

**Dependencies**: None

---

### Task 2: Update preload constants to use new button components
**Objective**: Replace avatar_component references with friendly_duel_button_l and friendly_duel_button_r

**Steps**:
1. Open `scenes/ui/lobby_pages/friendly_battle_page.gd`
2. Replace `const AVATAR_COMPONENT = preload("res://scenes/ui/components/avatar_component.tscn")`
3. With two new constants:
   ```gdscript
   const FRIENDLY_DUEL_BUTTON_L = preload("res://scenes/ui/components/friendly_duel_button_l.tscn")
   const FRIENDLY_DUEL_BUTTON_R = preload("res://scenes/ui/components/friendly_duel_button_r.tscn")
   ```

**Validation**:
- File compiles without errors
- Constants are accessible within the script

**Dependencies**: None

---

### Task 3: Refactor _populate_active_matches to use filtered matches
**Objective**: Filter out finished matches and update match retrieval logic

**Steps**:
1. In `_populate_active_matches()`, keep the existing `get_all_matches_for_player()` call
2. Update the filtering logic to exclude both dismissed matches AND finished matches:
   ```gdscript
   var matches: Array = []
   for match in all_matches:
       var dismissed_by = match.get("dismissed_by", [])
       var is_finished = match.get("status") == "finished"
       if UserDatabase.current_user.username not in dismissed_by and not is_finished:
           matches.append(match)
   ```
3. Keep the NoMatchesLabel visibility logic unchanged

**Validation**:
- Page shows only active matches
- Finished matches are hidden
- NoMatchesLabel appears when no active matches exist

**Dependencies**: None

---

### Task 4: Implement alternating button instantiation logic
**Objective**: Instantiate buttons alternating between left and right containers

**Steps**:
1. In `_populate_active_matches()`, after filtering matches, replace the avatar instantiation loop
2. Add match counter: `var match_index = 0`
3. For each match:
   - Determine target container: `var target_list = friend_list_l if match_index % 2 == 0 else friend_list_r`
   - Determine button scene: `var button_scene = FRIENDLY_DUEL_BUTTON_L if match_index % 2 == 0 else FRIENDLY_DUEL_BUTTON_R`
   - Instantiate button: `var button = button_scene.instantiate()`
   - Add to target container: `target_list.add_child(button)`
   - Increment match_index
4. Update clear logic to clear both containers:
   ```gdscript
   for child in friend_list_l.get_children():
       child.queue_free()
   for child in friend_list_r.get_children():
       child.queue_free()
   ```

**Validation**:
- First match appears on left
- Second match appears on right
- Pattern continues alternating
- Odd-numbered total results in extra button on left

**Dependencies**: Task 2

---

### Task 5: Populate button with match data (scores, round, name)
**Objective**: Set all button properties using the new API

**Steps**:
1. Inside the match loop (from Task 4), after instantiating the button:
2. Get opponent username: `var opponent_username = _get_opponent_username(match)`
3. Calculate scores:
   ```gdscript
   var player_score = _calculate_player_score(match, UserDatabase.current_user.username)
   var opponent_score = _calculate_player_score(match, opponent_username)
   ```
4. Set button properties:
   ```gdscript
   button.set_player_points(player_score)
   button.set_opponents_points(opponent_score)
   button.set_round_count(match.current_round)
   button.set_opponent_name(opponent_username)
   ```

**Validation**:
- Button displays correct player score
- Button displays correct opponent score
- Button displays current round number
- Button displays opponent's name

**Dependencies**: Task 1, Task 4

---

### Task 6: Implement highlight/unhighlight based on turn
**Objective**: Replace text-based turn indicator with visual highlighting

**Steps**:
1. After setting button properties (Task 5), add turn logic:
   ```gdscript
   if match.current_turn == UserDatabase.current_user.username:
       button.highlight()
   else:
       button.un_highlight()
   ```
2. Remove any remaining `set_avatar_name()` calls related to turn status

**Validation**:
- Button is highlighted when it's the player's turn
- Button is unhighlighted when it's the opponent's turn
- Highlight updates correctly after page refresh (return from gameplay_screen)

**Dependencies**: Task 5

---

### Task 7: Connect button pressed signal to navigation
**Objective**: Enable clicking buttons to navigate to gameplay_screen

**Steps**:
1. After setting button properties and highlight state, connect the pressed signal:
   ```gdscript
   button.pressed.connect(_on_button_pressed.bind(match.match_id))
   ```
2. Create new handler method (or rename existing `_on_avatar_clicked`):
   ```gdscript
   func _on_button_pressed(match_id: String) -> void:
       var match = UserDatabase.get_match(match_id)
       if match.is_empty():
           push_warning("Cannot navigate: match not found %s" % match_id)
           _populate_active_matches()
           return
       
       var params = {"match_id": match_id}
       TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)
   ```

**Validation**:
- Clicking button navigates to gameplay_screen
- Correct match_id is passed
- Invalid match_id triggers warning and refresh

**Dependencies**: Task 6

---

### Task 8: Remove unused code and update comments
**Objective**: Clean up legacy avatar_component references

**Steps**:
1. Remove `set_avatar_picture()` calls if any remain
2. Remove `set_match_id()` calls (not needed with bind approach)
3. Remove `avatar_clicked` signal connection code
4. Update function documentation comments:
   - Change "avatar_component" to "friendly_duel_button"
   - Update description to mention alternating left/right placement
5. Verify `_on_match_created` signal handler still calls `_populate_active_matches()`

**Validation**:
- No compiler warnings about unused variables
- Code comments accurately reflect new implementation
- File passes GDScript linter

**Dependencies**: Task 7

---

### Task 9: Manual testing across scenarios
**Objective**: Verify all user-facing behaviors work correctly

**Test Cases**:
1. **Empty state**: Sign out, verify NoMatchesLabel appears
2. **Single match (left side)**: Create 1 match, verify it appears on left
3. **Two matches (both sides)**: Create 2 matches, verify left-right placement
4. **Odd matches (3)**: Create 3 matches, verify 2 left, 1 right
5. **Score display**: Play some rounds, verify cumulative scores update
6. **Turn indicator**: 
   - Verify highlight when your turn
   - Play turn in gameplay_screen
   - Return to page
   - Verify unhighlight when opponent's turn
7. **Navigation**: Click each button, verify correct match opens
8. **Finished match hidden**: Finish a match in gameplay_screen, verify it disappears from list

**Validation**:
- All test cases pass
- No visual glitches or layout issues
- Highlight state correct in all scenarios

**Dependencies**: Task 8

---

### Task 10: Update related documentation
**Objective**: Ensure documentation reflects new implementation

**Steps**:
1. Update any architecture docs referencing friendly_battle_page
2. Update code comments in related files if they reference avatar_component usage
3. Verify openspec spec delta is accurate (completed in parallel track)

**Validation**:
- Documentation is consistent with implementation
- No outdated references to avatar_component in friendly_battle_page context

**Dependencies**: Task 9

---

## Summary
10 tasks total, estimated 3-4 hours for implementation and testing. Tasks 1-8 are code changes, Task 9 is manual testing, Task 10 is documentation updates. Each task builds on the previous, ensuring incremental progress with clear validation checkpoints.
