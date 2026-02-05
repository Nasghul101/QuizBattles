# Tasks: Add Multiplayer Turn-Based Gameplay

## Implementation Order

Tasks are ordered to deliver user-visible progress incrementally while maintaining dependencies. Each task is small, verifiable, and builds on previous work.

---

## Phase 1: Data Layer Foundation

### Task 1: Extend UserDatabase schema for multiplayer matches
**Objective**: Add multiplayer_matches array to database structure

**Steps**:
1. Open `autoload/user_database.gd`
2. In `_ready()` or `load_data()`, add schema migration:
   ```gdscript
   if not data.has("multiplayer_matches"):
       data["multiplayer_matches"] = []
       save_data()
   ```
3. Verify by checking `data/user_database.json` after running game

**Validation**:
- `user_database.json` contains `"multiplayer_matches": []` after first run

**Dependencies**: None

---

### Task 2: Add match creation method to UserDatabase
**Objective**: Implement `create_match()` to generate new match entries

**Steps**:
1. Add method to `user_database.gd`:
   ```gdscript
   ## Create a new multiplayer match between two players
   ##
   ## @param inviter: Username who sent the invitation
   ## @param invitee: Username who accepted the invitation
   ## @param rounds: Number of rounds to play
   ## @param questions: Number of questions per round
   ## @return match_id: Unique identifier for the created match
   func create_match(inviter: String, invitee: String, rounds: int, questions: int) -> String:
       var match_id = "match_%d" % Time.get_unix_time_from_system()
       
       var match_data = {
           "match_id": match_id,
           "players": [inviter, invitee],
           "inviter": inviter,
           "config": {
               "rounds": rounds,
               "questions": questions
           },
           "current_turn": inviter,  # Inviter always starts
           "current_round": 1,
           "status": "active",
           "rounds_data": [],
           "created_at": Time.get_unix_time_from_system()
       }
       
       # Initialize rounds_data with empty structures
       for i in range(rounds):
           var round_data = {
               "round_number": i + 1,
               "category": "",
               "category_chooser": inviter if (i + 1) % 2 == 1 else invitee,
               "questions": [],
               "player_answers": {
                   inviter: {
                       "answered": false,
                       "results": []
                   },
                   invitee: {
                       "answered": false,
                       "results": []
                   }
               }
           }
           match_data.rounds_data.append(round_data)
       
       data.multiplayer_matches.append(match_data)
       save_data()
       
       return match_id
   ```

**Validation**:
- Call method manually in test scenario
- Verify match appears in `user_database.json` with correct structure

**Dependencies**: Task 1

---

### Task 3: Add match retrieval methods to UserDatabase
**Objective**: Implement getter methods for match data

**Steps**:
1. Add `get_match()` method:
   ```gdscript
   ## Retrieve a specific match by ID
   ##
   ## @param match_id: Unique identifier of the match
   ## @return Dictionary: Match data, or empty Dictionary if not found
   func get_match(match_id: String) -> Dictionary:
       for match in data.multiplayer_matches:
           if match.match_id == match_id:
               return match
       
       push_warning("Match not found: %s" % match_id)
       return {}
   ```

2. Add `get_active_matches_for_player()` method:
   ```gdscript
   ## Get all active matches for a specific player
   ##
   ## @param username: Player's username
   ## @return Array[Dictionary]: List of active matches where player is participant
   func get_active_matches_for_player(username: String) -> Array:
       var player_matches: Array = []
       
       for match in data.multiplayer_matches:
           if match.status == "active" and username in match.players:
               player_matches.append(match)
       
       return player_matches
   ```

**Validation**:
- Create test matches with Task 2's method
- Retrieve with `get_match()` and verify data matches
- Verify `get_active_matches_for_player()` filters correctly

**Dependencies**: Task 2

---

### Task 4: Add match update method to UserDatabase
**Objective**: Implement `update_match()` to persist state changes

**Steps**:
1. Add method to `user_database.gd`:
   ```gdscript
   ## Update an existing match with new data
   ##
   ## @param match_data: Complete match Dictionary with updated fields
   func update_match(match_data: Dictionary) -> void:
       if not match_data.has("match_id"):
           push_error("Cannot update match: missing match_id")
           return
       
       for i in range(data.multiplayer_matches.size()):
           if data.multiplayer_matches[i].match_id == match_data.match_id:
               data.multiplayer_matches[i] = match_data
               save_data()
               return
       
       push_warning("Match not found for update: %s" % match_data.match_id)
   ```

