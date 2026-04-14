extends Control
## Register/Login Screen
##
## Provides user authentication interface with navigation to account registration
## and account management after successful login.

## Reference to the username input field
@onready var username_input: TextEdit = %UsernameInput

## Reference to the password input field
@onready var password_input: TextEdit = %PasswordInput

## Reference to the Log In button
@onready var log_in_button: Button = %LogInButton

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
    var all_fields_filled: bool = (
        not username_input.text.strip_edges().is_empty() and
        not password_input.text.strip_edges().is_empty()
    )
    
    # Disable if login error flag is set
    log_in_button.disabled = not all_fields_filled or _login_failed


## Handle BackButton press - return to main lobby
func _on_back_button_pressed() -> void:
    Utils.navigate_to_scene("main_lobby")


## Handle NewAccountButton press - navigate to account registration
func _on_new_account_button_pressed() -> void:
    Utils.navigate_to_scene("account_registration")


func _on_log_in_button_pressed() -> void:
    var username: String = username_input.text.strip_edges()
    var password: String = password_input.text
    
    # Attempt to sign in with UserDatabase
    var result: Dictionary = UserDatabase.sign_in(username, password)
    
    if result.success:
        # Success - navigate to account management
        Utils.navigate_to_scene("account_management", "main_lobby")
    else:
        # Error - log the error message
        print("ERROR: ", result.message)
        
        # Set login failed flag and disable button
        _login_failed = true
        _update_button_state()
