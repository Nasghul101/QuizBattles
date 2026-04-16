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

# Match state variables
var match_id: String = ""
var match_data: Dictionary = {}
var opponent_username: String = ""

# State variables
var current_round: int = 0  # 0 = idle, 1+ = active round
var current_question_index: int = 0
var fetched_questions: Array = []
var current_round_results: Array = []
var selected_category: String = ""

# Node references
@onready var result_container: VBoxContainer = %ResultContainer
@onready var name_p1_label: Label = %NameP1
@onready var name_p2_label: Label = %NameP2
@onready var play_button: Button = %PlayButton
@onready var score_p1_label: Label = %ScoreP1
@onready var score_p2_label: Label = %ScoreP2
@onready var finish_game_popup: MarginContainer = $FinishGamePopup
@onready var winner_display: Label = %WinnerDisplay
@onready var finish_game_button: Button = %FinishGameButton

# Scene references
var result_component_scene: PackedScene = preload("res://scenes/ui/components/result_component.tscn")
var category_popup: Control
var category_popup_scene: PackedScene = preload("res://scenes/ui/components/category_popup_component.tscn")
var quiz_screen: Control
var quiz_screen_scene: PackedScene = preload("res://scenes/ui/quiz_screen.tscn")


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
    
    # Connect FinishGameButton
    finish_game_button.pressed.connect(_on_finish_game_button_pressed)
    
    # Remove existing result components and create new ones
    _initialize_result_components()
    
    # Populate player name labels
    name_p1_label.text = UserDatabase.current_user.username
    name_p2_label.text = opponent_username
    
    # Setup match state
    _update_play_button_state()
    _load_existing_match_state()
    _update_score_labels()
    
    # If match is finished, show popup immediately
    if match_data.status == "finished":
        _show_finish_popup()
    
    # Display current configuration for debugging
    if num_rounds > 0 and num_questions > 0:
        print("Game initialized: %d rounds, %d questions" % [num_rounds, num_questions])


## Initialize result components based on num_rounds
func _initialize_result_components() -> void:
    # Skip if num_rounds not set yet (will be called again after initialize())
    if num_rounds == 0:
        return
    
    # Clear result container
    for child in result_container.get_children():
        child.queue_free()
    
    # Create num_rounds components
    for i in range(num_rounds):
        var component = result_component_scene.instantiate()
        result_container.add_child(component)
        component.initialize_empty(num_questions)
        component.set_round(i + 1)

    # Wait one frame for layout to update
    await get_tree().process_frame


## Initializes the gameplay screen with game configuration
##
## Called by TransitionManager when transitioning from friendly_battle_page.
## Stores configuration for use by future game logic.
##
## @param params: Dictionary with "match_id": String
func initialize(params: Dictionary) -> void:
    match_id = params["match_id"]
    
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
    
    # Note: _initialize_result_components() will be called from _ready()
    # after @onready variables are initialized


## Handle PlayButton press - Start category selection
func _on_play_button_pressed() -> void:
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
        quiz_screen.set_round_number(current_round)
        quiz_screen.load_question(fetched_questions[0])


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
    
    # Store in match data
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
    quiz_screen.set_round_number(current_round)
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
        

## Handle completion of current round by current player
func _handle_round_completion() -> void:
    quiz_screen.visible = false
    
    # Store my answers in match data (deep copy to prevent reference issues)
    var current_round_idx = match_data.current_round - 1
    var my_username = UserDatabase.current_user.username
    
    match_data.rounds_data[current_round_idx].player_answers[my_username].answered = true
    match_data.rounds_data[current_round_idx].player_answers[my_username].results = current_round_results.duplicate(true)
    
    # Display results for this round (both players)
    _display_round_results(current_round_idx)
    
    # Check if opponent also answered
    var opponent_answered = match_data.rounds_data[current_round_idx].player_answers[opponent_username].answered
    
    if opponent_answered:
        # Both answered - advance round
        
        # Check if more rounds remain
        if match_data.current_round < num_rounds:
            # Advance to next round
            match_data.current_round += 1
            var next_round_idx = match_data.current_round - 1
            match_data.current_turn = match_data.rounds_data[next_round_idx].category_chooser
        
        else:
            # Match complete - update statistics before finishing
            UserDatabase.update_player_statistics(match_data)
            
            # Set status to finished and show popup
            match_data.status = "finished"
            UserDatabase.update_match(match_data)
            _update_score_labels()
            _show_finish_popup()
            return
    
    else:
        # Only I answered - switch turn to opponent
        match_data.current_turn = opponent_username
    
    # Save match state
    UserDatabase.update_match(match_data)
    
    # Update play button state
    _update_play_button_state()


