extends Button
## Result button component for displaying answer outcome indicators
##
## A reusable button component that displays correct/incorrect icons for quiz answers.
## Manages its own visual properties, icon assets, and emits signals when clicked.
##
## Usage:
##   1. Instance the result_button_component.tscn scene
##   2. Connect to the result_clicked signal
##   3. Call set_correct_state(), set_incorrect_state(), or set_empty_state()
##   4. Set question data via load_question_data() to enable signal emission

# Signal emitted when the button is pressed with associated question data
signal result_clicked(question_index: int, question_data: Dictionary)

# Internal state
var question_index: int = -1
var question_data: Dictionary = {}
@export var icon_right: Texture2D
@export var icon_wrong: Texture2D


func _ready() -> void:
    # Set default visual properties
    custom_minimum_size = Vector2(30, 30)
    expand_icon = true
    icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    
    # Connect internal button signal
    pressed.connect(_on_button_pressed)


## Load question data for this button
##
## Args:
##   index: Question index (0-based)
##   data: Complete question data dictionary
func load_question_data(index: int, data: Dictionary) -> void:
    question_index = index
    question_data = data.duplicate(true)  # Deep copy


## Configure button to display correct answer state
##
## Sets the button to show the correct icon, enables interaction,
## and resets modulation to full color.
func set_correct_state() -> void:
    icon = icon_right
    disabled = false
    modulate = Color(1.0, 1.0, 1.0)


## Configure button to display incorrect answer state
##
## Sets the button to show the incorrect icon, enables interaction,
## and resets modulation to full color.
func set_incorrect_state() -> void:
    icon = icon_wrong
    disabled = false
    modulate = Color(1.0, 1.0, 1.0)


## Configure button to display empty/disabled state
##
## Sets the button to a disabled, grey appearance with no icon.
## Used for unused button slots before results are loaded.
func set_empty_state() -> void:
    icon = null
    disabled = true
    modulate = Color(0.5, 0.5, 0.5)


## Handle button press and emit custom signal
func _on_button_pressed() -> void:
    if question_index >= 0 and not question_data.is_empty():
        result_clicked.emit(question_index, question_data)
