extends TextureButton
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
var neutral_color: Color
@export var correct_color: Color = Color(0.2, 0.8, 0.2, 1.0)  # Green
@export var wrong_color: Color = Color(0.8, 0.2, 0.2, 1.0)    # Red
@export var selected_outline_color: Color = Color(1.0, 1.0, 1.0, 1.0)  # White
@export var animation_duration: float = 0.3

# Internal state
var answer_index: int = -1
var _answer_text: String = ""
var _tween: Tween

@onready var answer_label: AutoSizeLabel = %AnswerLabel

# Property to expose answer text as read-only
var answer_text: String:
    get:
        return _answer_text

func _ready() -> void:
    # Set initial neutral color tint
    neutral_color = get_self_modulate()
    
    # Connect button press to internal handler
    pressed.connect(_on_button_pressed)

## Set the answer text and index for this button
##
## Args:
##   answer_text: The text to display on the button
##   index: The index of this answer (0-3)
func set_answer(answer_text: String, index: int) -> void:
    _answer_text = answer_text
    answer_label.text = answer_text
    answer_index = index

## Handle button press: disable and emit signal
func _on_button_pressed() -> void:
    disabled = true
    
    # Emit signal with answer index
    answer_selected.emit(answer_index)

## Animate button to correct (green) state
func reveal_correct() -> void:
    _animate_modulate(correct_color)

## Animate button to wrong (red) state
func reveal_wrong() -> void:
    _animate_modulate(wrong_color)

## Reset button to neutral state for new question
func reset() -> void:
    # Re-enable the button
    disabled = false
    
    # Reset to neutral color
    self_modulate = neutral_color
    
    # Cancel any ongoing animation
    if _tween:
        _tween.kill()

## Enable or disable the pulsating animation on the shader material
##
## Args:
##   enabled: Whether pulsating should be active
func set_pulsating_enabled(enabled: bool) -> void:
    var mat := self.material as ShaderMaterial
    if mat == null:
        push_warning("answer_button: material is not a ShaderMaterial; set_pulsating_enabled is a no-op")
        return
    mat.set_shader_parameter("enable_pulsating", enabled)

## Set the outline color on the shader material
##
## Args:
##   color: The outline color to apply
func set_shader_outline_color(color: Color) -> void:
    var mat := self.material as ShaderMaterial
    if mat == null:
        push_warning("answer_button: material is not a ShaderMaterial; set_shader_outline_color is a no-op")
        return
    mat.set_shader_parameter("outline_color", color)

## Set the pulsating color on the shader material
##
## Args:
##   color: The pulsating glow color to apply
func set_pulsating_color(color: Color) -> void:
    var mat := self.material as ShaderMaterial
    if mat == null:
        push_warning("answer_button: material is not a ShaderMaterial; set_pulsating_color is a no-op")
        return
    mat.set_shader_parameter("pulsating_color", color)

## Smoothly animate the button's modulate tint
##
## Args:
##   target_color: The color to animate to
func _animate_modulate(target_color: Color) -> void:
    # Cancel any existing tween
    if _tween:
        _tween.kill()
    
    # Create new tween for color transition
    _tween = create_tween()
    _tween.set_ease(Tween.EASE_OUT)
    _tween.set_trans(Tween.TRANS_CUBIC)
    _tween.tween_property(self, "self_modulate", target_color, animation_duration)
