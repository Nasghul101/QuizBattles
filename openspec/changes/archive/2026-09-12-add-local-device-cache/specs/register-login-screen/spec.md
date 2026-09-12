## MODIFIED Requirements

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
