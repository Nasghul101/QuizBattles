# account-registration-screen Specification

## Purpose
TBD - created by archiving change add-account-registration-screen-logic. Update Purpose after archive.
## Requirements
### Requirement: Enable Create Account Button Based on Field Content
The CreateAccountButton SHALL be enabled only when all 4 input fields (username, password, password confirmation, email) contain text.

**Rationale:** Prevent submission of incomplete forms and provide clear visual feedback about readiness.

#### Scenario: Button disabled with empty fields
**Given** the account registration screen is displayed  
**And** at least one input field is empty  
**When** the user views the CreateAccountButton  
**Then** the button is disabled (not pressable)

#### Scenario: Button enabled with all fields filled
**Given** the account registration screen is displayed  
**And** NameInput contains "Player123"  
**And** PasswordInput contains "mypassword"  
**And** PasswordConfirm contains "mypassword"  
**And** EmailInput contains "player@example.com"  
**When** the user views the CreateAccountButton  
**Then** the button is enabled (pressable)

#### Scenario: Button updates in real-time as user types
**Given** all fields are filled and the button is enabled  
**When** the user clears the NameInput field  
**Then** the CreateAccountButton becomes disabled immediately

---

### Requirement: Validate Password Confirmation on Submit
The system SHALL verify that password and password confirmation fields match when CreateAccountButton is pressed.

**Rationale:** Prevent account creation with mistyped passwords.

#### Scenario: Reject mismatched passwords
**Given** the account registration screen has all fields filled  
**And** PasswordInput contains "password123"  
**And** PasswordConfirm contains "differentpassword"  
**When** the user presses CreateAccountButton  
**Then** no account is created  
**And** an error message is logged to console: "Passwords do not match"

#### Scenario: Accept matched passwords
**Given** the account registration screen has all fields filled  
**And** PasswordInput contains "password123"  
**And** PasswordConfirm contains "password123"  
**And** all other validations pass  
**When** the user presses CreateAccountButton  
**Then** password validation succeeds and account creation proceeds

---

### Requirement: Validate Email Format on Submit
The system SHALL verify email format using UserDatabase validation rules when CreateAccountButton is pressed.

**Rationale:** Ensure email addresses meet basic format requirements before storage.

#### Scenario: Reject invalid email format
**Given** the account registration screen has all fields filled  
**And** EmailInput contains "notanemail"  
**When** the user presses CreateAccountButton  
**Then** no account is created  
**And** an error message is logged to console with the UserDatabase error message

#### Scenario: Accept valid email format
**Given** the account registration screen has all fields filled  
**And** EmailInput contains "player@example.com"  
**And** all other validations pass  
**When** the user presses CreateAccountButton  
**Then** email validation succeeds and account creation proceeds

---

### Requirement: Check Username Uniqueness on Submit
The system SHALL check if the username already exists in UserDatabase when CreateAccountButton is pressed.

**Rationale:** Prevent duplicate usernames and maintain unique player identities.

#### Scenario: Reject duplicate username
**Given** a user already exists with username "Player123"  
**And** the account registration screen has all fields filled with username "Player123"  
**When** the user presses CreateAccountButton  
**Then** no account is created  
**And** an error message is logged to console: "Username already exists"  
**And** the CreateAccountButton is disabled

#### Scenario: Accept unique username
**Given** no user exists with username "NewPlayer"  
**And** the account registration screen has all fields filled with username "NewPlayer"  
**And** all other validations pass  
**When** the user presses CreateAccountButton  
**Then** username validation succeeds and account creation proceeds

---

### Requirement: Re-enable Button After Username Edit
The system SHALL re-enable the CreateAccountButton when the NameInput field is edited after a duplicate username error.

**Rationale:** Allow users to correct the duplicate username and retry registration without refreshing the screen.

#### Scenario: Re-enable button when username is edited
**Given** account creation failed with "Username already exists" error  
**And** the CreateAccountButton is disabled  
**When** the user modifies the NameInput field  
**And** all 4 fields still contain text  
**Then** the CreateAccountButton becomes enabled again

#### Scenario: Button remains disabled if username not edited
**Given** account creation failed with "Username already exists" error  
**And** the CreateAccountButton is disabled  
**When** the user modifies the PasswordInput field  
**Then** the CreateAccountButton remains disabled until NameInput is edited

---

### Requirement: Create Account on Successful Validation
The system SHALL call UserDatabase.create_user() and log the result when all validations pass.

**Rationale:** Complete the registration process and provide feedback without interrupting gameplay.

#### Scenario: Successful account creation
**Given** all input fields are valid  
**And** username "NewPlayer" does not exist  
**And** email "new@example.com" is valid format  
**And** passwords match  
**When** the user presses CreateAccountButton  
**Then** `UserDatabase.create_user("NewPlayer", password, "new@example.com")` is called  
**And** the returned user data is logged to console  
**And** no screen transition occurs

#### Scenario: Log database errors
**Given** all local validations pass  
**When** the user presses CreateAccountButton  
**And** UserDatabase returns an error (e.g., EMAIL_EXISTS)  
**Then** the error message is logged to console  
**And** no account is created

---

### Requirement: Console-Only Error Feedback
The system SHALL log all validation errors and success messages to console without displaying UI notifications.

**Rationale:** Maintain simple implementation while providing developer visibility during testing.

#### Scenario: Log validation errors to console
**Given** the user attempts to create an account  
**When** any validation fails  
**Then** the error message is printed to console using `print()` or `push_error()`  
**And** no UI popup or error label is displayed  
**And** gameplay is not interrupted

---

### Requirement: Back Button Has No Functionality
The BackButton SHALL have no connected logic or behavior.

**Rationale:** Navigation logic is deferred to future implementation.

#### Scenario: Back button does nothing
**Given** the account registration screen is displayed  
**When** the user presses the BackButton  
**Then** no action occurs  
**And** the screen remains on account registration

---

