## MODIFIED Requirements

### Requirement: Log Off and Navigate to Main Lobby on Log Off Button Press
The account management screen SHALL sign out the current user, clear any remembered login in the local device cache, and navigate to the main lobby screen when the LogOffButton is pressed.

**Rationale:** Users need to log out of their account from the account management screen, and an explicit log off SHALL be respected on the next launch instead of being silently undone by auto sign-in.

**Cross-reference:** Uses `local-user-database.sign_out()` and `local-device-cache.forget_login()`.

#### Scenario: Log off button signs out and returns to main lobby
**Given** user "Player123" is logged in  
**And** the account management screen is visible  
**When** the user presses the LogOffButton  
**Then** the screen SHALL call `UserDatabase.sign_out()`  
**And** the current user session SHALL be cleared  
**And** the screen SHALL call `Utils.navigate_to_scene("main_lobby")`  
**And** the user SHALL be navigated to the main lobby screen as a guest

#### Scenario: Log off button also forgets the remembered login
**Given** user "Player123" is logged in  
**And** the account management screen is visible  
**When** the user presses the LogOffButton  
**Then** the screen SHALL call `LocalCache.forget_login()`  
**And** the local device cache's `remembered_login` SHALL be cleared

#### Scenario: Main lobby shows login screen after log off
**Given** user was logged in and pressed LogOffButton  
**When** the user presses the AccountButton on the main lobby  
**Then** the user SHALL be navigated to the register/login screen (not account management)  
**And** this verifies the log off was successful

#### Scenario: Logging off prevents auto sign-in on next launch
**Given** user "Player123" was logged in and had remembered credentials in the local device cache  
**When** the user presses the LogOffButton  
**And** the game is restarted  
**Then** the `LocalCache` autoload SHALL find `remembered_login: {}`  
**And** no automatic sign-in SHALL occur  
**And** the main lobby SHALL show the guest state
