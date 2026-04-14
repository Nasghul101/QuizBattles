extends PanelContainer
## Result component for displaying dual-player round outcomes
##
## A reusable UI component that displays a category name and answer outcome buttons
## for both players side-by-side. Each player's results are shown in their own
## HBoxContainer. Buttons can be clicked to review individual questions.
##
## Usage:
##   1. Instance the result_component.tscn scene
##   2. Call initialize_empty(num_answer_buttons) to create button slots
##   3. Call set_round(round_number) to display the round label
##   4. Call load_result_data(category_name, p1_results, p2_results) with result data
##   5. Optionally call hide_results() to hide P2 (opponent) buttons
##
## Expected results data format (for both p1_results and p2_results):
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
@onready var result_button_container_p1: HBoxContainer = %ResultButtonContainerP1
@onready var result_button_container_p2: HBoxContainer = %ResultButtonContainerP2
@onready var round_label: Label = %RoundLabel
@onready var category_label: Label = %CategoryLabel


# Internal state
var answer_buttons_p1: Array = []
var answer_buttons_p2: Array = []
var stored_results_p1: Array = []
var stored_results_p2: Array = []
var is_empty: bool = true
var answer_review_screen: Control = null


func _ready() -> void:
    # Instantiate and configure answer review screen
    answer_review_screen = AnswerReviewScreen.instantiate()
    answer_review_screen.visible = false

    # Set high z-index to ensure it appears above other elements
    answer_review_screen.z_index = 100

    # Add to viewport root instead of this node to avoid position inheritance.
    # Deferred to avoid "parent busy setting up children" error during _ready().
    get_tree().root.add_child.call_deferred(answer_review_screen)


func _exit_tree() -> void:
    # Clean up answer review screen when this component is removed
    if answer_review_screen and is_instance_valid(answer_review_screen):
        answer_review_screen.queue_free()

## Initialize component in empty/disabled state
##
## Creates the specified number of answer buttons in both P1 and P2 containers,
## each in a grey, disabled state. Used to show result slots before rounds are completed.
##
## Args:
##   num_answer_buttons: Number of answer buttons to create per player container
func initialize_empty(num_answer_buttons: int) -> void:
    # Clear any existing buttons from both containers
    for child in result_button_container_p1.get_children():
        child.queue_free()
    for child in result_button_container_p2.get_children():
        child.queue_free()

    answer_buttons_p1.clear()
    answer_buttons_p2.clear()

    # Create new ResultButtonComponent instances in both containers
    for i in range(num_answer_buttons):
        var btn_p1 = ResultButtonComponent.instantiate()
        result_button_container_p1.add_child(btn_p1)
        answer_buttons_p1.append(btn_p1)
        btn_p1.set_empty_state()
        btn_p1.result_clicked.connect(_on_result_button_pressed)

        var btn_p2 = ResultButtonComponent.instantiate()
        result_button_container_p2.add_child(btn_p2)
        answer_buttons_p2.append(btn_p2)
        btn_p2.set_empty_state()
        btn_p2.result_clicked.connect(_on_result_button_pressed)

    # Mark as empty
    is_empty = true
    stored_results_p1.clear()
    stored_results_p2.clear()


## Set the round label text
##
## Args:
##   round_number: The 1-based round number to display
func set_round(round_number: int) -> void:
    round_label.text = "Round %d" % round_number


## Load and display result data for both players for a category round
##
## Args:
##   category_name: Text to display in CategoryLabel
##   p1_results: Array of result dictionaries for player 1. Each entry must contain
##               "question_data" (Dictionary), "was_correct" (bool), "player_answer" (String).
##   p2_results: Array of result dictionaries for player 2. Must match p1_results in size.
func load_result_data(category_name: String, p1_results: Array, p2_results: Array) -> void:
    if p1_results.is_empty():
        push_error("Invalid results data. p1_results cannot be empty.")
        return

    # p2_results may be empty (opponent not yet answered); only validate size when non-empty
    if not p2_results.is_empty() and p1_results.size() != p2_results.size():
        push_error("Invalid results data. p1_results and p2_results must have equal size (got %d and %d)." % [p1_results.size(), p2_results.size()])
        return

    if p1_results.size() > answer_buttons_p1.size():
        push_error("Invalid results data. Too many results: expected max %d entries, got %d." % [answer_buttons_p1.size(), p1_results.size()])
        return

    if p1_results.size() < answer_buttons_p1.size():
        push_warning("Loading %d results into %d button slots. Remaining buttons will stay disabled." % [p1_results.size(), answer_buttons_p1.size()])

    # Validate each entry has required fields
    for i in range(p1_results.size()):
        var entry_p1 = p1_results[i]
        if not entry_p1.has("question_data") or not entry_p1.has("was_correct") or not entry_p1.has("player_answer"):
            push_error("Invalid result entry at index %d in p1_results. Missing required fields." % i)
            return
        if not p2_results.is_empty():
            var entry_p2 = p2_results[i]
            if not entry_p2.has("question_data") or not entry_p2.has("was_correct") or not entry_p2.has("player_answer"):
                push_error("Invalid result entry at index %d in p2_results. Missing required fields." % i)
                return

    # Store data internally
    stored_results_p1 = p1_results.duplicate(true)
    stored_results_p2 = p2_results.duplicate(true)

    # Set category label text
    category_label.text = category_name

    # Mark as not empty
    is_empty = false

    # Update button states based on correctness
    _update_button_states()


## Update button states to show correct/incorrect states for both players
func _update_button_states() -> void:
    # Update P1 buttons
    for i in range(stored_results_p1.size()):
        var button_component = answer_buttons_p1[i]
        var result_data = stored_results_p1[i]
        button_component.load_question_data(i, result_data)
        if result_data["was_correct"]:
            button_component.set_correct_state()
        else:
            button_component.set_incorrect_state()

    # Leave remaining P1 buttons in empty state
    for i in range(stored_results_p1.size(), answer_buttons_p1.size()):
        answer_buttons_p1[i].set_empty_state()

    # Update P2 buttons
    for i in range(stored_results_p2.size()):
        var button_component = answer_buttons_p2[i]
        var result_data = stored_results_p2[i]
        button_component.load_question_data(i, result_data)
        if result_data["was_correct"]:
            button_component.set_correct_state()
        else:
            button_component.set_incorrect_state()

    # Leave remaining P2 buttons in empty state
    for i in range(stored_results_p2.size(), answer_buttons_p2.size()):
        answer_buttons_p2[i].set_empty_state()


## Hide P2 (opponent) result buttons for incomplete rounds
##
## Sets only the P2 answer buttons to hidden state. P1 (local player) buttons
## are always visible. Used by gameplay_screen when opponent results should not
## be visible until both players complete the round.
func hide_results() -> void:
    for button in answer_buttons_p2:
        button.set_hidden_state()


## Reveal P2 (opponent) result buttons once both players have completed the round
##
## Restores all buttons to their correct/incorrect states. Called by gameplay_screen
## when both players have answered and results can be shown.
func show_results() -> void:
    _update_button_states()


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
