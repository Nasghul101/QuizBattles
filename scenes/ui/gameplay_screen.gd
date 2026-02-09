extends Control
## Gameplay screen for quiz game
##
## Central orchestrator for round-based gameplay flow.
## Manages category selection, question fetching, answering, and result tracking.
##
## Signal Flow:
##   PlayButton → CategoryPopup → TriviaService → QuizScreen → Results → PlayButton
##
## State Flow:
##   IDLE → CATEGORY_SELECTION → LOADING_QUESTIONS → ANSWERING_QUESTIONS → ROUND_COMPLETE → IDLE

## Number of rounds to play
var num_rounds: int = 0

## Number of questions per round
var num_questions: int = 0

# Multiplayer state variables
var match_id: String = ""
var match_data: Dictionary = {}
var is_multiplayer: bool = false
var opponent_username: String = ""

# State variables
var current_round: int = 0  # 0 = idle, 1+ = active round
var current_question_index: int = 0
var fetched_questions: Array = []
var current_round_results: Array = []
var selected_category: String = ""

# Node references
@onready var result_container_l: VBoxContainer = %ResultContainerL
@onready var result_container_r: VBoxContainer = %ResultContainerR
@onready var play_button: Button = %PlayButton

# Scene references
var result_component_scene: PackedScene = preload("res://scenes/ui/components/result_component.tscn")
var category_popup: Control
var category_popup_scene: PackedScene = preload("res://scenes/ui/components/category_popup_component.tscn")
var quiz_screen: Control
var quiz_screen_scene: PackedScene = preload("res://scenes/ui/quiz_screen.tscn")
var icon_placeholder: Texture2D = preload("res://icon.svg")


func _ready() -> void:
    
    # Instantiate category popup
    category_popup = category_popup_scene.instantiate()
    add_child(category_popup)
    category_popup.visible = false
    category_popup.category_selected.connect(_on_category_selected)
    # Force layout update for proper sizing
    await get_tree().process_frame
    
    # Instantiate quiz screen
    quiz_screen = quiz_screen_scene.instantiate()
    add_child(quiz_screen)
    quiz_screen.visible = false
    quiz_screen.question_answered.connect(_on_question_answered)
    quiz_screen.next_question_requested.connect(_on_next_question_requested)
    
    # Connect TriviaQuestionService signals
    TriviaQuestionService.questions_ready.connect(_on_questions_ready)
    TriviaQuestionService.api_failed.connect(_on_api_failed)
    
    # Connect PlayButton
    play_button.pressed.connect(_on_play_button_pressed)
    
    # Remove existing result components and create new ones
    _initialize_result_components()
    
    # Setup multiplayer-specific state
    if is_multiplayer:
        _update_play_button_state()
        _load_existing_match_state()
    
    # Display current configuration for debugging
    if num_rounds > 0 and num_questions > 0:
        print("Game initialized: %d rounds, %d questions" % [num_rounds, num_questions])


## Initialize result components based on num_rounds
func _initialize_result_components() -> void:
    # Skip if num_rounds not set yet (will be called again after initialize())
    if num_rounds == 0:
        return
    
    # Clear left container
    for child in result_container_l.get_children():
        child.queue_free()
    
    # Clear right container
    for child in result_container_r.get_children():
        child.queue_free()
    
    # Create num_rounds components for each side
    for i in range(num_rounds):
        # Left container
        var component_l = result_component_scene.instantiate()
        result_container_l.add_child(component_l)
        component_l.initialize_empty(num_questions)
        
        # Right container
        var component_r = result_component_scene.instantiate()
        result_container_r.add_child(component_r)
        component_r.initialize_empty(num_questions)
    
    # Wait one frame for layout to update
    await get_tree().process_frame


## Initializes the gameplay screen with game configuration
##
## Called by TransitionManager when transitioning from setup screen or friendly_battle_page.
## Stores configuration for use by future game logic.
##
## @param params: Dictionary with either:
##   - "match_id": String for multiplayer mode
##   - "rounds": int and "questions": int for single-player mode
func initialize(params: Dictionary) -> void:
    if params.has("match_id"):
        # Multiplayer mode
        match_id = params["match_id"]
        is_multiplayer = true
        
        # Load match data
        match_data = UserDatabase.get_match(match_id)
        if match_data.is_empty():
            push_error("Match not found: %s" % match_id)
            TransitionManager.change_scene("res://scenes/ui/main_lobby_screen.tscn")
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
    
    # Note: _initialize_result_components() will be called from _ready()
    # after @onready variables are initialized


## Handle PlayButton press - Start category selection
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
            fetched_questions = round_data.questions.duplicate(true)
            
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


