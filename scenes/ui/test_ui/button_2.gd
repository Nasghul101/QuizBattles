extends Button
signal play_animation

func _on_animate_on_other_nodes_button_pressed() -> void:
	play_animation.emit()
