extends Control
## Main Lobby Screen
##
## Entry point screen that provides access to game features and account management.
## Conditionally navigates to account screens based on user login state.

## Cached user login state, set during _ready()
var _is_user_logged_in: bool = false


func _ready() -> void:
    # Cache user login state for navigation decisions
    _is_user_logged_in = UserDatabase.is_signed_in()


## Handle AccountButton press with conditional navigation based on login state
func _on_account_button_pressed() -> void:
    if _is_user_logged_in:
        # User is logged in - navigate to account management
        _navigate_to_account_management()
    else:
        # User is not logged in - navigate to register/login
        _navigate_to_register_login()


func _on_play_button_pressed() -> void:
    pass # Replace with function body.

## Navigate to register/login screen
func _navigate_to_register_login() -> void:
    var scene_path := "res://scenes/ui/account_ui/register_login_screen.tscn"
    if ResourceLoader.exists(scene_path):
        TransitionManager.change_scene(scene_path)
    else:
        push_error("Failed to navigate: register_login_screen.tscn not found at " + scene_path)


## Navigate to account management screen
func _navigate_to_account_management() -> void:
    var scene_path := "res://scenes/ui/account_ui/account_management_screen.tscn"
    if ResourceLoader.exists(scene_path):
        TransitionManager.change_scene(scene_path)
    else:
        push_error("Failed to navigate: account_management_screen.tscn not found at " + scene_path)
