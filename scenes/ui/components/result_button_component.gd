extends TextureButton
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

# Color utils
var colors = Utils.get_color_codes()

# Node ref
@onready var hidden_icon: TextureRect = %HiddenIcon

func _ready() -> void:
    # Connect internal button signal
    pressed.connect(_on_button_pressed)
    hidden_icon.visible = false


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
    hidden_icon.visible = false
    disabled = false
    self_modulate = Color(colors["miscellaneous"]["Right answer"])


## Configure button to display incorrect answer state
##
## Sets the button to show the incorrect icon, enables interaction,
## and resets modulation to full color.
func set_incorrect_state() -> void:
    hidden_icon.visible = false
    disabled = false
    self_modulate = Color(colors["miscellaneous"]["Wrong answer"])

## Configure button to display empty/disabled state
##
## Sets the button to a disabled, grey appearance with no icon.
## Used for unused button slots before results are loaded.
func set_empty_state() -> void:
    visible = true
    hidden_icon.visible = false
    disabled = true
    self_modulate = Color(colors["miscellaneous"]["App gray"])


## Configure button to display hidden state
##
## Sets the button to show the hidden icon and disables interaction.
## Used when opponent results should not be visible until both players complete the round.
func set_hidden_state() -> void:
    hidden_icon.visible = true
    disabled = true
    self_modulate = Color(colors["miscellaneous"]["App gray"])


## Handle button press and emit custom signal
func _on_button_pressed() -> void:
    if question_index >= 0 and not question_data.is_empty():
        result_clicked.emit(question_index, question_data)


var _state_timer: float = 0.0
var _current_state: int = 0
const _STATES = ["correct", "incorrect", "empty", "hidden"]

#for testing the differenct state looks
#func _process(delta: float) -> void:
    #_state_timer += delta
    #if _state_timer >= 5.0:
        #_state_timer = 0.0
        #_current_state = (_current_state + 1) % _STATES.size()
        #match _STATES[_current_state]:
            #"correct":
                #set_correct_state()
            #"incorrect":
                #set_incorrect_state()
            #"empty":
                #set_empty_state()
            #"hidden":
                #set_hidden_state()
    #
