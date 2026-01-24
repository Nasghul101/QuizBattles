extends Control
## Setup screen for configuring game settings
##
## Allows players to configure the number of rounds and questions per round
## using interactive sliders, then transitions to the gameplay screen.

## Reference to rounds slider
@onready var rounds_slider: HSlider = %RoundsSlider

## Reference to rounds amount label
@onready var rounds_amount: Label = %RoundsAmount

## Reference to questions slider
@onready var questions_slider: HSlider = %QuestionsSlider

## Reference to questions amount label
@onready var questions_amount: Label = %QuestionsAmount



func _ready() -> void:
    # Set default values
    rounds_slider.value = 5.0
    questions_slider.value = 3.0
    
    # Configure sliders for integer-only values
    rounds_slider.step = 1.0
    questions_slider.step = 1.0
    
    # Update labels to show default values
    rounds_amount.text = str(int(rounds_slider.value))
    questions_amount.text = str(int(questions_slider.value))
    
    # Connect signals
    rounds_slider.value_changed.connect(_on_rounds_slider_changed)
    questions_slider.value_changed.connect(_on_questions_slider_changed)


## Updates rounds amount label when slider changes
func _on_rounds_slider_changed(value: float) -> void:
    rounds_amount.text = str(int(value))


## Updates questions amount label when slider changes
func _on_questions_slider_changed(value: float) -> void:
    questions_amount.text = str(int(value))


## Starts the game with selected configuration
func _on_start_game_button_pressed() -> void:
    var rounds_value: int = int(rounds_slider.value)
    var questions_value: int = int(questions_slider.value)
    
    var params: Dictionary = {
        "rounds": rounds_value,
        "questions": questions_value
    }
    
    TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)
    