**Validation**:
- Retrieve match, modify a field, call `update_match()`
- Verify changes persist in `user_database.json`

**Dependencies**: Task 3

---

## Phase 2: Invite Flow Integration

### Task 5: Modify setup_screen to support multiplayer invites
**Objective**: Store invited player context and send enhanced notifications

**Steps**:
1. Open `scenes/ui/setup_screen.gd`
2. Add variable at top:
   ```gdscript
   var pending_invite_player: String = ""
   ```

3. Modify or add `initialize()` method:
   ```gdscript
   ## Initialize setup screen with optional parameters
   ##
   ## @param params: Dictionary with optional "invited_player" key
   func initialize(params: Dictionary) -> void:
       if params.has("invited_player"):
           pending_invite_player = params["invited_player"]
   ```

4. Modify `_on_start_game_button_pressed()`:
   ```gdscript
   func _on_start_game_button_pressed() -> void:
       var rounds_value: int = int(rounds_slider.value)
       var questions_value: int = int(questions_slider.value)
       
       if pending_invite_player.is_empty():
           # Single-player mode (existing behavior)
           var params: Dictionary = {
               "rounds": rounds_value,
               "questions": questions_value
           }
           TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)
       else:
           # Multiplayer invite mode
           var notification_data: Dictionary = {
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
           
           # Return to main lobby
           NavigationUtils.navigate_to_scene("main_lobby")
   ```

**Validation**:
- Click "Invite to Game" → setup opens
- Configure rounds/questions, click "Start Game"
- Verify notification appears with rounds/questions in action_data
- Verify navigation returns to main_lobby_screen

**Dependencies**: None (uses existing systems)

---

### Task 6: Modify account_popup to navigate to setup_screen
**Objective**: Connect "Invite to Game" button to setup screen

**Steps**:
1. Open `scenes/ui/account_ui/account_popup.gd`
2. Modify `_on_invite_to_game_button_pressed()`:
   ```gdscript
   func _on_invite_to_game_button_pressed() -> void:
       # Check validations (keep existing)
       if not UserDatabase.is_signed_in():
           push_warning("Cannot send game invite: user not signed in")
           return
       
       if current_displayed_user.is_empty():
           push_warning("Cannot send game invite: no user displayed")
           return
       
       # Disable button (keep existing)
       invite_button.disabled = true
       
       # Close popup
       close_popup()
       
       # Navigate to setup screen with invited player context
       var params: Dictionary = {"invited_player": current_displayed_user}
       NavigationUtils.navigate_to_scene("setup_screen", params)
   ```

**Validation**:
- Click "Invite to Game" on friend's account_popup
- Verify popup closes
- Verify setup_screen opens
- Verify player can configure and send invite

**Dependencies**: Task 5

---

### Task 7: Connect game invite acceptance to match creation
**Objective**: Auto-create match when invite accepted

**Steps**:
1. Open `autoload/user_database.gd`
2. Add signal handler in `_ready()`:
   ```gdscript
   func _ready() -> void:
       # ... existing code ...
       
       # Connect to game invite signal
       GlobalSignalBus.game_invite_accepted.connect(_on_game_invite_accepted)
   ```

3. Add handler method:
   ```gdscript
   ## Handle game invite acceptance by creating a match
   ##
   ## Extracts rounds/questions from the most recent game invite notification
   ## for the invitee and creates a persistent match entry.
   ##
   ## @param inviter_username: Username who sent the invite
   ## @param invitee_username: Username who accepted the invite
   func _on_game_invite_accepted(inviter_username: String, invitee_username: String) -> void:
       # Find the notification with game invite data
       var notifications = get_notifications(invitee_username)
       var rounds = 3  # Default fallback
       var questions = 2  # Default fallback
       
       for notification in notifications:
           if notification.has("action_data") and notification.action_data.get("type") == "game_invite":
               if notification.action_data.get("inviter_id") == inviter_username:
                   rounds = notification.action_data.get("rounds", 3)
                   questions = notification.action_data.get("questions", 2)
                   break
       
       # Create the match
       var match_id = create_match(inviter_username, invitee_username, rounds, questions)
       print("Match created: %s between %s and %s (%d rounds, %d questions)" % [
           match_id, inviter_username, invitee_username, rounds, questions
       ])
   ```

