extends Control
## Account Management Screen
##
## Displays user account information and settings with navigation back to main lobby.

func _ready() -> void:
    # Display username
    _display_username()
    
    # Connect BackButton signal
    var back_button: Button = $BackButton
    if back_button:
        back_button.pressed.connect(_on_back_button_pressed)
    
    # Connect LogOffButton signal
    var log_off_button: Button = $VBoxContainer/LogOffButton
    if log_off_button:
        log_off_button.pressed.connect(_on_log_off_button_pressed)


## Display the current user's username in NameLabel
func _display_username() -> void:
    var name_label: Label = $VBoxContainer/NameLabel
    if name_label:
        var current_user := UserDatabase.get_current_user()
        if not current_user.is_empty() and current_user.has("username"):
            name_label.text = current_user["username"]
        # If no user or no username, keep existing label text as fallback


## Handle BackButton press - return to main lobby
func _on_back_button_pressed() -> void:
    _navigate_to_main_lobby()


## Handle LogOffButton press - log out user and return to login screen
func _on_log_off_button_pressed() -> void:
    # Get username before logging out for console message
    var current_user := UserDatabase.get_current_user()
    var username: String = current_user.get("username", "Unknown") if not current_user.is_empty() else "Unknown"
    
    # Log out the user
    UserDatabase.sign_out()
    
    # Log confirmation to console
    print("User %s logged out" % username)
    
    # Navigate to register/login screen
    _navigate_to_register_login()


## Navigate to main lobby screen
func _navigate_to_main_lobby() -> void:
    var scene_path := "res://scenes/ui/main_lobby_screen.tscn"
    if ResourceLoader.exists(scene_path):
        TransitionManager.change_scene(scene_path)
    else:
        push_error("Failed to navigate: main_lobby_screen.tscn not found at " + scene_path)
        # Fallback already to main lobby, so just log error


## Navigate to register/login screen
func _navigate_to_register_login() -> void:
    var scene_path := "res://scenes/ui/account_ui/register_login_screen.tscn"
    if ResourceLoader.exists(scene_path):
        TransitionManager.change_scene(scene_path)
    else:
        push_error("Failed to navigate: register_login_screen.tscn not found at " + scene_path)
