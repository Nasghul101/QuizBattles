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
## Called by TransitionManager when transitioning from setup screen.
## Stores configuration for use by future game logic.
##
## @param rounds: Number of rounds to play
## @param questions: Number of questions per round
func initialize(rounds: int, questions: int) -> void:
    num_rounds = rounds
    num_questions = questions
    
    # Note: _initialize_result_components() will be called from _ready()
    # after @onready variables are initialized


## Handle PlayButton press - Start category selection
func _on_play_button_pressed() -> void:
    # Get 3 random categories
    var all_categories = TriviaQuestionService.get_available_categories()
    var random_categories: Array = []
    
    # Pick 3 random unique categories
    var available = all_categories.duplicate()
    available.shuffle()
    for i in range(min(3, available.size())):
        random_categories.append(available[i])
    
    # Show category popup
    category_popup.show_categories(random_categories)
    
    # Hide PlayButton during selection
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
    
    # Store questions for this round
    fetched_questions = questions
    
    # Log warning if we got fewer questions than requested
    if questions.size() < num_questions:
        push_warning("Received %d questions but requested %d. Using available questions." % [questions.size(), num_questions])
    
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
    # Get current question data
    var current_question_data = fetched_questions[current_question_index]
    
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
        _complete_round()


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


## Handle API failure
func _on_api_failed() -> void:
    print("API failed, using fallback questions")
    # questions_ready will still be emitted with fallback questions