## Handle API failure
func _on_api_failed() -> void:
    print("API failed, using fallback questions")
    # questions_ready will still be emitted with fallback questions


## Update play button enabled/disabled state based on turn
func _update_play_button_state() -> void:
    # Check if it's my turn
    var is_my_turn = (match_data.current_turn == UserDatabase.current_user.username)
    
    # Check if I've already answered current round
    var current_round_idx = match_data.current_round - 1
    var my_answered = match_data.rounds_data[current_round_idx].player_answers.get(
        UserDatabase.current_user.username, {}
    ).get("answered", false)
    
    # Enable only if my turn AND I haven't answered yet
    play_button.disabled = not (is_my_turn and not my_answered)


## Display round results in result_component for both players
##
## @param round_idx: 0-based round index
func _display_round_results(round_idx: int) -> void:
    var my_username = UserDatabase.current_user.username
    var category_name = match_data.rounds_data[round_idx].category
    var p1_results = match_data.rounds_data[round_idx].player_answers[my_username].results
    var p2_results = match_data.rounds_data[round_idx].player_answers[opponent_username].results
    
    if round_idx >= result_container.get_child_count():
        push_warning("Round index out of bounds: %d" % round_idx)
        return
    
    var result_component = result_container.get_child(round_idx)
    result_component.load_result_data(category_name, p1_results, p2_results)
    
    # Reveal P2 buttons only when both players have answered; otherwise keep them hidden
    var opponent_answered = match_data.rounds_data[round_idx].player_answers[opponent_username].answered
    if opponent_answered:
        result_component.show_results()
    else:
        result_component.hide_results()
    
    _update_score_labels()


## Load and display existing match state from database
func _load_existing_match_state() -> void:
    var my_username = UserDatabase.current_user.username
    
    # Iterate through rounds and display completed results
    for round_idx in range(match_data.rounds_data.size()):
        var round_data = match_data.rounds_data[round_idx]
        
        var my_answered = round_data.player_answers[my_username].answered
        var opponent_answered = round_data.player_answers[opponent_username].answered
        
        if my_answered:
            # Load both players' results (p2 may be empty if opponent hasn't answered)
            _display_round_results(round_idx)
        elif opponent_answered:
            # Opponent answered but I haven't — show P2 buttons in hidden state only
            result_container.get_child(round_idx).hide_results()
            

func _on_back_button_pressed() -> void:
    Utils.navigate_to_scene("main_lobby")

## Calculate score from result components
##
## @param side: "p1" or "p2"
## @return int: Total number of correct answers
func _calculate_score_from_results(side: String) -> int:
    var score = 0
    for result_component in result_container.get_children():
        if result_component.is_empty:
            continue
        
        var results = result_component.stored_results_p1 if side == "p1" else result_component.stored_results_p2
        for result_data in results:
            if result_data.was_correct:
                score += 1
    
    return score


## Update score labels based on current result components
func _update_score_labels() -> void:
    var p1_score = _calculate_score_from_results("p1")
    var p2_score = _calculate_score_from_results("p2")
    
    score_p1_label.text = str(p1_score)
    score_p2_label.text = str(p2_score)


## Show finish game popup with winner determination
func _show_finish_popup() -> void:
    var p1_score = _calculate_score_from_results("p1")
    var p2_score = _calculate_score_from_results("p2")
    
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


## Handle finish game button press
func _on_finish_game_button_pressed() -> void:
    var my_username = UserDatabase.current_user.username
    
    # Initialize dismissed_by array if it doesn't exist (backward compatibility)
    if not match_data.has("dismissed_by"):
        match_data.dismissed_by = []
    
    # Add current user to dismissed_by list
    if my_username not in match_data.dismissed_by:
        match_data.dismissed_by.append(my_username)
    
    # Check if both players have dismissed
    var all_dismissed = true
    for player in match_data.players:
        if player not in match_data.dismissed_by:
            all_dismissed = false
            break
    
    if all_dismissed:
        # Both players dismissed - delete the match
        UserDatabase.delete_match(match_id)
    else:
        # Only this player dismissed - update match
        UserDatabase.update_match(match_data)
    
    TransitionManager.change_scene("res://scenes/ui/main_lobby_screen.tscn")
