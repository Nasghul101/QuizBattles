@tool
class_name Animation_Component extends Node

signal entered
signal moved

@export_group("Options")
@export var from_center : bool = true
@export var enter_animation : bool = false
@export var visible_animation : bool = false
@export var movement_animation : bool = false
@export var time : float = 0.1
@export var transition_type : Tween.TransitionType
@export var parallel_animations : bool = true
@export var properties : Array = [
	"scale",
	"position",
	"rotation",
	"size",
    "self_modulate"
]

@export_group("Pressed Settings")
@export var press_anim_time : float = 0.1
@export var press_delay : float = 0.0
@export var press_transition : Tween.TransitionType
@export var press_easing : Tween.EaseType
@export var press_position: Vector2
@export var press_scale : Vector2 = Vector2(1,1)
@export var press_rotation : float
@export var press_size : Vector2
@export var press_modulate : Color = Color.WHITE

@export_group("Enter Settings")
@export var enter_anim_time : float = 0.1
@export var enter_delay : float = 0.0
@export var wait_for : Animation_Component
@export var enter_transition : Tween.TransitionType
@export var enter_easing : Tween.EaseType
@export var enter_position: Vector2
@export var enter_scale : Vector2 = Vector2(1,1)
@export var enter_rotation : float
@export var enter_size : Vector2
@export var enter_modulate : Color = Color.WHITE

@export_group("Visible Settings")
@export var visible_anim_time : float = 0.1
@export var visible_delay : float = 0.0
@export var visible_transition : Tween.TransitionType
@export var visible_easing : Tween.EaseType
@export var visible_position: Vector2
@export var visible_scale : Vector2 = Vector2(1,1)
@export var visible_rotation : float
@export var visible_size : Vector2
@export var visible_modulate : Color = Color.WHITE

@export_group("Movement Settings")
@export var movement_anim_time : float = 0.1
@export var movement_delay : float = 0.0
@export var wait_for_movement : Animation_Component
@export var movement_transition : Tween.TransitionType
@export var movement_easing : Tween.EaseType
@export var movement_position: Vector2
@export var movement_scale : Vector2 = Vector2(1,1)
@export var movement_rotation : float
@export var movement_size : Vector2
@export var movement_modulate : Color = Color.WHITE

var target : Control
var default_scale : Vector2
var default_values : Dictionary
var press_values : Dictionary
var enter_values : Dictionary
var visible_values : Dictionary
var movement_values : Dictionary
var movement_reversed : bool = false
var movement_playing : bool = false

const IMMEDIATE_TRANSITION = Tween.TRANS_LINEAR


func _validate_property(property: Dictionary) -> void:
	# Make Enter Settings read-only if enter_animation is not checked
	if property.name in ["enter_anim_time", "enter_delay", "wait_for", "enter_transition", 
						 "enter_easing", "enter_position", "enter_scale", "enter_rotation", 
						 "enter_size", "enter_modulate"]:
		if not enter_animation:
			property.usage |= PROPERTY_USAGE_READ_ONLY
	
	# Make Visible Settings read-only if visible_animation is not checked
	if property.name in ["visible_anim_time", "visible_delay", "visible_transition", 
						 "visible_easing", "visible_position", "visible_scale", 
						 "visible_rotation", "visible_size", "visible_modulate"]:
		if not visible_animation:
			property.usage |= PROPERTY_USAGE_READ_ONLY

	# Make Movement Settings read-only if movement_animation is not checked
	if property.name in ["movement_anim_time", "movement_delay", "wait_for_movement", "movement_transition",
						 "movement_easing", "movement_position", "movement_scale",
						 "movement_rotation", "movement_size", "movement_modulate"]:
		if not movement_animation:
			property.usage |= PROPERTY_USAGE_READ_ONLY

func _ready() -> void:
	target = get_parent()
	call_deferred("setup")
	

