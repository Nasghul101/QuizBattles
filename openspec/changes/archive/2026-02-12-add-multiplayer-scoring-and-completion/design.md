# Design: Multiplayer Scoring and Completion System

## Overview
This design implements a cumulative scoring system for multiplayer matches with proper completion flow, winner determination, and finished match display. The system tracks correct answers across all rounds, displays running totals, determines winners when all rounds are complete, and preserves finished matches until players explicitly dismiss them.

## Architecture

### Components Involved
1. **gameplay_screen.gd** - Score tracking, winner determination, popup management
2. **friendly_battle_page.gd** - Finished match display
3. **user_database.gd** - Match status persistence
4. **result_component.gd** - Already provides was_correct data (no changes)

### Data Flow

```
Round Completes
    ↓
_display_round_results() updates result_component
    ↓
_update_score_labels() counts correct answers from result_components
    ↓
ScoreP1 / ScoreP2 labels show cumulative totals
    ↓
Both players finish final round?
    ↓ YES
_show_finish_popup() determines winner
    ↓
FinishGamePopup displays winner or "Draw"
    ↓
Player clicks FinishGameButton
    ↓
delete_match() removes from database
    ↓
Return to main_lobby_screen
```

## Implementation Details

### 1. Score Tracking (gameplay_screen.gd)

**Node References:**
```gdscript
@onready var score_p1_label: Label = get_node("MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/ScoreP1")
@onready var score_p2_label: Label = get_node("MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/ScoreP2")
@onready var finish_game_popup: MarginContainer = $FinishGamePopup
@onready var winner_display: Label = $FinishGamePopup/PanelContainer/VBoxContainer/WinnerDisplay
@onready var finish_game_button: Button = $FinishGamePopup/PanelContainer/VBoxContainer/FinishGameButton
```

**Score Calculation:**
```gdscript
func _update_score_labels() -> void:
    if not is_multiplayer:
        return
    
    var p1_score = _calculate_score_from_results(result_container_l)
    var p2_score = _calculate_score_from_results(result_container_r)
    
    score_p1_label.text = str(p1_score)
    score_p2_label.text = str(p2_score)

func _calculate_score_from_results(container: VBoxContainer) -> int:
    var score = 0
    for result_component in container.get_children():
        if result_component.is_empty:
            continue
        
        for result_data in result_component.stored_results:
            if result_data.was_correct:
                score += 1
    
    return score
```

**Key Points:**
- Count from result_components (single source of truth)
- Only count non-empty components (skip unrevealed opponent rounds)
- Access `stored_results` array which has `was_correct` boolean
- Left container = P1 (logged-in player), Right container = P2 (opponent)

### 2. Winner Determination

**Trigger Condition:**
When both players finish the final round:
```gdscript
# In _handle_round_completion()
if opponent_answered and match_data.current_round >= num_rounds:
    # Both finished final round
    match_data.status = "finished"
    UserDatabase.update_match(match_data)
    _show_finish_popup()
    return  # Don't navigate away yet
```

**Winner Logic:**
```gdscript
func _show_finish_popup() -> void:
    var p1_score = _calculate_score_from_results(result_container_l)
    var p2_score = _calculate_score_from_results(result_container_r)
    
    var my_username = UserDatabase.current_user.username
    var winner_text = ""
    
    if p1_score > p2_score:
        winner_text = '"%s" won' % my_username
    elif p2_score > p1_score:
        winner_text = '"%s" won' % opponent_username
    else:
        winner_text = "Draw"
    
    winner_display.text = winner_text
    finish_game_popup.visible = true
```

**Display Format:**
- Winner: `"PlayerName" won` (with quotes around name)
- Draw: `Draw` (no quotes)

### 3. Popup Modal Behavior

**Blocking Interaction:**
Add ColorRect overlay as first child of FinishGamePopup (in .tscn file):
```gdscript
# Structure:
FinishGamePopup (MarginContainer)
    ColorRect (full-screen overlay with semi-transparent black)
        mouse_filter = MOUSE_FILTER_STOP
    PanelContainer
        VBoxContainer
            WinnerDisplay
            FinishGameButton
```

**Button Handler:**
```gdscript
func _on_finish_game_button_pressed() -> void:
    UserDatabase.delete_match(match_id)
    TransitionManager.change_scene("res://scenes/ui/main_lobby_screen.tscn")
```

### 4. Match Status Update

