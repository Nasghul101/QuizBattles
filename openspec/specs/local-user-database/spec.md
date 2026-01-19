# local-user-database Specification

## Purpose
TBD - created by archiving change add-local-user-database. Update Purpose after archive.
## Requirements
### Requirement: User Registration
The system SHALL allow creating new user accounts with username, password, and email.

**Rationale:** Enable players to create accounts for gameplay and progression tracking.

#### Scenario: Successful user registration
**Given** no user exists with username "Player123" or email "player@example.com"  
**When** `create_user("Player123", "password123", "player@example.com")` is called  
**Then** the user is created and stored in memory  
**And** the password is hashed using SHA-256  
**And** the method returns `{success: true, user: {username: "Player123", email: "player@example.com"}}`

---

### Requirement: Duplicate Username Detection
The system SHALL prevent registration of usernames that already exist.

**Rationale:** Ensure unique player identities and prevent account conflicts.

#### Scenario: Reject duplicate username
**Given** a user exists with username "Player123"  
**When** `create_user("Player123", "newpass", "different@example.com")` is called  
**Then** no new user is created  
**And** the method returns `{success: false, error_code: "USERNAME_EXISTS", message: "Username already exists"}`

---

### Requirement: Duplicate Email Detection
The system SHALL prevent registration of email addresses that already exist.

**Rationale:** Prevent multiple accounts with the same email and support future email-based features.

#### Scenario: Reject duplicate email
**Given** a user exists with email "player@example.com"  
**When** `create_user("NewPlayer", "password", "player@example.com")` is called  
**Then** no new user is created  
**And** the method returns `{success: false, error_code: "EMAIL_EXISTS", message: "Email already registered"}`

---

### Requirement: Email Format Validation
The system SHALL validate email addresses contain an `@` symbol and a valid top-level domain.

**Rationale:** Ensure email addresses are properly formatted before storage.

**Constraints:**
- Valid TLDs include: .com, .de, .org, .net, .edu, .gov, .co, .uk, .io, .app, .dev, .tech

#### Scenario: Reject invalid email format
**Given** the system is ready to create a user  
**When** `create_user("Player123", "password", "notanemail")` is called  
**Then** no user is created  
**And** the method returns `{success: false, error_code: "INVALID_EMAIL", message: "Email format is invalid"}`

#### Scenario: Accept valid email formats
**Given** the system is ready to create a user  
**When** `create_user("Player123", "password", "user@example.de")` is called  
**Then** the user is created successfully

---

### Requirement: Username Length Validation
The system SHALL enforce username length between 5 and 15 characters inclusive.

**Rationale:** Prevent usernames that are too short (hard to distinguish) or too long (display issues).

#### Scenario: Reject username too short
**Given** the system is ready to create a user  
**When** `create_user("ab", "password", "user@example.com")` is called  
**Then** no user is created  
**And** the method returns `{success: false, error_code: "USERNAME_TOO_SHORT", message: "Username must be at least 5 characters"}`

#### Scenario: Reject username too long
**Given** the system is ready to create a user  
**When** `create_user("ThisUsernameIsWayTooLong", "password", "user@example.com")` is called  
**Then** no user is created  
**And** the method returns `{success: false, error_code: "USERNAME_TOO_LONG", message: "Username must be at most 15 characters"}`

---

### Requirement: User Authentication
The system SHALL authenticate users with username and password credentials.

**Rationale:** Allow registered users to log into their accounts.

#### Scenario: Successful sign-in
**Given** a user exists with username "Player123" and password "password123"  
**When** `sign_in("Player123", "password123")` is called  
**Then** the user is authenticated  
**And** the current user session is set  
**And** the method returns `{success: true, user: {username: "Player123", email: "player@example.com"}}`

#### Scenario: Reject non-existent user
**Given** no user exists with username "Ghost"  
**When** `sign_in("Ghost", "password")` is called  
**Then** authentication fails  
**And** the method returns `{success: false, error_code: "USER_NOT_FOUND", message: "No user found with this username"}`

#### Scenario: Reject incorrect password
**Given** a user exists with username "Player123" and password "password123"  
**When** `sign_in("Player123", "wrongpassword")` is called  
**Then** authentication fails  
**And** the method returns `{success: false, error_code: "INVALID_PASSWORD", message: "Password is incorrect"}`

---

### Requirement: Session Management
The system SHALL track the currently logged-in user.

**Rationale:** Enable access to user information throughout the application.

#### Scenario: Track current user after sign-in
**Given** user "Player123" signs in successfully  
**When** `get_current_user()` is called  
**Then** it returns `{username: "Player123", email: "player@example.com"}`  
**And** `is_signed_in()` returns `true`

#### Scenario: Clear session on sign-out
**Given** user "Player123" is signed in  
**When** `sign_out()` is called  
**Then** `get_current_user()` returns an empty Dictionary  
**And** `is_signed_in()` returns `false`

---

### Requirement: Password Security
The system SHALL hash passwords using SHA-256 before storage and never store plain-text passwords.

**Rationale:** Protect user credentials even in temporary storage, following Firebase security practices.

#### Scenario: Hash password on registration
**Given** a user registers with password "mypassword"  
**When** the user data is stored  
**Then** the password field contains a SHA-256 hash  
**And** the plain-text password is not stored anywhere

#### Scenario: Verify hashed password on sign-in
**Given** a user registered with password "mypassword" (stored as hash)  
**When** `sign_in(username, "mypassword")` is called  
**Then** the provided password is hashed and compared to the stored hash  
**And** authentication succeeds if hashes match

---

### Requirement: Utility Methods
The system SHALL provide helper methods to check user and email existence.

**Rationale:** Enable UI components to provide real-time validation feedback.

#### Scenario: Check username availability
**Given** a user exists with username "Player123"  
**When** `user_exists("Player123")` is called  
**Then** it returns `true`  
**When** `user_exists("AvailableName")` is called  
**Then** it returns `false`

#### Scenario: Check email availability
**Given** a user exists with email "player@example.com"  
**When** `email_exists("player@example.com")` is called  
**Then** it returns `true`  
**When** `email_exists("available@example.com")` is called  
**Then** it returns `false`

---