#this connects signals for when animations should be played
func connect_signals() -> void:
	if target.has_signal("pressed"):
		target.pressed.connect(add_tween.bind(
				press_values,
				parallel_animations,
				press_anim_time,
				press_delay,
				press_transition,
				press_easing,
				false,
				true,
			)
	)
	if wait_for:
		wait_for.entered.connect(add_tween.bind(
				default_values,
				parallel_animations,
				enter_anim_time,
				enter_delay,
				enter_transition,
				enter_easing,
				true,
				false,
			)
		)

	if target.has_signal("play_animation"):
		target.play_animation.connect(on_play_animation)
	if wait_for_movement:
		wait_for_movement.moved.connect(on_play_animation)

	if target.has_signal("visibility_changed"):
		target.visibility_changed.connect(on_visible.bind())
		on_visible()


#makes the setup with the selected export variables 
func setup() -> void:
	if from_center:
		target.pivot_offset = target.size / 2
	default_scale = target.scale
	default_values = {
		"scale" : target.scale,
		"position" : target.position,
		"rotation" : target.rotation,
		"size" : target.size,
		"self_modulate": target.modulate,
	}
	press_values = {
		"scale" : press_scale,
		"position" : target.position + press_position,
		"rotation" : target.rotation + deg_to_rad(press_rotation),
		"size" : target.size + press_size,
		"self_modulate": press_modulate,
	}
	enter_values = {
		"scale" : enter_scale,
		"position" : target.position + enter_position,
		"rotation" : target.rotation + deg_to_rad(enter_rotation),
		"size" : target.size + enter_size,
		"self_modulate": enter_modulate,
	}
	visible_values = {
		"scale" : visible_scale,
		"position" : target.position + visible_position,
		"rotation" : target.rotation + deg_to_rad(visible_rotation),
		"size" : target.size + visible_size,
		"self_modulate": visible_modulate,
	}
	movement_values = {
		"scale" : movement_scale,
		"position" : target.position + movement_position,
		"rotation" : target.rotation + deg_to_rad(movement_rotation),
		"size" : target.size + movement_size,
		"self_modulate": movement_modulate,
	}
	connect_signals()
	if enter_animation:
		on_enter()
	else:
		entered.emit()

#this plays the enter animation when the node is ready, if the enter_animation export variable is set to true
func on_enter() -> void:
		add_tween(enter_values, true, 0.0, 0.0, IMMEDIATE_TRANSITION, enter_easing, false, false)

		if wait_for:
			pass
		else:
			add_tween(default_values, parallel_animations, enter_anim_time, enter_delay, enter_transition, enter_easing, true, false)

#plays the movement animation, reversing direction each time play_animation is emitted
func on_play_animation() -> void:
	if movement_playing:
		return
	movement_playing = true
	var values = default_values if movement_reversed else movement_values
	movement_reversed = not movement_reversed
	await add_tween(values, parallel_animations, movement_anim_time, movement_delay, movement_transition, movement_easing, false, false, true)
	movement_playing = false

#when turned visible this goes back to its original values
func on_visible() -> void:

	if not visible_animation:
		return

	if target.visible:
		add_tween(default_values, visible_animation, visible_anim_time, visible_delay, visible_transition, visible_easing, false, false)
	else:
		add_tween(visible_values, parallel_animations, 0.1, 0.0, IMMEDIATE_TRANSITION, visible_easing, false, false)


#this setups the tween with the given values, parallel_animations, seconds, delay, transition and easing
func add_tween(values: Dictionary, parallel_animations: bool, seconds: float, delay : float, transition: Tween.TransitionType, 
easing: Tween.EaseType, entering: bool, pressed: bool, moving: bool = false) -> void:
	var tween = get_tree().create_tween()
	tween.set_parallel(parallel_animations)
	tween.pause()
	for property in properties:
		tween.tween_property(target, str(property), values[property], seconds).set_trans(transition).set_ease(easing)
	await get_tree().create_timer(delay).timeout
	tween.play()

	if entering:
		await tween.finished
		entered.emit()

	if moving:
		await tween.finished
		moved.emit()
	
	if pressed:
		await tween.finished
		add_tween(default_values, parallel_animations, press_anim_time, 0.0, press_transition, press_easing, false, false)
