extends MarginContainer

signal play_animation

@onready var pop_up_background: Panel = %PopUpBackground


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not pop_up_background.get_global_rect().has_point(event.global_position):
			play_animation.emit()
			accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		if not pop_up_background.get_global_rect().has_point(event.position):
			play_animation.emit()
			accept_event()


func _on_notifications_button_pressed() -> void:
	play_animation.emit()


func _on_close_pop_up_button_pressed() -> void:
	play_animation.emit()
