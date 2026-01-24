# Account Registration Screen - Deduplication Changes

## MODIFIED Requirements

### Requirement: Navigation Implementation
The account registration screen SHALL use NavigationUtils.navigate_to_scene() for all scene navigation instead of private helper methods to eliminate code duplication.

#### Scenario: Navigate back to register/login screen
**Given** the user is on the account registration screen  
**When** the Back button is pressed  
**Then** the screen calls NavigationUtils.navigate_to_scene("register_login")  
**And** transitions back to register/login identically to previous behavior

#### Scenario: Navigate to account management after registration
**Given** the user successfully creates an account  
**And** automatic sign-in succeeds  
**When** _on_create_account_button_pressed() completes  
**Then** the screen calls NavigationUtils.navigate_to_scene("account_management", "register_login")  
**And** transitions to account management with register/login as fallback

## REMOVED Requirements

### Requirement: Private Navigation Helpers
~~The account registration screen SHALL implement private navigation helper methods (_navigate_to_register_login, _navigate_to_account_management) that validate scene paths and call TransitionManager.~~

**Rationale:** This functionality is now provided by NavigationUtils autoload.
