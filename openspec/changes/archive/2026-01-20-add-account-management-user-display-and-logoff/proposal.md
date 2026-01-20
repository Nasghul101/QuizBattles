# Proposal: Add Account Management User Display and Logoff

## Metadata
- **Change ID**: `add-account-management-user-display-and-logoff`
- **Created**: 2026-01-20
- **Status**: Draft
- **Type**: Feature Addition

## Problem Statement
The account management screen currently lacks essential functionality to display the logged-in user's information and provide a way to log out. Users cannot see which account they are currently using, nor can they log out from the application.

## Proposed Solution
Add functionality to the account management screen to:
1. Display the current user's username in the NameLabel when the screen loads
2. Provide a LogOffButton that logs out the user and returns them to the register/login screen

The implementation will:
- Query `UserDatabase.current_user` to retrieve the username
- Use the existing label text as fallback if no user is found (though this should not occur in normal flow)
- Call `UserDatabase.sign_out()` when the LogOffButton is pressed
- Transition to `register_login_screen.tscn` after logout using TransitionManager
- Log a console message confirming the logout action

## Scope
**In scope:**
- Display username from UserDatabase in NameLabel on screen load
- Connect LogOffButton to logout functionality
- Handle logout and screen transition to register_login_screen
- Console logging for logout action

**Out of scope:**
- Logout confirmation dialogs
- Additional account information display (email, profile picture, etc.)
- Error handling for non-existent users (fallback text already present)

## Dependencies
**Existing capabilities:**
- `local-user-database` - Provides `current_user`, `sign_out()` method
- `scene-transition-manager` - Provides scene transition with fade effects
- `account-management-screen` - Base screen implementation with BackButton navigation

**No new external dependencies required.**

## Affected Specifications
- `account-management-screen` - Add username display and logout requirements

## User Impact
**Positive:**
- Users can see which account they are logged into
- Users can log out from their account
- Clear feedback via console for logout action

**Breaking changes:** None

## Implementation Notes
- The NameLabel node must be accessible via `$VBoxContainer/NameLabel`
- LogOffButton node must be accessible via `$VBoxContainer/LogOffButton`
- Console message format: "User [username] logged out" or similar
- No async operations required - all actions are synchronous
