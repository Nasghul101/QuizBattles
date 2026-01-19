extends Control

## Account Registration Screen Controller
##
## Handles user input validation and account creation for new user registration.
## Monitors input fields and enables the Create Account button only when all fields
## are filled. Validates password match, email format, and username uniqueness
## when the button is pressed.

## Reference to the username input field
@onready var name_input: TextEdit = $VBoxContainer/NameInput

## Reference to the password input field
@onready var password_input: TextEdit = $VBoxContainer/PasswordInput

## Reference to the password confirmation input field
@onready var password_confirm: TextEdit = $VBoxContainer/PasswordConfirm

## Reference to the email input field
@onready var email_input: TextEdit = $VBoxContainer/EmailInput

## Reference to the Create Account button
@onready var create_account_button: Button = $VBoxContainer/CreateAccountButton

## Reference to the Back button (no functionality implemented)
@onready var back_button: Button = $BackButton

## Flag to track if account creation failed due to duplicate username
var _duplicate_username_error: bool = false


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
    
    # Connect button pressed signal
    create_account_button.pressed.connect(_on_create_account_button_pressed)


## Called when any input field text changes
func _on_input_field_changed() -> void:
    # Enable button only if all fields have content and no duplicate username error
    _update_button_state()


## Called specifically when the username field changes
func _on_name_input_changed() -> void:
    # If there was a duplicate username error, clear it when username is edited
    if _duplicate_username_error:
        _duplicate_username_error = false


## Update the Create Account button enabled/disabled state
func _update_button_state() -> void:
    var all_fields_filled := (
        not name_input.text.strip_edges().is_empty() and
        not password_input.text.strip_edges().is_empty() and
        not password_confirm.text.strip_edges().is_empty() and
        not email_input.text.strip_edges().is_empty()
    )
    
    # Disable if duplicate username error flag is set
    create_account_button.disabled = not all_fields_filled or _duplicate_username_error


## Handle Create Account button press
func _on_create_account_button_pressed() -> void:
    var username := name_input.text.strip_edges()
    var password := password_input.text
    var password_confirm_text := password_confirm.text
    var email := email_input.text.strip_edges()
    
    # Validate password match
    if password != password_confirm_text:
        print("ERROR: Passwords do not match")
        return
    
    # Attempt to create user account
    var result := UserDatabase.create_user(username, password, email)
    
    if result.success:
        # Success - log the created user data
        print("Account created successfully: ", result.user)
    else:
        # Error - log the error message
        print("ERROR: ", result.message)
        
        # If duplicate username error, set flag and disable button
        if result.error_code == "USERNAME_EXISTS":
            _duplicate_username_error = true
            _update_button_state()
