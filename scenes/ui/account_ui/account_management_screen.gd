extends Control
## Account Management Screen
##
## Displays user account information and settings with navigation back to main lobby.

func _ready() -> void:
	# Connect BackButton signal
	var back_button: Button = $BackButton
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)


## Handle BackButton press - return to main lobby
func _on_back_button_pressed() -> void:
	_navigate_to_main_lobby()


## Navigate to main lobby screen
func _navigate_to_main_lobby() -> void:
	var scene_path := "res://scenes/ui/main_lobby_screen.tscn"
	if ResourceLoader.exists(scene_path):
		TransitionManager.change_scene(scene_path)
	else:
		push_error("Failed to navigate: main_lobby_screen.tscn not found at " + scene_path)
		# Fallback already to main lobby, so just log error
