# register-login-screen Specification Delta

## ADDED Requirements

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
