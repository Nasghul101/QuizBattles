extends Node
## Utils
##
## General-purpose utility functions shared across scripts to prevent code duplication.

## Path to the color codes JSON file
const COLOR_CODES_PATH: String = "res://data/color_codes.json"

## Scene path definitions for navigation
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
        push_error("Utils: Unknown scene key '%s'" % scene_key)
        if not fallback_key.is_empty():
            navigate_to_scene(fallback_key)
        return

    if not ResourceLoader.exists(scene_path):
        push_error("Utils: Scene file does not exist at path: %s" % scene_path)
        if not fallback_key.is_empty():
            navigate_to_scene(fallback_key)
        return

    TransitionManager.change_scene(scene_path)


## Returns the full color codes dictionary parsed from color_codes.json.
##
## The returned dictionary has two top-level keys:
##   - "category_colors": Dictionary mapping category names to hex color strings (or null)
##   - "miscellaneous": Dictionary mapping color names to hex color strings
##
## Example usage:
##   var colors = Utils.get_color_codes()
##   var bg_color = Color(colors["miscellaneous"]["App background"])
##   var science_color = Color(colors["category_colors"]["Science"])
func get_color_codes() -> Dictionary:
    if not FileAccess.file_exists(COLOR_CODES_PATH):
        push_error("Utils: Color codes file not found at: %s" % COLOR_CODES_PATH)
        return {}

    var file: FileAccess = FileAccess.open(COLOR_CODES_PATH, FileAccess.READ)
    if file == null:
        push_error("Utils: Failed to open color codes file: %s" % str(FileAccess.get_open_error()))
        return {}

    var json_string: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()
    var parse_result: Error = json.parse(json_string)
    if parse_result != OK:
        push_error("Utils: Failed to parse color codes JSON: %s" % json.get_error_message())
        return {}

    return json.data
