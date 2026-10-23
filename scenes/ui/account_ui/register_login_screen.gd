# uid://bbvvhw0unfkrd
extends Control
## Register/Login Screen
##
## Provides user authentication interface with navigation to account registration
## and account management after successful login.

## Reference to the email input field
@onready var email_input: TextEdit = %EmailInput

## Reference to the password input field
@onready var password_input: TextEdit = %PasswordInput

## Reference to the Log In button
@onready var log_in_button: TextureButton = %LogInButton

## Flag to track if login failed due to authentication error
var _login_failed: bool = false
var _login_in_progress: bool = false


func _ready() -> void:
    # Initialize button as disabled
    log_in_button.disabled = true
    
    # Connect text_changed signals from both input fields
    email_input.text_changed.connect(_on_input_field_changed)
    password_input.text_changed.connect(_on_input_field_changed)
    


## Called when any input field text changes
func _on_input_field_changed() -> void:
    # A failed login (wrong email or password) is cleared by any edit
    _login_failed = false
    _update_button_state()


## Update the Log In button enabled/disabled state
func _update_button_state() -> void:
    var all_fields_filled: bool = (
        not email_input.text.strip_edges().is_empty() and
        not password_input.text.strip_edges().is_empty()
    )
    
    # Disable if login error flag is set
    log_in_button.disabled = not all_fields_filled or _login_failed or _login_in_progress


## Handle BackButton press - return to main lobby
func _on_back_button_pressed() -> void:
    Utils.navigate_to_scene("main_lobby")


## Handle NewAccountButton press - navigate to account registration
func _on_new_account_button_pressed() -> void:
    Utils.navigate_to_scene("account_registration")


func _on_log_in_button_pressed() -> void:
    if _login_in_progress:
        return

    var email: String = email_input.text.strip_edges()
    var password: String = password_input.text

    _login_in_progress = true
    _update_button_state()
    var result: Dictionary = await UserDatabase.sign_in(email, password)
    _login_in_progress = false

    if result.get("success", false):
        if not LocalCache.remember_session():
            push_error("Login succeeded, but the session could not be saved on this device")
        Utils.navigate_to_scene("account_management", "main_lobby")
    else:
        push_warning("Sign-in failed (%s): %s" % [
            result.get("error_code", "UNKNOWN"),
            result.get("message", "No error details returned")
        ])
        _login_failed = true
        _update_button_state()
