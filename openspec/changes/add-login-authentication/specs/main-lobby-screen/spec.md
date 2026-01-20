# main-lobby-screen Spec Delta

## MODIFIED Requirements

### Requirement: Conditional AccountButton Navigation
The main lobby SHALL query UserDatabase.is_signed_in() dynamically when AccountButton is pressed to determine navigation target.

**Rationale:** Ensure navigation accurately reflects current login state, including changes from login/logout actions during the session.

**Changes from previous version:**
- Previously cached login state in `_ready()` which didn't reflect login state changes
- Now queries UserDatabase directly on each button press for accurate state

#### Scenario: Navigate to account management when logged in
**Given** the user is on the main lobby screen  
**And** UserDatabase.is_signed_in() returns true  
**When** the AccountButton is pressed  
**Then** the screen queries UserDatabase.is_signed_in()  
**And** the screen transitions to `res://scenes/ui/account_ui/account_management_screen.tscn`

#### Scenario: Navigate to register/login when not logged in
**Given** the user is on the main lobby screen  
**And** UserDatabase.is_signed_in() returns false  
**When** the AccountButton is pressed  
**Then** the screen queries UserDatabase.is_signed_in()  
**And** the screen transitions to `res://scenes/ui/account_ui/register_login_screen.tscn`

#### Scenario: Reflect login state changes during session
**Given** the user was not logged in when entering main lobby  
**And** the user navigates to register/login screen and successfully logs in  
**And** the user returns to main lobby  
**When** the AccountButton is pressed  
**Then** the screen queries UserDatabase.is_signed_in() and gets true  
**And** the screen transitions to account_management_screen (not register/login)
