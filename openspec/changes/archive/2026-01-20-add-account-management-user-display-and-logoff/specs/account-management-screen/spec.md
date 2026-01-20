# account-management-screen Spec Delta

## ADDED Requirements

### Requirement: Display Current User Username
The account management screen SHALL display the currently logged-in user's username in the NameLabel when the screen loads.

**Rationale:** Users need to see which account they are currently logged into for confirmation and context.

#### Scenario: Display username on screen load
**GIVEN** a user is logged in and the account management screen is loaded  
**WHEN** the screen's `_ready()` method executes  
**THEN** the screen SHALL query `UserDatabase.get_current_user()` to retrieve user data  
**AND** the NameLabel SHALL display the username from `current_user["username"]`

#### Scenario: Fallback when no user is logged in
**GIVEN** no user is logged in (empty current_user)  
**WHEN** the screen's `_ready()` method executes and attempts to display username  
**THEN** the NameLabel SHALL retain its existing text as fallback  
**AND** no error SHALL be raised

---

### Requirement: Log Off Functionality
The account management screen SHALL provide a LogOffButton that logs out the current user and returns to the login screen.

**Rationale:** Users need the ability to log out from their account to switch users or secure their session.

#### Scenario: User logs off successfully
**GIVEN** a user is logged in and on the account management screen  
**WHEN** the LogOffButton is pressed  
**THEN** the screen SHALL call `UserDatabase.sign_out()` to clear the user session  
**AND** the screen SHALL log a message to the console confirming logout with the username  
**AND** the screen SHALL transition to `res://scenes/ui/account_ui/register_login_screen.tscn` using TransitionManager  
**AND** the transition SHALL include fade effects

#### Scenario: Console logging on logout
**GIVEN** a user named "TestUser" is logged in  
**WHEN** the LogOffButton is pressed  
**THEN** a message SHALL be logged to the console indicating the user logged out  
**AND** the message SHALL include the username (e.g., "User TestUser logged out")
