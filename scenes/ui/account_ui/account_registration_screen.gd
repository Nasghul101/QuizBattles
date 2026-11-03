# uid://-6118563010160079653
extends Control

## Account Registration Screen Controller
##
## Handles user input validation and account creation for new user registration.
## Monitors input fields and enables the Create Account button only when all fields
## are filled. Validates password match, email format, and username uniqueness
## when the button is pressed.

## Reference to the username input field
@onready var name_input: LineEdit = %NameInput

## Reference to the password input field
@onready var password_input: LineEdit = %PasswordInput

## Reference to the password confirmation input field
@onready var password_confirm: LineEdit = %PasswordConfirm

## Reference to the email input field<
@onready var email_input: LineEdit = %EmailInput

## Reference to the Create Account button
@onready var create_account_button: TextureButton = %CreateAccountButton
@onready var feedback_dialog: AcceptDialog = $FeedbackDialog

## Reference to the Google sign-in button
@onready var google_sign_in_button: Button = $MarginContainer/VBoxContainer/GoogleSignInButton

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

    google_sign_in_button.pressed.connect(_on_google_sign_in_button_pressed)
    _update_button_state()
    

## Called when any input field text changes
func _on_input_field_changed(_new_text: String = "") -> void:
    # Enable button only if all fields have content and no duplicate username error
    _update_button_state()


## Called specifically when the username field changes
func _on_name_input_changed(_new_text: String = "") -> void:
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
    google_sign_in_button.disabled = _creating_account or not GoogleSignInService.is_available()


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

        var verification_result: Dictionary = await UserDatabase.send_email_verification()
        if not verification_result.get("success", false):
            push_warning("Account created, but the verification email could not be sent (%s): %s" % [
                verification_result.get("error_code", "UNKNOWN"),
                verification_result.get("message", "No error details returned")
            ])
            feedback_dialog.dialog_text = tr("ACCOUNT_REGISTRATION_VERIFICATION_SEND_FAILED")
            feedback_dialog.popup_centered()
            await feedback_dialog.confirmed

        var sign_in_result: Dictionary = await UserDatabase.sign_in(email, password)
        if sign_in_result.get("success", false):
            _finish_registration()
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


## Remember the new session and continue to the account screen
func _finish_registration() -> void:
    if not LocalCache.remember_session():
        push_error("Account created and signed in, but the session could not be saved on this device")
    Utils.navigate_to_scene("account_management", "register_login")


## Register (or sign in) with a Google account; independent of the text fields
func _on_google_sign_in_button_pressed() -> void:
    if _creating_account:
        return

    _creating_account = true
    _update_button_state()

    var google: Dictionary = await GoogleSignInService.sign_in()
    if google.get("success", false):
        var result: Dictionary = await UserDatabase.register_with_google(
            google.id_token, google.get("display_name", ""), google.get("email", "")
        )
        if result.get("success", false):
            _finish_registration()
        else:
            push_warning("Google registration failed (%s): %s" % [
                result.get("error_code", "UNKNOWN"),
                result.get("message", "No error details returned")
            ])
    else:
        push_warning("Google sign-in failed (%s): %s" % [
            google.get("error_code", "UNKNOWN"),
            google.get("message", "No error details returned")
        ])

    _creating_account = false
    _update_button_state()
