# Implementation Tasks

## 1. Main Lobby Screen Navigation
- [x] 1.1 Create `scenes/ui/main_lobby_screen.gd` script file
- [x] 1.2 Attach script to `main_lobby_screen.tscn` root node
- [x] 1.3 Implement `_ready()` to detect and cache user login state using `UserDatabase.is_signed_in()`
- [x] 1.4 Connect AccountButton `pressed` signal to handler method
- [x] 1.5 Implement conditional navigation logic in AccountButton handler (check cached login state)
- [x] 1.6 Add TransitionManager calls for navigation to register/login screen when not logged in
- [x] 1.7 Add TransitionManager calls for navigation to account management screen when logged in
- [x] 1.8 Implement error handling with `push_error()` for failed transitions

## 2. Register/Login Screen Navigation
- [x] 2.1 Create `scenes/ui/account_ui/register_login_screen.gd` script file (or add to existing if present)
- [x] 2.2 Attach script to `register_login_screen.tscn` root node
- [x] 2.3 Connect BackButton `pressed` signal to handler method
- [x] 2.4 Implement BackButton handler to transition to main lobby using TransitionManager
- [x] 2.5 Connect NewAccountButton `pressed` signal to handler method
- [x] 2.6 Implement NewAccountButton handler to transition to account registration screen using TransitionManager
- [x] 2.7 Add placeholder/stub for post-login navigation method (to be implemented in future change)
- [x] 2.8 Implement error handling with `push_error()` and fallback to main lobby for failed transitions

## 3. Account Management Screen Navigation
- [x] 3.1 Create `scenes/ui/account_ui/account_management_screen.gd` script file (or add to existing if present)
- [x] 3.2 Attach script to `account_management_screen.tscn` root node
- [x] 3.3 Connect BackButton `pressed` signal to handler method
- [x] 3.4 Implement BackButton handler to transition to main lobby using TransitionManager
- [x] 3.5 Implement error handling with `push_error()` and fallback to main lobby for failed transitions

## 4. Testing and Validation
- [ ] 4.1 Manual test: Start at main lobby when not logged in → press AccountButton → verify navigation to register/login screen
- [ ] 4.2 Manual test: From register/login screen → press BackButton → verify navigation to main lobby
- [ ] 4.3 Manual test: From register/login screen → press NewAccountButton → verify navigation to account registration screen
- [ ] 4.4 Manual test: Sign in with valid user → return to main lobby → press AccountButton → verify navigation to account management screen
- [ ] 4.5 Manual test: From account management screen → press BackButton → verify navigation to main lobby
- [ ] 4.6 Verify all transitions use fade effects (should take ~1 second)
- [ ] 4.7 Test error handling by temporarily breaking a scene path and verifying error logs and fallback behavior
