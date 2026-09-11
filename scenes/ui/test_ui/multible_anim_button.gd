extends Button
signal play_animation


func _on_pressed() -> void:
	play_animation.emit()