**Validation**:
- Send invite with specific rounds/questions
- Accept invite
- Verify match appears in `user_database.json`
- Verify match has correct configuration

**Dependencies**: Task 2, Task 6

---

## Phase 3: Friendly Battle Page

### Task 8: Implement friendly_battle_page match loading
**Objective**: Display avatar_components for active matches

**Steps**:
1. Open `scenes/ui/lobby_pages/friendly_battle_page.gd`
2. Replace contents with:
   ```gdscript
   extends Control
   
   const AVATAR_COMPONENT = preload("res://scenes/ui/components/avatar_component.tscn")
   
   @onready var friend_list: GridContainer = %FriendsList
   
   
   func _ready() -> void:
       _populate_active_matches()
   
   
   ## Populate friend_list with avatar_components for active multiplayer matches
   func _populate_active_matches() -> void:
       # Clear existing children
       for child in friend_list.get_children():
           child.queue_free()
       
       # Return early if user is not signed in
       if not UserDatabase.is_signed_in():
           return
       
       # Get active matches for current user
       var matches: Array = UserDatabase.get_active_matches_for_player(
           UserDatabase.current_user.username
       )
       
       # Create avatar_component for each match
       for match in matches:
           var opponent_username = _get_opponent_username(match)
           var opponent_data = UserDatabase.get_user_data_for_display(opponent_username)
           
           if opponent_data.is_empty():
               continue  # Skip if opponent data not found
           
           var avatar: Button = AVATAR_COMPONENT.instantiate()
           friend_list.add_child(avatar)
           
           # Set avatar picture to opponent's profile
           avatar.set_avatar_picture(opponent_data.avatar_path)
           
           # Set match ID for navigation context
           avatar.set_match_id(match.match_id)
           
           # Set turn status label
           var label_text = ""
           if match.current_turn == UserDatabase.current_user.username:
               label_text = "Your Turn"
           else:
               label_text = "%s Turn" % opponent_username
           avatar.set_avatar_name(label_text)
           
           # Connect click signal
           avatar.avatar_clicked.connect(_on_avatar_clicked)
   
   
   ## Get opponent's username from match data
   ##
   ## @param match: Match Dictionary
   ## @return String: Opponent's username
   func _get_opponent_username(match: Dictionary) -> String:
       var current_username = UserDatabase.current_user.username
       for player in match.players:
           if player != current_username:
               return player
       return ""
   
   
   ## Handle avatar click to navigate to gameplay screen
   ##
   ## @param match_id: Match identifier passed from avatar component
   func _on_avatar_clicked(match_id: String) -> void:
       var params = {"match_id": match_id}
       NavigationUtils.navigate_to_scene("gameplay_screen", params)
   ```

**Validation**:
- Create test match with Task 2
- Navigate to friendly_battle_page
- Verify avatar appears with opponent's picture
- Verify turn label shows "Your Turn" or "[Player] Turn"
- Click avatar and verify navigation intent (will error until Task 10)

**Dependencies**: Task 3, Task 9

---

### Task 9: Add match_id support to avatar_component
**Objective**: Allow avatar to store and emit match_id

**Steps**:
1. Open `scenes/ui/components/avatar_component.gd`
2. Add variable:
   ```gdscript
   var match_id: String = ""
   ```

3. Add setter method:
   ```gdscript
   ## Store match identifier for multiplayer navigation
   ##
   ## @param id: Match ID string
   func set_match_id(id: String) -> void:
       match_id = id
   ```

4. Modify `_on_pressed()` (or `_pressed()` signal handler):
   ```gdscript
   func _on_pressed() -> void:
       if not user_id.is_empty():
           avatar_clicked.emit(user_id)
       elif not match_id.is_empty():
           avatar_clicked.emit(match_id)
   ```

**Validation**:
- Set match_id on avatar
- Click avatar
- Verify signal emits with match_id

**Dependencies**: None

---

## Phase 4: Gameplay Screen Multiplayer Support

### Task 10: Add match_id parameter to gameplay_screen initialization
**Objective**: Detect multiplayer mode and load match state

**Steps**:
1. Open `scenes/ui/gameplay_screen.gd`
2. Add variables at top:
   ```gdscript
   var match_id: String = ""
   var match_data: Dictionary = {}
   var is_multiplayer: bool = false
   var opponent_username: String = ""
   ```

