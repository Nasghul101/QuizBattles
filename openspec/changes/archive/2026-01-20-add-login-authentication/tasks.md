# Implementation Tasks: Add Login Authentication

## Task Breakdown

### 1. Update register_login_screen.gd with input validation
- [x] Add @onready references to UsernameInput and PasswordInput TextEdit nodes
- [x] Add @onready reference to LogInButton Button node
- [x] Add `_login_failed` flag to track authentication failure state
- [x] Implement `_ready()` to initialize button as disabled and connect text_changed signals
- [x] Implement `_on_input_field_changed()` to update button state when any field changes
- [x] Implement `_on_username_input_changed()` to clear error flag when username is edited
- [x] Implement `_update_button_state()` to enable/disable button based on field content and error flag
- [x] **Validation**: Run game, verify button is disabled on load

### 2. Implement login authentication logic
- [x] Implement `_on_log_in_button_pressed()` to:
  - Get username and password from input fields (strip edges on username)
  - Call `UserDatabase.sign_in(username, password)`
  - On success: Call `_navigate_to_account_management_after_login()`
  - On failure: Log error message, set `_login_failed` flag, call `_update_button_state()`
- [x] **Validation**: Test successful login, verify navigation to account management
- [x] **Validation**: Test failed login (wrong password), verify console error and button disabled
- [x] **Validation**: Edit input after failure, verify button re-enables

### 3. Update main_lobby_screen.gd for dynamic login state
- [x] Remove `_is_user_logged_in` cached variable
- [x] Update `_ready()` to remove login state caching
- [x] Update `_on_account_button_pressed()` to call `UserDatabase.is_signed_in()` directly instead of using cached value
- [x] **Validation**: Log out, click Account button, verify navigates to register/login screen
- [x] **Validation**: Log in, return to lobby, click Account button, verify navigates to account management

### 4. Integration testing
- [ ] Test full flow: Start game → Register account → Logout → Login with same credentials → Navigate to account management
- [ ] Test error recovery: Attempt login with wrong password → Edit input → Retry with correct password
- [ ] Test button enablement: Clear fields → Type in username only → Verify button disabled → Type in password → Verify button enabled
- [ ] **Validation**: All scenarios work as expected

## Dependencies

- Task 1 must complete before Task 2 (need references and button state logic)
- Task 3 can be done in parallel with Tasks 1-2
- Task 4 requires all previous tasks complete

## Estimated Effort

- Task 1: ~15 minutes
- Task 2: ~20 minutes  
- Task 3: ~10 minutes
- Task 4: ~15 minutes
- **Total**: ~60 minutes
