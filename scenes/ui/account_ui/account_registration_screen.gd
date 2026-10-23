# uid://-6118563010160079653
extends Control

## Account Registration Screen Controller
##
## Handles user input validation and account creation for new user registration.
## Monitors input fields and enables the Create Account button only when all fields
## are filled. Validates password match, email format, and username uniqueness
## when the button is pressed.

## Reference to the username input field
@onready var name_input: TextEdit = %NameInput

## Reference to the password input field
@onready var password_input: TextEdit = %PasswordInput

## Reference to the password confirmation input field
@onready var password_confirm: TextEdit = %PasswordConfirm

## Reference to the email input field<
@onready var email_input: TextEdit = %EmailInput

## Reference to the Create Account button
@onready var create_account_button: TextureButton = %CreateAccountButton

## Flag to track if account creation failed due to duplicate username
var _duplicate_username_error: bool = false
var _creating_account: bool = false


func _ready() -> void:
    # Initialize button as disabled
    create_account_button.disabled = true
    
    # Connect text_changed signals from all input fields
    name_input.text_changed.connect(_on_input_field_changed)
    password_input.text_changed.connect(_on_input_field_changed)
    password_confirm.text_changed.connect(_on_input_field_changed)
    email_input.text_changed.connect(_on_input_field_changed)
    
    # Connect special handler for username field to handle duplicate error recovery
    name_input.text_changed.connect(_on_name_input_changed)
    

## Called when any input field text changes
func _on_input_field_changed() -> void:
    # Enable button only if all fields have content and no duplicate username error
    _update_button_state()


## Called specifically when the username field changes
func _on_name_input_changed() -> void:
    # If there was a duplicate username error, clear it when username is edited
    if _duplicate_username_error:
        _duplicate_username_error = false
    _update_button_state()


## Update the Create Account button enabled/disabled state
func _update_button_state() -> void:
    var all_fields_filled: bool = (
        not name_input.text.strip_edges().is_empty() and
        not password_input.text.strip_edges().is_empty() and
        not password_confirm.text.strip_edges().is_empty() and
        not email_input.text.strip_edges().is_empty()
    )
    
    # Disable if duplicate username error flag is set
    create_account_button.disabled = not all_fields_filled or _duplicate_username_error or _creating_account


func _on_back_button_pressed() -> void:
    Utils.navigate_to_scene("main_lobby")

## Handle Create Account button press
func _on_create_account_button_pressed() -> void:
    if _creating_account:
        return

    var username: String = name_input.text.strip_edges()
    var password: String = password_input.text
    var password_confirm_text: String = password_confirm.text
    var email: String = email_input.text.strip_edges()
    
    # Validate password match
    if password != password_confirm_text:
        print("ERROR: Passwords do not match")
        return
    
    # Attempt to create user account
    _creating_account = true
    _update_button_state()
    var result: Dictionary = await UserDatabase.create_user(username, password, email)
    
    if result.get("success", false):
        print("Account created successfully")

        var sign_in_result: Dictionary = await UserDatabase.sign_in(email, password)
        if sign_in_result.get("success", false):
            if not LocalCache.remember_session():
                push_error("Account created and signed in, but the session could not be saved on this device")
            Utils.navigate_to_scene("account_management", "register_login")
        else:
            push_error("Account created, but sign-in failed (%s): %s" % [
                sign_in_result.get("error_code", "UNKNOWN"),
                sign_in_result.get("message", "No error details returned")
            ])
            Utils.navigate_to_scene("register_login")
    else:
        push_warning("Account creation failed (%s): %s" % [
            result.get("error_code", "UNKNOWN"),
            result.get("message", "No error details returned")
        ])
        
        # If duplicate username error, set flag and disable button
        if result.get("error_code") == "USERNAME_EXISTS":
            _duplicate_username_error = true

    _creating_account = false
    _update_button_state()


func _on_sign_in_button_pressed() -> void:
    Utils.navigate_to_scene("register_login")
