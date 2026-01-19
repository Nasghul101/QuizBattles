# Proposal: Add Account Registration Screen Logic

## Overview
Implement interactive validation and account creation logic for the existing `account_registration_screen.tscn` scene. The screen will allow players to create accounts by entering a username, password (with confirmation), and email address.

## Problem Statement
The account registration screen scene exists but has no logic. Players need a way to create accounts with proper validation to ensure data quality and prevent duplicate usernames.

## Proposed Solution
Add a GDScript controller (`account_registration_screen.gd`) that:
- Monitors all 4 text input fields and enables the Create Account button only when all fields have content
- Validates password match, email format, and username uniqueness when Create Account is pressed
- Disables the button after failed username duplicate check until the username is edited again
- Logs success or error messages to console without interrupting gameplay
- Integrates with the existing `UserDatabase` autoload for account creation

## Scope
### In Scope
- Enable/disable logic for CreateAccountButton based on field content
- Password confirmation matching validation
- Email format validation using existing UserDatabase rules
- Duplicate username detection using UserDatabase
- Console logging for success/error feedback
- Re-enable button when username field is edited after duplicate error

### Out of Scope
- Visual error messages or UI feedback (console only)
- Password visibility toggle
- Password strength requirements
- Navigation logic for Back button
- Auto sign-in after registration
- Screen transitions after successful registration
- Real-time validation as user types (validation only on button press)

## Dependencies
- Existing `UserDatabase` autoload (no changes needed)
- Existing `account_registration_screen.tscn` scene with nodes:
  - NameInput (TextEdit)
  - PasswordInput (TextEdit)
  - PasswordConfirm (TextEdit)
  - EmailInput (TextEdit)
  - CreateAccountButton (Button)
  - BackButton (Button)

## Impact Assessment
- **Complexity**: Low - straightforward UI logic calling existing database methods
- **Risk**: Low - isolated to one screen, no changes to existing systems
- **Testing**: Manual testing of validation rules and button states

## Success Criteria
- CreateAccountButton is disabled until all 4 fields have content
- Button press validates all requirements before calling UserDatabase
- Successful registration logs account details to console
- Duplicate username error disables button until username is modified
- All validation errors are logged to console
