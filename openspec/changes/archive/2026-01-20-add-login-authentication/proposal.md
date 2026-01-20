# Change Proposal: Add Login Authentication

**Change ID:** `add-login-authentication`  
**Date:** 2026-01-20  
**Status:** Draft

## Overview

Enable user login functionality in the register/login screen with input validation, authentication against UserDatabase, and proper navigation flow. Update main lobby to dynamically check login state instead of caching it.

## Problem Statement

Currently, the register/login screen has a non-functional login button and the main lobby screen caches login state on initialization, which doesn't reflect login changes. Users cannot authenticate with their registered accounts, and the navigation flow doesn't respond to login state changes.

## Proposed Solution

1. **Input-driven button enablement**: Enable LogInButton only when both username and password fields contain text, with real-time updates as users type (matching registration screen pattern)

2. **Authentication logic**: Implement login using `UserDatabase.sign_in()` with proper error handling:
   - On success: Navigate to account management screen
   - On failure: Disable button until input changes, log error to console

3. **Dynamic login state checking**: Update main lobby to query `UserDatabase.is_signed_in()` dynamically instead of caching the value in `_ready()`

## Affected Components

- **register-login-screen**: Add input validation, authentication flow, and error handling
- **main-lobby-screen**: Replace cached login state with dynamic database queries

## User Impact

Users will be able to:
- Log into their registered accounts from the login screen
- See immediate visual feedback (button enabled/disabled) based on input state
- Navigate directly to account management after successful login
- See account management when clicking Account button if already logged in
- Retry login attempts after failures by editing input fields

## Dependencies

- Requires existing UserDatabase service with `sign_in()` and `is_signed_in()` methods (already implemented)
- Requires TransitionManager for navigation (already implemented)
- Requires account_management_screen for post-login navigation (already implemented)

## Risks and Considerations

- **Session persistence**: Login only persists for current game session (in-memory). Future work will add persistent sessions
- **Error visibility**: Errors logged to console only, no UI error labels (matches registration screen pattern)
- **Security**: No rate limiting or lockout for failed attempts in this change
- **Password visibility**: Password field not masked (plain text visible)

## Alternatives Considered

1. **Cache login state with signals**: Could use signals from UserDatabase to update cached state in screens
   - Rejected: Direct queries to database are simpler and more explicit for this use case

2. **Visual error messages**: Could add error labels to UI
   - Rejected: Keeping consistency with registration screen pattern (console-only errors)

3. **Password masking**: Could make password field secret/masked
   - Rejected: Not required for initial implementation, can be added later

## Success Criteria

- [ ] LogInButton is disabled when fields are empty
- [ ] LogInButton is enabled when both fields have text
- [ ] Button state updates in real-time as user types
- [ ] Successful login navigates to account management screen
- [ ] Failed login logs error to console and disables button
- [ ] Button re-enables when user modifies input after failure
- [ ] Main lobby Account button navigates based on current login state
- [ ] Login state persists during current session until sign out
