# Design: Add Multiplayer Turn-Based Gameplay

## Architecture Overview

This design implements asynchronous turn-based multiplayer using **local UserDatabase storage** as a mock for future Firebase integration. The system maintains a clear separation between match state management (data layer), UI presentation (friendly_battle_page, gameplay_screen), and game flow logic (turn management, answer tracking).

### Key Design Principles
1. **Single Source of Truth**: UserDatabase stores all match state; screens always read from database
2. **Stateless Screens**: gameplay_screen and friendly_battle_page load fresh state on open
3. **Explicit Turn Management**: Current turn stored in match data, not inferred from answer state
4. **Match-Centric Navigation**: All multiplayer gameplay flows through match_id parameter
5. **Deferred Synchronization**: Local-first design prepares for Firebase migration without premature optimization

## Data Model

### Match Structure
```gdscript
# Stored in UserDatabase.multiplayer_matches: Array[Dictionary]
{
    "match_id": String,          # Unique UUID (e.g., "match_1234567890")
    "players": [String, String], # [inviter_username, invitee_username]
    "inviter": String,           # Username who sent invite
    "config": {
        "rounds": int,           # Total rounds (e.g., 3)
        "questions": int         # Questions per round (e.g., 2)
    },
    "current_turn": String,      # Username whose turn it is
    "current_round": int,        # 1-based round number (1 to config.rounds)
    "status": String,            # "active" | "completed"
    "rounds_data": [             # Array of round results, indexed by round-1
        {
            "round_number": int,           # 1-based
            "category": String,            # "" if not chosen yet
            "category_chooser": String,    # Username who should/did choose
            "questions": Array,            # Question data from TriviaService
            "player_answers": {
                "username1": {
                    "answered": bool,      # Has this player answered this round?
                    "results": []          # Array of answer_button results (only if answered)
                },
                "username2": {
                    "answered": bool,
                    "results": []
                }
            }
        }
    ],
    "created_at": int            # Unix timestamp
}
```

### Round State Machine
Each round progresses through these states:
1. **Not Started**: `category == "", both players.answered == false`
2. **Category Chosen**: `category != "", both players.answered == false`
3. **One Player Answered**: `category != "", one player.answered == true, other == false`
4. **Round Complete**: `category != "", both players.answered == true`

### Turn Logic
```gdscript
# Who chooses category in round N?
if (round_number % 2 == 1):  # Odd rounds (1, 3, 5...)
    return match.inviter
else:                         # Even rounds (2, 4, 6...)
    return match.players[1]   # Invitee (non-inviter)

# When does turn switch?
# After player completes all questions in their round
# Turn switches to opponent if:
#   - Both have answered current round: advance to next round, turn = next round's chooser
#   - Only current player answered: turn = opponent (to answer same round)
```

## Component Integration

### 1. Invite Flow (account_popup → setup_screen → notification)

```
account_popup._on_invite_to_game_button_pressed()
    ↓
close_popup()
    ↓
NavigationUtils.navigate_to_scene("setup_screen", {"invited_player": username})
    ↓
setup_screen.initialize({"invited_player": username})  # Store pending invite
    ↓
setup_screen._on_start_game_button_pressed()
    ↓
Create notification_data with:
    - action_data.invited_player
    - action_data.rounds
    - action_data.questions
    ↓
GlobalSignalBus.notification_received.emit(notification_data)
    ↓
NavigationUtils.navigate_to_scene("main_lobby")
```

### 2. Match Creation (notification acceptance)

```
main_lobby_screen._on_notification_action_taken(notification_id, "accept")
    ↓
UserDatabase.remove_notification(username, notification_id)
    ↓
GlobalSignalBus.game_invite_accepted.emit(inviter, invitee)
    ↓
UserDatabase._on_game_invite_accepted(inviter, invitee)  # Signal handler
    ↓
Extract rounds/questions from notification.action_data
    ↓
Generate unique match_id
    ↓
Create match structure with:
    - current_turn = inviter (inviter always starts)
    - current_round = 1
    - status = "active"
    - empty rounds_data array
    ↓
Append to UserDatabase.data.multiplayer_matches
    ↓
UserDatabase.save_data()
```

### 3. Display Active Matches (friendly_battle_page)

```
friendly_battle_page._ready()
    ↓
UserDatabase.get_active_matches_for_player(current_username)
    ↓
For each match:
    ↓
    Instantiate avatar_component
        ↓
        avatar.set_avatar_picture(opponent.avatar_path)
        avatar.set_match_id(match.match_id)
        avatar.set_avatar_name(turn_label_text)  # "Your Turn" or "[Player] Turn"
        ↓
        Connect avatar.avatar_clicked → _on_avatar_clicked(match_id)
```

### 4. Gameplay Flow (gameplay_screen with match_id)

