extends Control
## Register/Login Screen
##
## Provides user authentication interface with navigation to account registration
## and account management after successful login.

## Handle BackButton press - return to main lobby
func _on_back_button_pressed() -> void:
    _navigate_to_main_lobby()


## Handle NewAccountButton press - navigate to account registration
func _on_new_account_button_pressed() -> void:
    _navigate_to_account_registration()


func _on_log_in_button_pressed() -> void:
    pass # Replace with function body.


## Navigate to main lobby screen
func _navigate_to_main_lobby() -> void:
    var scene_path := "res://scenes/ui/main_lobby_screen.tscn"
    if ResourceLoader.exists(scene_path):
        TransitionManager.change_scene(scene_path)
    else:
        push_error("Failed to navigate: main_lobby_screen.tscn not found at " + scene_path)
        # Fallback already to main lobby, so just log error


## Navigate to account registration screen
func _navigate_to_account_registration() -> void:
    var scene_path := "res://scenes/ui/account_ui/account_registration_screen.tscn"
    if ResourceLoader.exists(scene_path):
        TransitionManager.change_scene(scene_path)
    else:
        push_error("Failed to navigate: account_registration_screen.tscn not found at " + scene_path)
        # Fallback to main lobby on error
        _navigate_to_main_lobby()


## Navigate to account management screen after successful login
## This method is called after login authentication completes successfully
## NOTE: Login logic implementation is out of scope - this is a navigation stub
func _navigate_to_account_management_after_login() -> void:
    var scene_path := "res://scenes/ui/account_ui/account_management_screen.tscn"
    if ResourceLoader.exists(scene_path):
        TransitionManager.change_scene(scene_path)
    else:
        push_error("Failed to navigate: account_management_screen.tscn not found at " + scene_path)
        # Fallback to main lobby on error
        _navigate_to_main_lobby()
