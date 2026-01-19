# Tasks: Add Local User Database

## Implementation Order

### 1. Create UserDatabase Autoload Script
- [x] Create `autoload/user_database.gd` script
- [x] Define user data structure (Dictionary with username, password_hash, email)
- [x] Create in-memory storage (Dictionary mapping usernames to user data)
- [x] Register as autoload singleton in `project.godot`

### 2. Implement Input Validation Functions
- [x] Create `_validate_email(email: String) -> Dictionary` helper
  - Check for `@` symbol
  - Check for valid TLD (.com, .de, .org, .net, etc.)
  - Return success or error code
- [x] Create `_validate_username(username: String) -> Dictionary` helper
  - Check length (5-15 characters)
  - Return success or error code
- [x] Create `_hash_password(password: String) -> String` helper
  - Use Godot's `Crypto.generate_random_bytes()` for salt
  - Hash with SHA-256
  - Return hex-encoded hash

### 3. Implement User Registration
- [x] Create `create_user(username: String, password: String, email: String) -> Dictionary` method
- [x] Validate username (call `_validate_username`)
- [x] Validate email (call `_validate_email`)
- [x] Check for duplicate username (return "USERNAME_EXISTS" error)
- [x] Check for duplicate email (return "EMAIL_EXISTS" error)
- [x] Hash password and store user data
- [x] Return success result with user data

### 4. Implement User Authentication
- [x] Create `sign_in(username: String, password: String) -> Dictionary` method
- [x] Check if username exists (return "USER_NOT_FOUND" error)
- [x] Verify password hash matches (return "INVALID_PASSWORD" error)
- [x] Set current user on success
- [x] Return success result with user data
- [x] Create `sign_out() -> void` method to clear current user

### 5. Implement Session Management
- [x] Add `current_user: Dictionary` variable to track logged-in user
- [x] Create `get_current_user() -> Dictionary` method
- [x] Create `is_signed_in() -> bool` helper method

### 6. Implement Utility Methods
- [x] Create `user_exists(username: String) -> bool` method
- [x] Create `email_exists(email: String) -> bool` method
- [x] Create `get_user_by_username(username: String) -> Dictionary` method (returns empty dict if not found)

### 7. Add Documentation
- [x] Add class-level documentation comment explaining purpose and Firebase compatibility
- [x] Add function documentation for all public methods
- [x] Document error codes and return value structures
- [x] Add inline comments for complex validation logic

### 8. Testing Validation
- [x] Manual test: Register new user with valid data
- [x] Manual test: Reject duplicate username
- [x] Manual test: Reject duplicate email
- [x] Manual test: Reject invalid email format
- [x] Manual test: Reject username too short/long
- [x] Manual test: Sign in with correct credentials
- [x] Manual test: Reject incorrect password
- [x] Manual test: Reject non-existent user
- [x] Manual test: Track current user after sign in
- [x] Manual test: Clear current user after sign out

## Dependencies
None - This is standalone functionality

## Validation Checklist
- [x] All methods follow Firebase Auth naming conventions
- [x] Error codes match Firebase Auth patterns (uppercase with underscores)
- [x] Return values are consistent (Dictionary with `success`, `error_code`, and optional `user` or `message`)
- [x] Passwords are hashed, never stored in plain text
- [x] Code follows GDScript style guide
- [x] Documentation comments use `##` syntax
- [x] All public methods are documented
- [x] No hardcoded values (TLDs defined in constant array)