```
friendly_battle_page._on_avatar_clicked(match_id)
    ↓
NavigationUtils.navigate_to_scene("gameplay_screen", {"match_id": match_id})
    ↓
gameplay_screen.initialize(params)
    ↓
Load match = UserDatabase.get_match(match_id)
    ↓
Determine current_player (left vs right based on username)
    ↓
Load current round state:
    - If both answered: show both results (colored)
    - If only opponent answered: show opponent results, own placeholders grey
    - If neither answered: show both grey
    ↓
Enable play_button if:
    - match.current_turn == UserDatabase.current_user.username
    - AND current player hasn't answered current round yet
```

### 5. Category Selection & Questions

```
gameplay_screen._on_play_button_pressed()
    ↓
Check if current round has category chosen:
    ↓
    If category == "":
        # I'm the category chooser
        Show category_popup with 3 random categories
        ↓
        _on_category_selected(category_name)
        ↓
        Update match.rounds_data[current_round-1].category = category_name
        Fetch questions from TriviaQuestionService
        ↓
        _on_questions_ready(questions)
        ↓
        Store questions in match.rounds_data[current_round-1].questions
        Show quiz_screen
    ↓
    Else (category already chosen):
        # Opponent chose category, I just answer
        Load questions from match.rounds_data[current_round-1].questions
        Show quiz_screen
```

### 6. Answer Submission & Turn Switch

```
gameplay_screen._on_question_answered(was_correct)
    ↓
Store result in current_round_results array
    ↓
If current_question_index < num_questions:
    Load next question
    ↓
Else (last question answered):
    ↓
    Update match:
        match.rounds_data[current_round-1].player_answers[my_username].answered = true
        match.rounds_data[current_round-1].player_answers[my_username].results = current_round_results
    ↓
    Check opponent status:
        ↓
        If opponent also answered this round:
            # Round complete - both players done
            Reveal opponent results (update result_components with colored buttons)
            ↓
            If current_round < num_rounds:
                # More rounds to play
                match.current_round += 1
                match.current_turn = (next round's category_chooser)
            Else:
                # Match complete
                match.status = "completed"
                Navigate to main_lobby_screen
                (match remains in database as completed)
        ↓
        Else (opponent hasn't answered yet):
            # Switch turn to opponent
            match.current_turn = opponent_username
    ↓
    UserDatabase.update_match(match)
    ↓
    If match not completed:
        Disable play_button (turn switched)
        Show "Waiting for opponent" or similar feedback
```

### 7. Answer Reveal After Round Complete

```
# When both players answer round N:
gameplay_screen._reveal_opponent_answers(round_index)
    ↓
Get opponent_results = match.rounds_data[round_index].player_answers[opponent_username].results
    ↓
Update result_components in opponent's container (left side):
        For each result in opponent_results:
            result_component.update_button_at_index(i, was_correct, answer_data)
```

## Screen Modifications

### account_popup.gd Changes
**Existing**: Sends basic invite notification, disables button
**New**: Navigate to setup_screen with invited player context

```gdscript
func _on_invite_to_game_button_pressed() -> void:
    # Disable button (keep existing behavior)
    invite_button.disabled = true
    
    # Close popup
    close_popup()
    
    # Navigate to setup screen with invited player
    var params = {"invited_player": current_displayed_user}
    NavigationUtils.navigate_to_scene("setup_screen", params)
```

### setup_screen.gd Changes
**Existing**: Transitions directly to gameplay_screen
**New**: Store invite context, send notification with config, return to lobby

```gdscript
var pending_invite_player: String = ""  # Added

func initialize(params: Dictionary) -> void:
    if params.has("invited_player"):
        pending_invite_player = params["invited_player"]

func _on_start_game_button_pressed() -> void:
    var rounds_value = int(rounds_slider.value)
    var questions_value = int(questions_slider.value)
    
    if pending_invite_player.is_empty():
        # Single-player mode (existing behavior - KEEP FOR NOW)
        var params = {"rounds": rounds_value, "questions": questions_value}
        TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)
    else:
        # Multiplayer invite mode (NEW)
        var notification_data = {
            "recipient_username": pending_invite_player,
            "message": "%s invites you to a duel (%d rounds, %d questions)" % [
                UserDatabase.current_user.username, rounds_value, questions_value
            ],
            "sender": UserDatabase.current_user.username,
            "has_actions": true,
            "action_data": {
                "type": "game_invite",
                "inviter_id": UserDatabase.current_user.username,
                "rounds": rounds_value,
                "questions": questions_value
            }
        }
        GlobalSignalBus.notification_received.emit(notification_data)
        
        # Clear pending invite
        pending_invite_player = ""
        
        # Return to lobby
        NavigationUtils.navigate_to_scene("main_lobby")
```

### gameplay_screen.gd Changes
**Existing**: Single-player with num_rounds/num_questions
**New**: Support match_id parameter, load match state, turn management