3. Modify `initialize()` method:
   ```gdscript
   func initialize(params: Dictionary) -> void:
       if params.has("match_id"):
           # Multiplayer mode
           match_id = params["match_id"]
           is_multiplayer = true
           
           # Load match data
           match_data = UserDatabase.get_match(match_id)
           if match_data.is_empty():
               push_error("Match not found: %s" % match_id)
               NavigationUtils.navigate_to_scene("main_lobby")
               return
           
           # Set configuration from match
           num_rounds = match_data.config.rounds
           num_questions = match_data.config.questions
           
           # Determine opponent
           for player in match_data.players:
               if player != UserDatabase.current_user.username:
                   opponent_username = player
                   break
       
       elif params.has("rounds") and params.has("questions"):
           # Single-player mode (existing behavior)
           is_multiplayer = false
           num_rounds = params["rounds"]
           num_questions = params["questions"]
       
       # Initialize result components will be called from _ready()
   ```

**Validation**:
- Navigate to gameplay_screen with match_id parameter
- Verify match loads correctly
- Verify num_rounds and num_questions set from match config
- Verify opponent_username populated

**Dependencies**: Task 3, Task 8

---

### Task 11: Implement turn-based play button logic
**Objective**: Enable/disable play button based on turn state

**Steps**:
1. In `gameplay_screen.gd`, add method:
   ```gdscript
   ## Update play button enabled/disabled state based on turn
   func _update_play_button_state() -> void:
       if not is_multiplayer:
           play_button.disabled = false
           return
       
       # Check if it's my turn
       var is_my_turn = (match_data.current_turn == UserDatabase.current_user.username)
       
       # Check if I've already answered current round
       var current_round_idx = match_data.current_round - 1
       var my_answered = match_data.rounds_data[current_round_idx].player_answers.get(
           UserDatabase.current_user.username, {}
       ).get("answered", false)
       
       # Enable only if my turn AND I haven't answered yet
       play_button.disabled = not (is_my_turn and not my_answered)
   ```

2. Call `_update_play_button_state()` in `_ready()` after initializing components:
   ```gdscript
   func _ready() -> void:
       # ... existing initialization code ...
       
       # Update play button state for multiplayer
       if is_multiplayer:
           _update_play_button_state()
   ```

**Validation**:
- Load match where it's your turn → play button enabled
- Load match where it's opponent's turn → play button disabled
- Load match where you already answered → play button disabled

**Dependencies**: Task 10

---

### Task 12: Implement category selection logic for multiplayer
**Objective**: Chooser selects category, opponent uses pre-selected category

**Steps**:
1. In `gameplay_screen.gd`, modify `_on_play_button_pressed()`:
   ```gdscript
   func _on_play_button_pressed() -> void:
       if is_multiplayer:
           var current_round_idx = match_data.current_round - 1
           var round_data = match_data.rounds_data[current_round_idx]
           
           if round_data.category == "":
               # I'm the category chooser - show selection
               var all_categories = TriviaQuestionService.get_available_categories()
               var random_categories: Array = []
               
               var available = all_categories.duplicate()
               available.shuffle()
               for i in range(min(3, available.size())):
                   random_categories.append(available[i])
               
               category_popup.show_categories(random_categories)
               play_button.visible = false
           
           else:
               # Opponent already chose category - load questions directly
               selected_category = round_data.category
               fetched_questions = round_data.questions
               
               # Start quiz immediately
               current_question_index = 0
               current_round_results = []
               current_round += 1  # Track locally for display
               
               quiz_screen.visible = true
               quiz_screen.load_question(fetched_questions[0])
       
       else:
           # Single-player mode (existing behavior)
           var all_categories = TriviaQuestionService.get_available_categories()
           var random_categories: Array = []
           
           var available = all_categories.duplicate()
           available.shuffle()
           for i in range(min(3, available.size())):
               random_categories.append(available[i])
           
           category_popup.show_categories(random_categories)
           play_button.visible = false
   ```

**Validation**:
- First player in round: category popup appears
- Second player in round: questions load immediately
- Verify questions match opponent's category choice

**Dependencies**: Task 11

---

### Task 13: Store questions in match data after category selection
**Objective**: Save questions so opponent can answer the same ones

