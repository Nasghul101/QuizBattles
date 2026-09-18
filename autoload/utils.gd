# uid://cfid8ydxnxm8p
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

## Last page selected in the main lobby during this app session.
var last_lobby_page: int = 0

## Locales supported by localization/ui_translations.csv, in priority order.
const SUPPORTED_LOCALES: PackedStringArray = ["en", "de"]

## Default locale used when no stored preference or supported OS locale is found.
const DEFAULT_LOCALE: String = "en"


func _ready() -> void:
    _bootstrap_locale()


## Resolve and apply the active locale on startup.
##
## Priority: stored player preference -> supported OS locale -> DEFAULT_LOCALE.
func _bootstrap_locale() -> void:
    var stored_locale: String = LocalCache.get_setting("locale", "")
    if not stored_locale.is_empty() and SUPPORTED_LOCALES.has(stored_locale):
        TranslationServer.set_locale(stored_locale)
        return

    var os_locale: String = OS.get_locale_language()
    if SUPPORTED_LOCALES.has(os_locale):
        TranslationServer.set_locale(os_locale)
        return

    TranslationServer.set_locale(DEFAULT_LOCALE)


## Change the active app locale at runtime and persist the choice.
##
## @param locale: A locale code from SUPPORTED_LOCALES (e.g. "en", "de")
func set_app_locale(locale: String) -> void:
    if not SUPPORTED_LOCALES.has(locale):
        push_error("Utils: Unsupported locale '%s'" % locale)
        return

    TranslationServer.set_locale(locale)
    LocalCache.set_setting("locale", locale)


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
##   var colors: Dictionary = Utils.get_color_codes()
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

## Resolve the accent Color for a category name from color_codes.json
##
## Returns Color.WHITE when the category is unknown or has no defined color.
func resolve_category_color(category: String) -> Color:
    var codes: Dictionary = get_color_codes()
    var category_colors: Dictionary = codes.get("category_colors", {})
    if not category_colors.has(category):
        return Color.WHITE
    var value = category_colors[category]
    if value == null:
        return Color.WHITE
    return Color(value)


## Translate a canonical (English) category name for display in the current locale.
##
## The canonical name (e.g. "General Knowledge") is what question data and
## color_codes.json key off of, so callers must keep using it for lookups and
## only use the translated string for on-screen display.
##
## Falls back to the original category name if no matching CATEGORY_* key exists.
func translate_category(category_name: String) -> String:
    var key: String = "CATEGORY_" + category_name.to_upper().replace(" ", "_")
    var translated: String = tr(key)
    return category_name if translated == key else translated
