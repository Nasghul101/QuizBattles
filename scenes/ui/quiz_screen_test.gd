extends Node2D
## Test scene for quiz screen component
##
## This is a simple test harness to verify the quiz screen works correctly.
## Run this scene to test the quiz screen functionality.

@onready var quiz_screen: Control = $QuizScreen


func _ready() -> void:
    # Connect to the answer_correct signal
    quiz_screen.answer_correct.connect(_on_answer_correct)
    
    # Load a sample question
    var sample_question: Dictionary = {
        "question": "What is the capital of France?",
        "correct_answer": "Paris",
        "incorrect_answers": ["London", "Berlin", "Madrid"]
    }
    
    quiz_screen.load_question(sample_question)


func _on_answer_correct() -> void:
    """Handle correct answer signal"""
    print("✓ Correct answer! Point scored.")
    
    # Wait 2 seconds then load another question
    await get_tree().create_timer(2.0).timeout
    _load_next_question()


func _load_next_question() -> void:
    """Load another sample question for testing"""
    var questions: Array = [
        {
            "question": "What is 2 + 2?",
            "correct_answer": "4",
            "incorrect_answers": ["3", "5", "22"]
        },
        {
            "question": "Which planet is known as the Red Planet?",
            "correct_answer": "Mars",
            "incorrect_answers": ["Venus", "Jupiter", "Saturn"]
        },
        {
            "question": "What is the largest ocean on Earth?",
            "correct_answer": "Pacific Ocean",
            "incorrect_answers": ["Atlantic Ocean", "Indian Ocean", "Arctic Ocean"]
        }
    ]
    
    var random_question: Dictionary = questions[randi() % questions.size()]
    quiz_screen.load_question(random_question)
