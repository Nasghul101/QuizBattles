# register-login-screen Specification

## Purpose
TBD - created by archiving change add-account-screen-navigation. Update Purpose after archive.

## Requirements

### Requirement: Back Navigation to Main Lobby
The register/login screen SHALL provide navigation back to the main lobby screen.

**Rationale:** Allow users to return to the main lobby without completing login or registration.

#### Scenario: Navigate back to main lobby
**GIVEN** the user is on the register/login screen  
**WHEN** the BackButton is pressed  
**THEN** the screen SHALL transition to `res://scenes/ui/main_lobby_screen.tscn` using TransitionManager  
**AND** the transition SHALL include fade effects

---

### Requirement: Navigation to Account Registration
The register/login screen SHALL provide navigation to the account registration screen.

**Rationale:** Enable new users to create accounts from the login screen.

#### Scenario: Navigate to account registration
**GIVEN** the user is on the register/login screen  
**WHEN** the NewAccountButton is pressed  
**THEN** the screen SHALL transition to `res://scenes/ui/account_ui/account_registration_screen.tscn` using TransitionManager  
**AND** the transition SHALL include fade effects

---

### Requirement: Post-Login Navigation to Account Management
The register/login screen SHALL navigate to the account management screen after successful user authentication.

**Rationale:** Provide seamless transition to account features after login.

**Constraints:**
- This requirement defines the navigation target only
- Login logic implementation is out of scope for this change

#### Scenario: Navigate to account management after login success
**GIVEN** the user successfully logs in  
**WHEN** the login operation completes  
**THEN** the screen SHALL transition to `res://scenes/ui/account_ui/account_management_screen.tscn` using TransitionManager  
**AND** the transition SHALL include fade effects

---

### Requirement: Navigation Error Handling
The register/login screen SHALL handle navigation failures gracefully by returning to the main lobby.

**Rationale:** Ensure users can recover from navigation errors and have a safe fallback screen.

#### Scenario: Handle transition failure and return to main lobby
**GIVEN** a scene transition is initiated  
**WHEN** the transition fails (e.g., scene path not found)  
**THEN** the screen SHALL log an error to the console using `push_error()`  
**AND** the screen SHALL transition back to `res://scenes/ui/main_lobby_screen.tscn`  
**AND** the fallback transition SHALL use TransitionManager with fade effects

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
The system SHALL authenticate user credentials using UserDatabase when LogInButton is pressed, and SHALL remember the credentials in the local device cache on success so future launches can auto sign-in.

**Rationale:** Allow registered users to log into their accounts and access authenticated features, and let the device remember them for next time.

**Constraints:**
- Login state persists only for current game session (in-memory) beyond what the local device cache remembers
- Authentication errors are logged to console only (no UI error display)
- Successful login SHALL call `LocalCache.remember_login(username, password)` with the exact credentials that were used to sign in

**Cross-reference:** Uses `local-device-cache.remember_login()`.

#### Scenario: Successful login with valid credentials
**Given** a user exists with username "Player123" and password "password123"  
**And** the register/login screen has UsernameInput "Player123" and PasswordInput "password123"  
**When** the user presses LogInButton  
**Then** UserDatabase.sign_in() is called with the provided credentials  
**And** the user session is set in UserDatabase  
**And** `LocalCache.remember_login("Player123", "password123")` is called  
**And** the screen transitions to account_management_screen using TransitionManager

#### Scenario: Failed login with non-existent user
**Given** no user exists with username "Ghost"  
**And** the register/login screen has UsernameInput "Ghost" and PasswordInput "anypassword"  
**When** the user presses LogInButton  
**Then** UserDatabase.sign_in() returns failure with error_code "USER_NOT_FOUND"  
**And** an error message is logged to console  
**And** the LogInButton is disabled  
**And** `LocalCache.remember_login()` is NOT called

#### Scenario: Failed login with incorrect password
**Given** a user exists with username "Player123" and password "password123"  
**And** the register/login screen has UsernameInput "Player123" and PasswordInput "wrongpassword"  
**When** the user presses LogInButton  
**Then** UserDatabase.sign_in() returns failure with error_code "INVALID_PASSWORD"  
**And** an error message is logged to console: "ERROR: Password is incorrect"  
**And** the LogInButton is disabled  
**And** `LocalCache.remember_login()` is NOT called

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
