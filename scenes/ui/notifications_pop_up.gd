extends MarginContainer
signal play_animation


func _on_notifications_button_pressed() -> void:
	play_animation.emit()


func _on_close_pop_up_button_pressed() -> void:
	play_animation.emit()
