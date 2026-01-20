# register-login-screen Spec Delta

## ADDED Requirements

### Requirement: Enable Login Button Based on Input Field Content
The LogInButton SHALL be enabled only when both username and password input fields contain text.

**Rationale:** Prevent login attempts with incomplete credentials and provide clear visual feedback about form readiness.

#### Scenario: Button disabled with empty fields
**Given** the register/login screen is displayed  
**And** at least one input field is empty  
**When** the user views the LogInButton  
**Then** the button is disabled (not pressable)

#### Scenario: Button enabled with both fields filled
**Given** the register/login screen is displayed  
**And** UsernameInput contains "Player123"  
**And** PasswordInput contains "password123"  
**When** the user views the LogInButton  
**Then** the button is enabled (pressable)

#### Scenario: Button updates in real-time as user types
**Given** both fields are filled and the button is enabled  
**When** the user clears the UsernameInput field  
**Then** the LogInButton becomes disabled immediately  
**And** when the user types text back into UsernameInput  
**Then** the LogInButton becomes enabled again

---

### Requirement: Authenticate User on Login Button Press
The system SHALL authenticate user credentials using UserDatabase when LogInButton is pressed.

**Rationale:** Allow registered users to log into their accounts and access authenticated features.

**Constraints:**
- Login state persists only for current game session (in-memory)
- Authentication errors are logged to console only (no UI error display)

#### Scenario: Successful login with valid credentials
**Given** a user exists with username "Player123" and password "password123"  
**And** the register/login screen has UsernameInput "Player123" and PasswordInput "password123"  
**When** the user presses LogInButton  
**Then** UserDatabase.sign_in() is called with the provided credentials  
**And** the user session is set in UserDatabase  
**And** the screen transitions to account_management_screen using TransitionManager

#### Scenario: Failed login with non-existent user
**Given** no user exists with username "Ghost"  
**And** the register/login screen has UsernameInput "Ghost" and PasswordInput "anypassword"  
**When** the user presses LogInButton  
**Then** UserDatabase.sign_in() returns failure with error_code "USER_NOT_FOUND"  
**And** an error message is logged to console  
**And** the LogInButton is disabled

#### Scenario: Failed login with incorrect password
**Given** a user exists with username "Player123" and password "password123"  
**And** the register/login screen has UsernameInput "Player123" and PasswordInput "wrongpassword"  
**When** the user presses LogInButton  
**Then** UserDatabase.sign_in() returns failure with error_code "INVALID_PASSWORD"  
**And** an error message is logged to console: "ERROR: Password is incorrect"  
**And** the LogInButton is disabled

---

### Requirement: Re-enable Button After Login Failure
The system SHALL re-enable the LogInButton when either input field is edited after a failed login attempt.

**Rationale:** Allow users to correct their credentials and retry login without navigation away from the screen.

#### Scenario: Re-enable button after editing username following failure
**Given** login failed and LogInButton is disabled  
**When** the user modifies the UsernameInput field  
**And** both fields contain text  
**Then** the LogInButton becomes enabled

#### Scenario: Re-enable button after editing password following failure
**Given** login failed and LogInButton is disabled  
**When** the user modifies the PasswordInput field  
**And** both fields contain text  
**Then** the LogInButton becomes enabled

#### Scenario: Button remains disabled if fields are empty after edit
**Given** login failed and LogInButton is disabled  
**When** the user clears the UsernameInput field  
**Then** the LogInButton remains disabled
