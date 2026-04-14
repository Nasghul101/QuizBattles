extends Control
## Answer review screen component
##
## A modal overlay component that displays a completed question with all answer options
## in their revealed states (correct in green, incorrect in red) and highlights the
## player's selected answer with a white outline. Used for post-round question review.
##
## Usage:
##   1. Instance as a child of the result component
##   2. Call load_review_data(question_data) with complete question data
##   3. Call show_review() to display the modal
##   4. Back button automatically hides the overlay
##
## Expected question_data format:
##   {
##       "question": "What is the capital of France?",
##       "correct_answer": "Paris",
##       "incorrect_answers": ["London", "Berlin", "Madrid"],
##       "player_answer": "Paris"
##   }

# Node references
@onready var question_label: Label = %QuestionLabel
@onready var answers_grid: GridContainer = %AnswersGrid

# Answer button references
var answer_buttons: Array = []


func _ready() -> void:
    # Get all answer button children from the grid
    for child in answers_grid.get_children():
        answer_buttons.append(child)
    
    
    # Start hidden
    visible = false
    
    # Configure modal behavior
    mouse_filter = Control.MOUSE_FILTER_STOP


## Load question data into the review screen
##
## Args:
##   question_data: Dictionary containing question, correct_answer, incorrect_answers, and player_answer
func load_review_data(question_data: Dictionary) -> void:
    # Validate input
    if not question_data.has("question") or not question_data.has("correct_answer") or \
       not question_data.has("incorrect_answers") or not question_data.has("player_answer"):
        push_error("Invalid question data format. Missing required keys.")
        return
    
    # Set question text
    question_label.text = question_data["question"]
    
    # Get correct answer and player's answer
    var correct_answer: String = question_data["correct_answer"]
    var player_answer: String = question_data["player_answer"]
    
    # Create shuffled answer list (same as quiz_screen)
    var all_answers: Array = [correct_answer]
    all_answers.append_array(question_data["incorrect_answers"])
    all_answers.shuffle()
    
    # Populate answer buttons with visual states
    for i in range(answer_buttons.size()):
        var button = answer_buttons[i]
        var answer_text: String = all_answers[i]
        
        # Populate via component API
        button.set_answer(answer_text, i)
        
        # Disable interaction
        button.disabled = true
        
        # Disable pulsating animation for static review display
        button.set_pulsating_enabled(false)
        
        # Set color based on correctness
        if answer_text == correct_answer:
            button.reveal_correct()
        else:
            button.reveal_wrong()
        
        # Add white shader outline if this was the player's choice
        if answer_text == player_answer:
            button.set_shader_outline_color(Color.WHITE)


## Show the review screen as a modal overlay
func show_review() -> void:
    visible = true


## Hide the review screen
func hide_review() -> void:
    visible = false


## Handle back button press
func _on_back_button_pressed() -> void:
    hide_review()
