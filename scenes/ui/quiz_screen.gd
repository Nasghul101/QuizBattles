extends Control
## Quiz screen component for gameplay
##
## Displays a trivia question with 4 possible answers arranged in a 2x2 grid.
## Handles answer randomization, validates user selection, reveals correct/wrong states,
## and signals when the player answers correctly for scoring purposes.
##
## Usage:
##   1. Instance the quiz_screen.tscn scene
##   2. Connect to the answer_correct signal
##   3. Call load_question(data) with question data in Open Trivia DB format
##   4. Screen will handle shuffling, validation, and visual feedback
##
## Expected data format:
##   {
##       "question": "What is the capital of France?",
##       "correct_answer": "Paris",
##       "incorrect_answers": ["London", "Berlin", "Madrid"]
##   }

# Signal emitted when the player selects the correct answer
signal answer_correct

# Node references
@onready var question_label: Label = $QuestionPanel/QuestionLabel
@onready var answers_grid: GridContainer = $AnswersGrid
@onready var answer_buttons: Array[Button] = [
    $AnswersGrid/AnswerButton1,
    $AnswersGrid/AnswerButton2,
    $AnswersGrid/AnswerButton3,
    $AnswersGrid/AnswerButton4
]

# Internal state
var correct_answer_text: String = ""
var has_answered: bool = false


func _ready() -> void:
    # Connect all answer button signals to handler
    for button in answer_buttons:
        button.answer_selected.connect(_on_answer_selected)


func load_question(data: Dictionary) -> void:
    """
    Load and display a quiz question with answers
    
    Args:
        data: Dictionary with keys "question" (String), "correct_answer" (String),
              and "incorrect_answers" (Array of 3 Strings)
    """
    # Validate input data
    if not data.has("question") or not data.has("correct_answer") or not data.has("incorrect_answers"):
        push_error("Invalid question data format. Missing required keys.")
        return
    
    if not data["incorrect_answers"] is Array or data["incorrect_answers"].size() != 3:
        push_error("Invalid question data format. incorrect_answers must be an Array of 3 strings.")
        return
    
    # Reset state
    has_answered = false
    
    # Display question text
    question_label.text = data["question"]
    
    # Store correct answer for validation
    correct_answer_text = data["correct_answer"]
    
    # Combine all answers into one array
    var all_answers: Array = [data["correct_answer"]]
    all_answers.append_array(data["incorrect_answers"])
    
    # Shuffle answers randomly
    all_answers.shuffle()
    
    # Assign shuffled answers to buttons
    for i in range(answer_buttons.size()):
        answer_buttons[i].set_answer(all_answers[i], i)


func _on_answer_selected(answer_index: int) -> void:
    """
    Handle answer button selection
    
    Args:
        answer_index: Index of the selected answer button (0-3)
    """
    # Prevent multiple answers
    if has_answered:
        return
    
    has_answered = true
    
    # Get the selected button and its answer text
    var selected_button: Button = answer_buttons[answer_index]
    var selected_answer_text: String = selected_button.text
    
    # Validate if answer is correct
    var is_correct: bool = (selected_answer_text == correct_answer_text)
    
    # Reveal all button states
    _reveal_all_buttons()
    
    # Emit signal only if answer was correct
    if is_correct:
        answer_correct.emit()


func _reveal_all_buttons() -> void:
    """
    Reveal the correct/wrong state of all answer buttons
    """
    for button in answer_buttons:
        # Check if this button has the correct answer
        if button.text == correct_answer_text:
            button.reveal_correct()
        else:
            button.reveal_wrong()
