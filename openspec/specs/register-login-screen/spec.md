# register-login-screen Specification

## Purpose
Defines navigation and interaction behavior for the registration and login screen.

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
The LogInButton SHALL be enabled only when both the email and password input fields contain text.

**Rationale:** Prevent sign-in attempts with incomplete credentials and provide clear visual feedback about form readiness.

#### Scenario: Button disabled with empty fields
- **GIVEN** the register/login screen is displayed and at least one input field is empty
- **WHEN** the user views the LogInButton
- **THEN** the button is disabled

#### Scenario: Button enabled with both fields filled
- **GIVEN** EmailInput contains `player@example.com` and PasswordInput contains a password
- **WHEN** the user views the LogInButton
- **THEN** the button is enabled

#### Scenario: Button updates in real time
- **GIVEN** both fields are filled and the button is enabled
- **WHEN** the user clears either field
- **THEN** the LogInButton becomes disabled immediately

#### Scenario: Button updates in real-time as user types
- **GIVEN** the button is enabled
- **WHEN** the user clears and then refills either email or password
- **THEN** the button's enabled state updates immediately based on both fields

### Requirement: Authenticate User on Login Button Press
The system SHALL authenticate the supplied email and password through Firebase Authentication when LogInButton is pressed. After successful authentication, it SHALL load the Firestore profile, persist the Firebase Auth session using the plugin's encrypted auth-file support, and navigate to account management.

**Rationale:** Authenticate through the configured Firebase provider and restore a valid session without keeping the user's password in the device cache.

**Constraints:**
- Authentication and profile loading are asynchronous
- Authentication or profile-loading failures are logged and surfaced to the caller without creating a signed-in session
- Successful login SHALL NOT call `LocalCache.remember_login()` or persist the password

#### Scenario: Successful login with valid credentials
- **GIVEN** an Auth account and Firestore profile exist for the supplied email
- **WHEN** the user presses LogInButton
- **THEN** Firebase Authentication verifies the credentials
- **AND** the profile is loaded into the current user session
- **AND** the Firebase Auth session is saved locally without storing the password
- **AND** the screen transitions to account management

#### Scenario: Failed login with invalid credentials
- **GIVEN** Firebase Authentication rejects the supplied email or password
- **WHEN** the user presses LogInButton
- **THEN** an authentication error is logged
- **AND** no session is established and no Auth session file is saved

#### Scenario: Failed login with non-existent user
- **GIVEN** no Firebase Auth account exists for the supplied email
- **WHEN** the user presses LogInButton
- **THEN** Firebase Auth returns a failed sign-in result
- **AND** an error is logged, the button is disabled, and no session is saved

#### Scenario: Failed login with incorrect password
- **GIVEN** a Firebase Auth account exists for the supplied email
- **WHEN** the user submits an incorrect password
- **THEN** Firebase Auth returns a failed sign-in result
- **AND** an error is logged, the button is disabled, and no session is saved

#### Scenario: Failed profile load
- **GIVEN** Auth succeeds but the corresponding Firestore profile cannot be loaded
- **WHEN** the login operation completes
- **THEN** login is not reported as successful
- **AND** the Firestore failure is surfaced

### Requirement: Re-enable Button After Login Failure
The system SHALL re-enable the LogInButton when either the email or password field is edited after a failed login attempt, provided both fields contain text.

**Rationale:** Allow users to correct credentials and retry without navigating away.

#### Scenario: Re-enable after editing email
- **GIVEN** login failed and both fields contain text
- **WHEN** the user edits the email field
- **THEN** the LogInButton becomes enabled

#### Scenario: Re-enable button after editing username following failure
- **GIVEN** login failed and both fields contain text
- **WHEN** the user edits the email field
- **THEN** the LogInButton becomes enabled

#### Scenario: Re-enable after editing password
- **GIVEN** login failed and both fields contain text
- **WHEN** the user edits the password field
- **THEN** the LogInButton becomes enabled

#### Scenario: Re-enable button after editing password following failure
- **GIVEN** login failed and both fields contain text
- **WHEN** the user edits the password field
- **THEN** the LogInButton becomes enabled

#### Scenario: Keep button disabled when a field is empty
- **GIVEN** login failed
- **WHEN** the user edits a field but either email or password remains empty
- **THEN** the LogInButton remains disabled

#### Scenario: Button remains disabled if fields are empty after edit
- **GIVEN** login failed
- **WHEN** the user edits a field while the other required field remains empty
- **THEN** the LogInButton remains disabled