**Steps**:
1. In `gameplay_screen.gd`, modify `_on_questions_ready()`:
   ```gdscript
   func _on_questions_ready(questions: Array) -> void:
       print("[GameplayScreen] Received %d questions from TriviaQuestionService" % questions.size())
       
       # Hide category popup
       category_popup.visible = false
       
       # Store questions
       fetched_questions = questions
       
       # If multiplayer, store in match data
       if is_multiplayer:
           var current_round_idx = match_data.current_round - 1
           match_data.rounds_data[current_round_idx].category = selected_category
           match_data.rounds_data[current_round_idx].questions = questions
           UserDatabase.update_match(match_data)
       
       # Initialize quiz state
       current_question_index = 0
       current_round_results = []
       current_round += 1  # Increment local round counter for display
       
       # Show quiz screen with first question
       quiz_screen.visible = true
       quiz_screen.load_question(questions[0])
   ```

**Validation**:
- Choose category, answer questions
- Check `user_database.json`: verify questions and category stored
- Load as opponent: verify same questions appear

**Dependencies**: Task 12

---

### Task 14: Implement answer submission and turn switching
**Objective**: Store player answers, update turn state, handle round completion

**Steps**:
1. In `gameplay_screen.gd`, find where last question is answered (in `_on_question_answered()` or similar)
2. Replace or modify with:
   ```gdscript
   func _on_question_answered(was_correct: bool) -> void:
       # Store result in temporary array
       var result_data = {
           "correct": was_correct,
           # Store additional answer data if needed
       }
       current_round_results.append(result_data)
       
       # Check if more questions remain
       if current_question_index < num_questions - 1:
           # Load next question
           current_question_index += 1
           quiz_screen.load_question(fetched_questions[current_question_index])
       
       else:
           # Last question answered - handle round completion
           _handle_round_completion()
   
   
   ## Handle completion of current round by current player
   func _handle_round_completion() -> void:
       quiz_screen.visible = false
       
       if is_multiplayer:
           # Store my answers in match data
           var current_round_idx = match_data.current_round - 1
           var my_username = UserDatabase.current_user.username
           
           match_data.rounds_data[current_round_idx].player_answers[my_username].answered = true
           match_data.rounds_data[current_round_idx].player_answers[my_username].results = current_round_results
           
           # Display my results on right side
           _display_round_results(current_round_idx, my_username, "right")
           
           # Check if opponent also answered
           var opponent_answered = match_data.rounds_data[current_round_idx].player_answers[opponent_username].answered
           
           if opponent_answered:
               # Both answered - reveal opponent results and advance round
               _display_round_results(current_round_idx, opponent_username, "left")
               
               # Check if more rounds remain
               if match_data.current_round < num_rounds:
                   # Advance to next round
                   match_data.current_round += 1
                   var next_round_idx = match_data.current_round - 1
                   match_data.current_turn = match_data.rounds_data[next_round_idx].category_chooser
               
               else:
                   # Match complete
                   match_data.status = "completed"
                   UserDatabase.update_match(match_data)
                   
                   # Return to lobby
                   NavigationUtils.navigate_to_scene("main_lobby")
                   return
           
           else:
               # Only I answered - switch turn to opponent
               match_data.current_turn = opponent_username
           
           # Save match state
           UserDatabase.update_match(match_data)
           
           # Update play button state
           _update_play_button_state()
       
       else:
           # Single-player mode (existing behavior)
           # Display results, etc.
           pass
   ```

**Validation**:
- Answer all questions as Player 1
- Verify turn switches to Player 2
- Answer as Player 2
- Verify both results appear, round advances
- Complete all rounds, verify return to lobby

**Dependencies**: Task 13

---

### Task 15: Implement result display for multiplayer
**Objective**: Show colored result buttons after answers submitted

**Steps**:
1. Add helper method to `gameplay_screen.gd`:
   ```gdscript
   ## Display round results in appropriate result_component
   ##
   ## @param round_idx: 0-based round index
   ## @param username: Player whose results to display
   ## @param side: "left" or "right" container
   func _display_round_results(round_idx: int, username: String, side: String) -> void:
       var results = match_data.rounds_data[round_idx].player_answers[username].results
       
       # Get appropriate container
       var container = result_container_r if side == "right" else result_container_l
       
       # Get result_component at round_idx
       if round_idx >= container.get_child_count():
           push_warning("Round index out of bounds: %d" % round_idx)
           return
       
       var result_component = container.get_child(round_idx)
       
       # Update each result button
       for i in range(results.size()):
           var was_correct = results[i].correct
           result_component.update_button_at_index(i, was_correct)
   ```

2. Verify calls in `_handle_round_completion()` from Task 14