**Key additions:**
- `var match_id: String = ""`
- `var match_data: Dictionary = {}`
- `var is_multiplayer: bool = false`
- Modified `initialize()` to accept match_id
- Modified `_on_play_button_pressed()` to check category chosen
- Modified answer submission to update match state
- Added `_reveal_opponent_answers()` for round completion

### friendly_battle_page.gd Changes
**Existing**: Empty with just GridContainer reference
**New**: Load and display active matches as avatar_components

```gdscript
const AVATAR_COMPONENT = preload("res://scenes/ui/components/avatar_component.tscn")

func _ready() -> void:
    _populate_active_matches()

func _populate_active_matches() -> void:
    # Clear existing
    for child in friend_list.get_children():
        child.queue_free()
    
    if not UserDatabase.is_signed_in():
        return
    
    var matches = UserDatabase.get_active_matches_for_player(
        UserDatabase.current_user.username
    )
    
    for match in matches:
        var opponent = _get_opponent_username(match)
        var opponent_data = UserDatabase.get_user_data_for_display(opponent)
        
        var avatar = AVATAR_COMPONENT.instantiate()
        friend_list.add_child(avatar)
        
        avatar.set_avatar_picture(opponent_data.avatar_path)
        avatar.set_match_id(match.match_id)
        
        # Set turn label
        if match.current_turn == UserDatabase.current_user.username:
            avatar.set_avatar_name("Your Turn")
        else:
            avatar.set_avatar_name("%s Turn" % opponent)
        
        avatar.avatar_clicked.connect(_on_avatar_clicked)

func _on_avatar_clicked(match_id: String) -> void:
    NavigationUtils.navigate_to_scene("gameplay_screen", {"match_id": match_id})
```

## UserDatabase API Extensions

### New Methods
```gdscript
# Match CRUD
func create_match(inviter: String, invitee: String, rounds: int, questions: int) -> String
func get_match(match_id: String) -> Dictionary
func update_match(match_data: Dictionary) -> void
func get_active_matches_for_player(username: String) -> Array[Dictionary]
func delete_match(match_id: String) -> void  # For completed matches cleanup (future)

# Signal handler
func _on_game_invite_accepted(inviter: String, invitee: String) -> void
    # Auto-create match when invite accepted
    # Extract rounds/questions from notification action_data
```

### Schema Migration
```gdscript
# In UserDatabase._ready() or load_data()
if not data.has("multiplayer_matches"):
    data["multiplayer_matches"] = []
    save_data()
```

## Turn State Validation

### Play Button Enable Logic
```gdscript
func _update_play_button_state() -> void:
    if not is_multiplayer:
        play_button.disabled = false  # Single-player always enabled
        return
    
    var is_my_turn = (match_data.current_turn == UserDatabase.current_user.username)
    var current_round_idx = match_data.current_round - 1
    var my_answered = match_data.rounds_data[current_round_idx].player_answers[
        UserDatabase.current_user.username
    ].answered
    
    play_button.disabled = not (is_my_turn and not my_answered)
```

## Edge Cases & Error Handling

1. **Match not found**: If match_id invalid, show error and return to lobby
2. **Opponent deleted account**: Show "Opponent no longer available" (future)
3. **Concurrent updates**: Last write wins (acceptable for local storage; Firebase will handle properly)
4. **Malformed match data**: Validate structure on load, log errors, provide defaults
5. **Single-player regression**: Keep existing behavior if no match_id provided
6. **Empty friendly_battle_page**: Show placeholder text "No active matches"

## Testing Strategy

### Unit Tests (Manual Verification)
- [ ] Match creation with correct initial state
- [ ] Turn switching after round completion
- [ ] Category chooser determination (odd/even rounds)
- [ ] Answer reveal only after both players complete round
- [ ] Multiple simultaneous matches don't interfere

### Integration Tests (Manual Gameplay)
- [ ] Full flow: invite → accept → play → complete
- [ ] Inviter chooses category in round 1, invitee in round 2
- [ ] Grey placeholders until opponent answers
- [ ] Results reveal after round completion
- [ ] Match persists across app restart
- [ ] Play button enables/disables correctly

## Future Considerations (Out of Scope)

- **Firebase Migration**: Match structure designed for Firebase Realtime Database (flat key-value structure)
- **Push Notifications**: When turn changes, notify via Firebase Cloud Messaging
- **Rematch**: Add "Play Again" button after match completes
- **Statistics**: Track wins/losses per match for leaderboards
- **Spectator Mode**: Allow viewing active matches without participating
- **Chat**: In-match messaging between players
- **Time Limits**: Auto-forfeit if player doesn't answer within timeframe

## Performance Considerations

- **Deferred**: No optimization for large match lists (show all active matches)
- **Deferred**: No lazy loading of match data (load full match each time)
- **Deferred**: No caching of opponent user data (fetch on each display)

Performance will be addressed when Firebase integration requires it.
