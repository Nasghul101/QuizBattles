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

# Node references
@onready var category_symbol: TextureRect = %CategorySymbol
@onready var answer_button_container: HBoxContainer = %AnswerButtonContainer

# Internal state
var answer_buttons: Array[Button] = []
var stored_results: Array = []
var icon_right: Texture2D
var icon_wrong: Texture2D


func _ready() -> void:
    # Load icon assets
    icon_right = load("res://assets/icon_right.png")
    icon_wrong = load("res://assets/icon_wrong.png")
    
    # Populate button array from container children
    for child in answer_button_container.get_children():
        if child is Button:
            answer_buttons.append(child)
    
    # Connect button signals to handler
    for i in range(answer_buttons.size()):
        answer_buttons[i].pressed.connect(_on_answer_button_pressed.bind(i))


## Load and display result data for a category round
##
## Args:
##   category_texture: Texture2D to display as the category symbol
##   results: Array of dictionaries, each containing "question_data" (Dictionary),
##            "was_correct" (bool), and "player_answer" (String). Must match the number of buttons.
func load_result_data(category_texture: Texture2D, results: Array) -> void:
    # Validate input data
    if results.is_empty():
        push_error("Invalid results data. Array cannot be empty.")
        return
    
    if results.size() != answer_buttons.size():
        push_error("Invalid results data. Expected %d entries to match button count, got %d." % [answer_buttons.size(), results.size()])
        return
    
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
    
    # Update button icons based on correctness
    _update_button_icons()


## Update button icons to show correct/incorrect states
func _update_button_icons() -> void:
    for i in range(answer_buttons.size()):
        var button = answer_buttons[i]
        var was_correct: bool = stored_results[i]["was_correct"]
        
        # Set icon based on correctness
        if was_correct:
            button.icon = icon_right
        else:
            button.icon = icon_wrong


## Handle answer button press
##
## Args:
##   button_index: Index of the pressed button
func _on_answer_button_pressed(button_index: int) -> void:
    # Get the stored data for this question
    var result_data = stored_results[button_index]
    
    # Create complete data dictionary for the signal
    var complete_data = {
        "question_data": result_data["question_data"],
        "was_correct": result_data["was_correct"],
        "player_answer": result_data["player_answer"]
    }
    
    # Emit signal with question index and complete data
    question_review_requested.emit(button_index, complete_data)
