extends PanelContainer
## Result component for displaying round outcomes
##
## A reusable UI component that displays a category summary with answer outcomes
## for multiple questions. Shows a category icon and answer indicator buttons
## that display correct/incorrect icons and can be clicked to review questions.
##
## Usage:
##   1. Instance the result_component.tscn scene
##   2. Connect to the question_review_requested signal
##   3. Call load_result_data(texture, results) with category data
##   4. Component will display icons and emit signals on button clicks
##
## Expected results data format:
##   [
##       {
##           "question_data": {
##               "question": "What is the capital of France?",
##               "correct_answer": "Paris",
##               "incorrect_answers": ["London", "Berlin", "Madrid"]
##           },
##           "was_correct": true,
##           "player_answer": "Paris"
##       },
##       ... (one entry per question)
##   ]

# Signal emitted when a player clicks an answer button to review a question
signal question_review_requested(question_index: int, question_data: Dictionary)

# Preload ResultButtonComponent scene
const ResultButtonComponent = preload("res://scenes/ui/components/result_button_component.tscn")

# Preload AnswerReviewScreen scene
const AnswerReviewScreen = preload("res://scenes/ui/components/answer_review_screen.tscn")

# Node references
@onready var category_symbol: TextureRect = %CategorySymbol
@onready var answer_button_container: HBoxContainer = %AnswerButtonContainer

# Internal state
var answer_buttons: Array = []
var stored_results: Array = []
var is_empty: bool = true
var answer_review_screen: Control = null


func _ready() -> void:
    # Instantiate and configure answer review screen
    answer_review_screen = AnswerReviewScreen.instantiate()
    # Add to viewport root instead of this node to avoid position inheritance
    get_tree().root.add_child(answer_review_screen)
    answer_review_screen.visible = false
    
    # Set high z-index to ensure it appears above other elements
    answer_review_screen.z_index = 100


func _exit_tree() -> void:
    # Clean up answer review screen when this component is removed
    if answer_review_screen and is_instance_valid(answer_review_screen):
        answer_review_screen.queue_free()

## Initialize component in empty/disabled state
##
## Creates the specified number of answer buttons in a grey, disabled state.
## Used to show result slots before rounds are completed.
##
## Args:
##   num_answer_buttons: Number of answer buttons to create
func initialize_empty(num_answer_buttons: int) -> void:
    # Clear any existing buttons
    for child in answer_button_container.get_children():
        child.queue_free()
    
    answer_buttons.clear()
    
    # Create new ResultButtonComponent instances in disabled state
    for i in range(num_answer_buttons):
        var button_instance = ResultButtonComponent.instantiate()
        answer_button_container.add_child(button_instance)
        answer_buttons.append(button_instance)
        
        # Set to empty state
        button_instance.set_empty_state()
        
        # Connect signal
        button_instance.result_clicked.connect(_on_result_button_pressed)
    
    # Set category symbol to greyscale placeholder
    if category_symbol:
        category_symbol.modulate = Color(0.5, 0.5, 0.5)
        category_symbol.texture = null
    
    # Mark as empty
    is_empty = true
    stored_results.clear()


## Load and display result data for a category round
##
## Args:
##   category_texture: Texture2D to display as the category symbol
##   results: Array of dictionaries, each containing "question_data" (Dictionary),
##            "was_correct" (bool), and "player_answer" (String). Must not exceed the number of buttons.
func load_result_data(category_texture: Texture2D, results: Array) -> void:
    # Validate input data
    if results.is_empty():
        push_error("Invalid results data. Array cannot be empty.")
        return
    
    # Allow loading fewer results than buttons (in case API returned fewer questions)
    if results.size() > answer_buttons.size():
        push_error("Invalid results data. Too many results: expected max %d entries, got %d." % [answer_buttons.size(), results.size()])
        return
    
    if results.size() < answer_buttons.size():
        push_warning("Loading %d results into %d button slots. Remaining buttons will stay disabled." % [results.size(), answer_buttons.size()])
    
    # Validate each result entry has required fields
    for i in range(results.size()):
        var result = results[i]
        if not result.has("question_data") or not result.has("was_correct") or not result.has("player_answer"):
            push_error("Invalid result entry at index %d. Missing required fields." % i)
            return
    
    # Store data internally
    stored_results = results.duplicate(true)  # Deep copy to prevent external modifications
    
    # Set category texture
    category_symbol.texture = category_texture
    category_symbol.modulate = Color(1.0, 1.0, 1.0)  # Reset to full color
    
    # Mark as not empty
    is_empty = false
    
    # Update button states based on correctness
    _update_button_states()


## Update button states to show correct/incorrect states
func _update_button_states() -> void:
    # Only update buttons for which we have results
    for i in range(stored_results.size()):
        var button_component = answer_buttons[i]
        var result_data = stored_results[i]
        var was_correct: bool = result_data["was_correct"]
        
        # Load question data into button
        button_component.load_question_data(i, result_data)
        
        # Set state based on correctness
        if was_correct:
            button_component.set_correct_state()
        else:
            button_component.set_incorrect_state()
    
    # Leave remaining buttons in empty state if we have fewer results than buttons
    for i in range(stored_results.size(), answer_buttons.size()):
        answer_buttons[i].set_empty_state()


## Handle result button press from ResultButtonComponent
##
## Args:
##   question_index: Index of the pressed button
##   result_data: Complete result data from the button (includes question_data, was_correct, player_answer)
func _on_result_button_pressed(question_index: int, result_data: Dictionary) -> void:
    # Show the answer review screen with this question's data
    _show_answer_review(result_data)


## Show the answer review screen with question data
##
## Args:
##   result_data: Complete result data with nested question_data and player_answer
func _show_answer_review(result_data: Dictionary) -> void:
    # Hide the review screen first if it's already visible (to support multiple clicks)
    if answer_review_screen and answer_review_screen.visible:
        answer_review_screen.hide_review()
    
    # Extract and merge the data for the review screen
    # result_data has structure: {"question_data": {...}, "was_correct": bool, "player_answer": string}
    # We need to merge question_data with player_answer for the review screen
    var review_data: Dictionary = result_data["question_data"].duplicate()
    review_data["player_answer"] = result_data["player_answer"]
    
    # Load the merged question data into the review screen
    if answer_review_screen:
        answer_review_screen.load_review_data(review_data)
        answer_review_screen.show_review()
