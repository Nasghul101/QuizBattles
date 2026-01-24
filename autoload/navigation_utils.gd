extends Node
## NavigationUtils
##
## Centralized scene navigation utility for consistent scene transitions.
## Provides scene path validation and error handling for all navigation operations.

## Scene path definitions
const SCENES: Dictionary = {
	"main_lobby": "res://scenes/ui/main_lobby_screen.tscn",
	"register_login": "res://scenes/ui/account_ui/register_login_screen.tscn",
	"account_management": "res://scenes/ui/account_ui/account_management_screen.tscn",
	"account_registration": "res://scenes/ui/account_ui/account_registration_screen.tscn"
}


## Navigate to a scene by key with optional fallback
##
## @param scene_key: Key from SCENES dictionary
## @param fallback_key: Optional fallback scene key if primary fails
func navigate_to_scene(scene_key: String, fallback_key: String = "") -> void:
	var scene_path: String = SCENES.get(scene_key, "")
	
	if scene_path.is_empty():
		push_error("NavigationUtils: Unknown scene key '%s'" % scene_key)
		if not fallback_key.is_empty():
			navigate_to_scene(fallback_key)
		return
	
	if not ResourceLoader.exists(scene_path):
		push_error("NavigationUtils: Scene file does not exist at path: %s" % scene_path)
		if not fallback_key.is_empty():
			navigate_to_scene(fallback_key)
		return
	
	TransitionManager.change_scene(scene_path)
