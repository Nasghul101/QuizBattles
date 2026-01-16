extends Button
## Answer button component for quiz questions
##
## A reusable button component for displaying quiz answers. Handles user interaction,
## visual feedback for correct/wrong answers, and state management.
##
## Usage:
##   1. Instance the answer_button.tscn scene
##   2. Connect to the answer_selected signal
##   3. Call set_answer(text, index) to populate the button
##   4. Call reveal_correct() or reveal_wrong() to show result

# Signal emitted when the button is pressed, includes the answer index
signal answer_selected(index: int)

# Exported color properties for customization
@export var neutral_color: Color = Color(0.5, 0.5, 0.5, 1.0)  # Grey
@export var correct_color: Color = Color(0.2, 0.8, 0.2, 1.0)  # Green
@export var wrong_color: Color = Color(0.8, 0.2, 0.2, 1.0)    # Red
@export var selected_outline_color: Color = Color(1.0, 1.0, 1.0, 1.0)  # White
@export var animation_duration: float = 0.3

# Internal state
var answer_index: int = -1
var _tween: Tween
var _style_box: StyleBoxFlat

func _ready() -> void:
    # Set up initial styling with neutral color
    _setup_style()
    
    # Connect button press to internal handler
    pressed.connect(_on_button_pressed)

## Initialize the button's visual style with neutral color
func _setup_style() -> void:
    _style_box = StyleBoxFlat.new()
    _style_box.bg_color = neutral_color
    _style_box.border_width_left = 0
    _style_box.border_width_right = 0
    _style_box.border_width_top = 0
    _style_box.border_width_bottom = 0
    _style_box.corner_radius_top_left = 8
    _style_box.corner_radius_top_right = 8
    _style_box.corner_radius_bottom_left = 8
    _style_box.corner_radius_bottom_right = 8
    _style_box.content_margin_left = 16
    _style_box.content_margin_right = 16
    _style_box.content_margin_top = 12
    _style_box.content_margin_bottom = 12
    
    add_theme_stylebox_override("normal", _style_box)
    add_theme_stylebox_override("hover", _style_box)
    add_theme_stylebox_override("pressed", _style_box)
    add_theme_stylebox_override("disabled", _style_box)

## Set the answer text and index for this button
##
## Args:
##   answer_text: The text to display on the button
##   index: The index of this answer (0-3)
func set_answer(answer_text: String, index: int) -> void:
    text = answer_text
    answer_index = index

## Handle button press: disable and add white outline, emit signal
func _on_button_pressed() -> void:
    disabled = true
    
    # Add white outline to indicate selection
    _style_box.border_width_left = 3
    _style_box.border_width_right = 3
    _style_box.border_width_top = 3
    _style_box.border_width_bottom = 3
    _style_box.border_color = selected_outline_color
    
    # Emit signal with answer index
    answer_selected.emit(answer_index)

## Animate button to correct (green) state
func reveal_correct() -> void:
    _animate_color(correct_color)

## Animate button to wrong (red) state
func reveal_wrong() -> void:
    _animate_color(wrong_color)

## Reset button to neutral state for new question
func reset() -> void:
    # Re-enable the button
    disabled = false
    
    # Remove white outline
    _style_box.border_width_left = 0
    _style_box.border_width_right = 0
    _style_box.border_width_top = 0
    _style_box.border_width_bottom = 0
    
    # Reset to neutral color
    _style_box.bg_color = neutral_color
    
    # Cancel any ongoing animation
    if _tween:
        _tween.kill()

## Smoothly animate the button's background color
##
## Args:
##   target_color: The color to animate to
func _animate_color(target_color: Color) -> void:
    # Cancel any existing tween
    if _tween:
        _tween.kill()
    
    # Create new tween for color transition
    _tween = create_tween()
    _tween.set_ease(Tween.EASE_OUT)
    _tween.set_trans(Tween.TRANS_CUBIC)
    _tween.tween_property(_style_box, "bg_color", target_color, animation_duration)
