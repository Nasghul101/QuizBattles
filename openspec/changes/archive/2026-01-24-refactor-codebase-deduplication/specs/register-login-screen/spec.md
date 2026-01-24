# Register/Login Screen - Deduplication Changes

## MODIFIED Requirements

### Requirement: Navigation Implementation
The register/login screen SHALL use NavigationUtils.navigate_to_scene() for all scene navigation instead of private helper methods to eliminate code duplication.

#### Scenario: Navigate back to main lobby
**Given** the user is on the register/login screen  
**When** the Back button is pressed  
**Then** the screen calls NavigationUtils.navigate_to_scene("main_lobby")  
**And** transitions to the main lobby identically to previous behavior

#### Scenario: Navigate to account registration
**Given** the user presses the New Account button  
**When** _on_new_account_button_pressed() executes  
**Then** the screen calls NavigationUtils.navigate_to_scene("account_registration", "main_lobby")  
**And** transitions to the registration screen with main lobby as fallback

#### Scenario: Navigate to account management after login
**Given** the user successfully logs in  
**When** _on_log_in_button_pressed() completes authentication  
**Then** the screen calls NavigationUtils.navigate_to_scene("account_management", "register_login")  
**And** transitions to account management with register/login as fallback

## REMOVED Requirements

### Requirement: Private Navigation Helpers
~~The register/login screen SHALL implement private navigation helper methods (_navigate_to_main_lobby, _navigate_to_account_registration, _navigate_to_account_management_after_login) that validate scene paths and call TransitionManager.~~

**Rationale:** This functionality is now provided by NavigationUtils autoload.