## Handle category selection
func _on_category_selected(category_name: String) -> void:
    selected_category = category_name
    
    # Show loading state
    category_popup.show_loading()
    
    # Fetch questions from TriviaQuestionService
    print("[GameplayScreen] Requesting %d questions for category: %s" % [num_questions, category_name])
    TriviaQuestionService.fetch_questions(category_name, num_questions)


## Handle questions ready from TriviaQuestionService
func _on_questions_ready(questions: Array) -> void:
    print("[GameplayScreen] Received %d questions from TriviaQuestionService" % questions.size())
    
    # Validate we received questions
    if questions.is_empty():
        push_error("No questions received from TriviaQuestionService")
        play_button.visible = true
        return
    
    # Store questions for this round (deep copy to prevent reference sharing)
    fetched_questions = questions.duplicate(true)
    
    # Log warning if we got fewer questions than requested
    if questions.size() < num_questions:
        push_warning("Received %d questions but requested %d. Using available questions." % [questions.size(), num_questions])
    
    # If multiplayer, store in match data
    if is_multiplayer:
        var current_round_idx = match_data.current_round - 1
        match_data.rounds_data[current_round_idx].category = selected_category
        match_data.rounds_data[current_round_idx].questions = questions.duplicate(true)
        UserDatabase.update_match(match_data)
    
    # Hide category popup
    category_popup.hide_popup()
    
    # Initialize round state
    current_question_index = 0
    if current_round == 0:
        current_round = 1
    current_round_results.clear()
    
    # Show quiz screen with first question
    quiz_screen.visible = true
    quiz_screen.load_question(fetched_questions[0])


## Handle question answered
func _on_question_answered(was_correct: bool, player_answer: String) -> void:
    # Get current question data (deep copy to prevent reference sharing)
    var current_question_data = fetched_questions[current_question_index].duplicate(true)
    
    # Store result with player's selected answer
    current_round_results.append({
        "question_data": current_question_data,
        "was_correct": was_correct,
        "player_answer": player_answer
    })


## Handle next question requested
func _on_next_question_requested() -> void:
    # Move to next question
    current_question_index += 1
    
    # Check if more questions remain
    if current_question_index < fetched_questions.size():
        # Load next question
        quiz_screen.load_question(fetched_questions[current_question_index])
    else:
        # All questions answered, complete the round
        _handle_round_completion()


## Complete the current round and update results
func _complete_round() -> void:
    # Hide quiz screen
    quiz_screen.visible = false
    
    # Get result components for current round (0-indexed)
    var result_l = result_container_l.get_child(current_round - 1)
    var result_r = result_container_r.get_child(current_round - 1)
    
    # Load results into both components
    result_l.load_result_data(icon_placeholder, current_round_results)
    result_r.load_result_data(icon_placeholder, current_round_results)
    
    # Check if all rounds are complete
    if current_round >= num_rounds:
        # Game over - hide PlayButton
        play_button.visible = false
        print("All rounds complete! Game over.")
    else:
        # Increment round counter for next round
        current_round += 1
        # Show PlayButton for next round
        play_button.visible = true


## Handle completion of current round by current player
func _handle_round_completion() -> void:
    quiz_screen.visible = false
    
    if is_multiplayer:
        # Store my answers in match data (deep copy to prevent reference issues)
        var current_round_idx = match_data.current_round - 1
        var my_username = UserDatabase.current_user.username
        
        match_data.rounds_data[current_round_idx].player_answers[my_username].answered = true
        match_data.rounds_data[current_round_idx].player_answers[my_username].results = current_round_results.duplicate(true)
        
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
                # Match complete - delete from database
                UserDatabase.delete_match(match_data.match_id)
                
                # Return to lobby
                TransitionManager.change_scene("res://scenes/ui/main_lobby_screen.tscn")
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
        _complete_round()


## Handle API failure
func _on_api_failed() -> void:
    print("API failed, using fallback questions")
    # questions_ready will still be emitted with fallback questions


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
    
    # Load results using the component's proper method
    result_component.load_result_data(icon_placeholder, results)


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
        
        # Handle opponent results based on round completion status
        var opponent_answered = round_data.player_answers[opponent_username].answered
        var my_answered = round_data.player_answers[my_username].answered
        
        if opponent_answered:
            # Display opponent results
            _display_round_results(round_idx, opponent_username, "left")
            
            # If opponent answered but I haven't, hide their results
            if not my_answered:
                var opponent_container = result_container_l
                var opponent_result_component = opponent_container.get_child(round_idx)
                opponent_result_component.hide_results()


func _on_back_button_pressed() -> void:
    NavigationUtils.navigate_to_scene("main_lobby")
