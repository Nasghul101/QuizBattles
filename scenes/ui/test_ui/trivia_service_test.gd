extends Control
## Test scene for TriviaQuestionService integration
##
## Tests fetching questions from the service and displaying them in the quiz screen.
## Also tests caching, error handling, and category mapping.

@onready var quiz_screen: Control = %QuizScreen
@onready var status_label: Label = %StatusLabel
@onready var category_option: OptionButton = %CategoryOption
@onready var fetch_button: Button = %FetchButton
@onready var clear_cache_button: Button = %ClearCacheButton


func _ready() -> void:
    # Connect service signals
    TriviaQuestionService.questions_ready.connect(_on_questions_ready)
    TriviaQuestionService.connection_error.connect(_on_connection_error)
    TriviaQuestionService.api_failed.connect(_on_api_failed)
    
    # Populate category dropdown
    var categories = TriviaQuestionService.get_available_categories()
    for category in categories:
        category_option.add_item(category)
    
    # Connect UI buttons
    fetch_button.pressed.connect(_on_fetch_button_pressed)
    clear_cache_button.pressed.connect(_on_clear_cache_button_pressed)
    
    status_label.text = "Ready. Select a category and click Fetch Questions."


func _on_fetch_button_pressed() -> void:
    if category_option.selected == -1:
        status_label.text = "Please select a category first."
        return
    
    var category: String = category_option.get_item_text(category_option.selected)
    status_label.text = "Fetching questions for %s..." % category
    
    # Request 3 questions (standard round size)
    TriviaQuestionService.fetch_questions(category, 3)


func _on_clear_cache_button_pressed() -> void:
    TriviaQuestionService.clear_cache()
    status_label.text = "Cache cleared."


func _on_questions_ready(questions: Array) -> void:
    if questions.is_empty():
        status_label.text = "No questions returned."
        return
    
    status_label.text = "Received %d questions. Displaying first question..." % questions.size()
    
    # Display first question in quiz screen
    quiz_screen.load_question(questions[0])


func _on_connection_error() -> void:
    status_label.text = "ERROR: No internet connection. Please connect to the internet."


func _on_api_failed() -> void:
    status_label.text = "WARNING: API failed. Using fallback questions."