**In gameplay_screen.gd:**
```gdscript
# OLD (line ~344):
UserDatabase.delete_match(match_data.match_id)
TransitionManager.change_scene("res://scenes/ui/main_lobby_screen.tscn")
return

# NEW:
if match_data.current_round >= num_rounds:
    match_data.status = "finished"
    UserDatabase.update_match(match_data)
    _update_score_labels()  # Final score update
    _show_finish_popup()
    return
else:
    # Advance to next round (existing logic)
    match_data.current_round += 1
    # ...
```

### 5. Friendly Battle Page Updates

**In friendly_battle_page.gd:**
```gdscript
# Modify _populate_active_matches() to show ALL matches (active + finished)
var matches: Array = UserDatabase.get_all_matches_for_player(
    UserDatabase.current_user.username
)

# Update label logic:
var label_text = ""
if match.status == "finished":
    label_text = "Game Finished"
elif match.current_turn == UserDatabase.current_user.username:
    label_text = "Your Turn"
else:
    label_text = "%s Turn" % opponent_username

avatar.set_avatar_name(label_text)
```

**In user_database.gd:**
```gdscript
# Add new method:
func get_all_matches_for_player(username: String) -> Array:
    var player_matches: Array = []
    
    for match in data.multiplayer_matches:
        if username in match.players:
            player_matches.append(match)
    
    return player_matches
```

## Score Label Positioning

**Current TSCN Structure (no changes needed):**
```
HBoxContainer (alignment=1, center)
    ResultContainerL (left side - logged-in player)
    VBoxContainer3 (center - scores and play button)
        Label "Results"
        HBoxContainer (scores row)
            ScoreP1 (left player score)
            TextureRect (versus icon)
            ScoreP2 (right player score)
        PlayButton
    ResultContainerR (right side - opponent)
```

The ScoreP1 and ScoreP2 labels are already correctly positioned in the .tscn file with the versus icon between them.

## Initialization Timing

**Score labels must be initialized in _ready():**
```gdscript
func _ready() -> void:
    # ... existing code ...
    
    # Add score label references
    score_p1_label = get_node("MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/ScoreP1")
    score_p2_label = get_node("MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/ScoreP2")
    finish_game_popup = $FinishGamePopup
    winner_display = $FinishGamePopup/PanelContainer/VBoxContainer/WinnerDisplay
    finish_game_button = $FinishGamePopup/PanelContainer/VBoxContainer/FinishGameButton
    
    # Connect finish button
    finish_game_button.pressed.connect(_on_finish_game_button_pressed)
    
    # Initialize score labels
    if is_multiplayer:
        _update_score_labels()
```

**Update scores after each round completes:**
```gdscript
func _display_round_results(...) -> void:
    # ... existing display logic ...
    
    # Update cumulative scores
    _update_score_labels()
```

## Edge Cases

### Both Players Finish Simultaneously
- Each client independently sets status="finished" and calls _show_finish_popup()
- No race condition because both calculate the same winner from the same data
- UserDatabase.update_match() is idempotent for status changes

### Player Leaves Without Dismissing Finished Match
- Match remains in database with status="finished"
- Still appears on friendly_battles_page as "Game Finished"
- Clicking avatar opens gameplay_screen showing final state
- Player can then press FinishGameButton to clear it

### Score Updates Before Opponent Results Revealed
- _update_score_labels() only counts non-empty result_components
- Opponent's result_component stays empty until they also finish the round
- Score counts are always accurate based on currently visible data

### Player Tries to Click Through Popup
- ColorRect overlay with MOUSE_FILTER_STOP prevents clicks on background
- Only FinishGameButton is interactive when popup is shown

## Testing Considerations

### Manual Test Scenarios
1. **Score accumulation:** Play 3 rounds, verify ScoreP1 increases after each round
2. **Winner display:** Finish match with P1=5, P2=3, verify "PlayerName won" appears
3. **Draw display:** Finish match with P1=4, P2=4, verify "Draw" appears
4. **Modal blocking:** Try clicking PlayButton while popup is shown, verify no action
5. **Finished match display:** Complete match, return to lobby, verify "Game Finished" label
6. **Dismissal:** Click FinishGameButton, verify return to lobby and match removed from list

### Unit Test Ideas (future)
- `_calculate_score_from_results()` with mock result_components
- Winner determination logic with various score combinations
- Status transitions from "active" to "finished"