**Validation**:
- After answering questions, verify colored buttons appear on right side
- After opponent answers, verify colored buttons appear on left side
- Verify grey placeholders remain until both answer

**Dependencies**: Task 14

---

### Task 16: Load existing match state on gameplay_screen open
**Objective**: Display previous round results when reopening gameplay screen

**Steps**:
1. Add method to `gameplay_screen.gd`:
   ```gdscript
   ## Load and display existing match state from database
   func _load_existing_match_state() -> void:
       if not is_multiplayer:
           return
       
       var my_username = UserDatabase.current_user.username
       
       # Iterate through rounds and display completed results
       for round_idx in range(match_data.rounds_data.size()):
           var round_data = match_data.rounds_data[round_idx]
           
           # Display my results if I've answered
           if round_data.player_answers[my_username].answered:
               _display_round_results(round_idx, my_username, "right")
           
           # Display opponent results if they've answered
           if round_data.player_answers[opponent_username].answered:
               _display_round_results(round_idx, opponent_username, "left")
   ```

2. Call in `_ready()` after `_update_play_button_state()`:
   ```gdscript
   func _ready() -> void:
       # ... existing initialization ...
       
       if is_multiplayer:
           _update_play_button_state()
           _load_existing_match_state()
   ```

**Validation**:
- Answer questions, close game
- Reopen and navigate to gameplay_screen
- Verify previous results still display correctly

**Dependencies**: Task 15

---

## Phase 5: Polish & Edge Cases

### Task 17: Add empty state message for friendly_battle_page
**Objective**: Show helpful text when no active matches exist

**Steps**:
1. Open `scenes/ui/lobby_pages/friendly_battle_page.tscn`
2. Add Label node as child of the page (not inside GridContainer)
3. Set properties:
   - `unique_name_in_owner = true` with name "NoMatchesLabel"
   - `text = "No active matches\nInvite friends to start playing!"`
   - `horizontal_alignment = Center`
   - `vertical_alignment = Center`
   - Anchor to center

4. In `friendly_battle_page.gd`, modify `_populate_active_matches()`:
   ```gdscript
   func _populate_active_matches() -> void:
       # Clear existing children
       for child in friend_list.get_children():
           child.queue_free()
       
       if not UserDatabase.is_signed_in():
           return
       
       var matches: Array = UserDatabase.get_active_matches_for_player(
           UserDatabase.current_user.username
       )
       
       # Show/hide empty state message
       var no_matches_label = get_node_or_null("%NoMatchesLabel")
       if no_matches_label:
           no_matches_label.visible = matches.is_empty()
       
       # Create avatar_component for each match
       for match in matches:
           # ... existing code ...
   ```

**Validation**:
- Navigate to friendly_battle_page with no matches
- Verify message appears
- Create match, verify message disappears

**Dependencies**: Task 8

---

### Task 18: Update friendly_battle_page on returning from gameplay
**Objective**: Refresh turn labels when match state changes

**Steps**:
1. In `friendly_battle_page.gd`, add visibility notification:
   ```gdscript
   func _notification(what: int) -> void:
       if what == NOTIFICATION_VISIBILITY_CHANGED:
           if visible and is_inside_tree():
               _populate_active_matches()
   ```

**Validation**:
- Play turn, return to friendly_battle_page
- Verify turn label updates to show opponent's turn

**Dependencies**: Task 8

---

### Task 19: Add error handling for invalid match_id
**Objective**: Gracefully handle navigation to non-existent matches

**Steps**:
1. Already implemented in Task 10's `initialize()` method
2. Add additional validation in `_on_avatar_clicked()` in `friendly_battle_page.gd`:
   ```gdscript
   func _on_avatar_clicked(match_id: String) -> void:
       # Validate match exists before navigating
       var match = UserDatabase.get_match(match_id)
       if match.is_empty():
           push_warning("Cannot navigate: match not found %s" % match_id)
           _populate_active_matches()  # Refresh list
           return
       
       var params = {"match_id": match_id}
       NavigationUtils.navigate_to_scene("gameplay_screen", params)
   ```

**Validation**:
- Manually corrupt match_id in database
- Attempt to click avatar
- Verify error logged, no crash

**Dependencies**: Task 8, Task 10

---

### Task 20: Prevent single-player navigation from setup_screen (optional cleanup)
**Objective**: Clarify that setup_screen is for multiplayer only (or keep for testing)

