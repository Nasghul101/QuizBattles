extends Control
## Register/Login Screen
##
## Provides user authentication interface with navigation to account registration
## and account management after successful login.

## Reference to the username input field
@onready var username_input: TextEdit = $VBoxContainer/UsernameInput

## Reference to the password input field
@onready var password_input: TextEdit = $VBoxContainer/PasswordInput

## Reference to the Log In button
@onready var log_in_button: Button = $VBoxContainer/LogInButton

## Flag to track if login failed due to authentication error
var _login_failed: bool = false


func _ready() -> void:
    # Initialize button as disabled
    log_in_button.disabled = true
    
    # Connect text_changed signals from both input fields
    username_input.text_changed.connect(_on_input_field_changed)
    password_input.text_changed.connect(_on_input_field_changed)
    
    # Connect special handler for username field to handle login error recovery
    username_input.text_changed.connect(_on_username_input_changed)


## Called when any input field text changes
func _on_input_field_changed() -> void:
    # Enable button only if all fields have content and no login error
    _update_button_state()


## Called specifically when the username field changes
func _on_username_input_changed() -> void:
    # If there was a login error, clear it when username is edited
    if _login_failed:
        _login_failed = false


## Update the Log In button enabled/disabled state
func _update_button_state() -> void:
    var all_fields_filled := (
        not username_input.text.strip_edges().is_empty() and
        not password_input.text.strip_edges().is_empty()
    )
    
    # Disable if login error flag is set
    log_in_button.disabled = not all_fields_filled or _login_failed


## Handle BackButton press - return to main lobby
func _on_back_button_pressed() -> void:
    _navigate_to_main_lobby()


## Handle NewAccountButton press - navigate to account registration
func _on_new_account_button_pressed() -> void:
    _navigate_to_account_registration()


func _on_log_in_button_pressed() -> void:
    var username := username_input.text.strip_edges()
    var password := password_input.text
    
    # Attempt to sign in with UserDatabase
    var result := UserDatabase.sign_in(username, password)
    
    if result.success:
        # Success - navigate to account management
        _navigate_to_account_management_after_login()
    else:
        # Error - log the error message
        print("ERROR: ", result.message)
        
        # Set login failed flag and disable button
        _login_failed = true
        _update_button_state()


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