**Steps**:
1. Review `setup_screen.gd` Task 5 implementation
2. Decision: Keep single-player path for now (useful for testing)
3. Add comment documenting behavior:
   ```gdscript
   func _on_start_game_button_pressed() -> void:
       # ... existing code ...
       
       if pending_invite_player.is_empty():
           # Single-player mode - kept for testing purposes
           # TODO: Remove this path once multiplayer is stable
           var params: Dictionary = {
               "rounds": rounds_value,
               "questions": questions_value
           }
           TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)
       else:
           # Multiplayer invite mode
           # ... existing code ...
   ```

**Validation**:
- None required (documentation only)

**Dependencies**: Task 5

---

## Phase 6: Validation & Testing

### Task 21: Manual integration test - Full multiplayer flow
**Objective**: Verify complete user journey from invite to match completion

**Test Script**:
1. [ ] Player A (e.g., "linus") logs in
2. [ ] Player A opens friend's account_popup (e.g., "robin")
3. [ ] Player A clicks "Invite to Game"
4. [ ] Setup screen opens
5. [ ] Player A configures 2 rounds, 2 questions
6. [ ] Player A clicks "Start Game"
7. [ ] Verify returns to main_lobby_screen
8. [ ] Player B ("robin") logs in
9. [ ] Player B sees notification with invite
10. [ ] Player B accepts invite
11. [ ] Verify match created in database
12. [ ] Both players navigate to friendly_battle_page
13. [ ] Verify both see avatar with opponent's picture
14. [ ] Verify Player A sees "Your Turn", Player B sees "linus Turn"
15. [ ] Player A clicks avatar → gameplay_screen opens
16. [ ] Verify play button enabled for Player A
17. [ ] Player A clicks play, chooses category, answers 2 questions
18. [ ] Verify colored results appear on right side for Player A
19. [ ] Verify play button disabled after answering
20. [ ] Player A closes gameplay_screen
21. [ ] Verify friendly_battle_page now shows "robin Turn" for Player A
22. [ ] Player B clicks avatar → gameplay_screen opens
23. [ ] Verify play button enabled for Player B
24. [ ] Verify Player B sees same questions Player A answered
25. [ ] Player B answers 2 questions
26. [ ] Verify both players' results appear (colored)
27. [ ] Verify round advances to round 2
28. [ ] Verify turn switches to Player B (category chooser for round 2)
29. [ ] Player B chooses category, answers questions
30. [ ] Player A answers same questions
31. [ ] After last question, verify both return to main_lobby_screen
32. [ ] Verify match status changed to "completed" in database

**Dependencies**: All previous tasks

---

### Task 22: Validate edge cases
**Objective**: Test boundary conditions and error scenarios

**Test Cases**:
1. [ ] Create match with 1 round, 1 question
2. [ ] Create match with 10 rounds, 5 questions
3. [ ] Player has 3 simultaneous active matches
4. [ ] Opponent account deleted (mock by removing user) - should show error
5. [ ] Malformed match data - should log warning and skip
6. [ ] Navigate directly to gameplay_screen without match_id - should work (single-player)
7. [ ] Close app mid-game, reopen - should resume from correct state
8. [ ] Both players in different rounds simultaneously (should not happen, but verify safety)

**Dependencies**: Task 21

---

## Checklist Summary

Once all tasks complete, verify:
- [x] UserDatabase has `multiplayer_matches` array
- [ ] Matches can be created, retrieved, updated
- [ ] Invite flow navigates: account_popup → setup_screen → notification → lobby
- [ ] Notifications include rounds/questions
- [ ] Accepting invite creates match
- [ ] friendly_battle_page shows avatar_components
- [ ] Turn labels accurate ("Your Turn" vs "[Player] Turn")
- [ ] Clicking avatar navigates to gameplay_screen with match_id
- [ ] Play button enables/disables based on turn
- [ ] Category chooser alternates (inviter: odd, invitee: even)
- [ ] Questions saved and reused for opponent
- [ ] Answers hidden until both complete round
- [ ] Results reveal after round completion
- [ ] Turn switches correctly
- [ ] Match completes and returns to lobby
- [ ] Multiple simultaneous matches work
- [ ] State persists across app restarts

## Notes

- Tasks are designed for incremental delivery
- Each task includes validation steps
- Dependencies are explicit
- Manual testing required (no automated test framework yet)
- Firebase migration deferred until local gameplay proven
