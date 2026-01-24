# Main Lobby Screen - Deduplication Changes

## MODIFIED Requirements

### Requirement: Navigation Implementation
The main lobby screen SHALL use NavigationUtils.navigate_to_scene() for all scene navigation instead of private helper methods to eliminate code duplication.

#### Scenario: Navigate to register/login screen
**Given** the user is not signed in  
**And** the user presses the Account button  
**When** _on_account_button_pressed() executes  
**Then** the screen calls NavigationUtils.navigate_to_scene("register_login")  
**And** transitions to the register/login screen identically to previous behavior

#### Scenario: Navigate to account management screen
**Given** the user is signed in  
**And** the user presses the Account button  
**When** _on_account_button_pressed() executes  
**Then** the screen calls NavigationUtils.navigate_to_scene("account_management")  
**And** transitions to the account management screen identically to previous behavior

## REMOVED Requirements

### Requirement: Private Navigation Helpers
~~The main lobby screen SHALL implement private navigation helper methods (_navigate_to_register_login, _navigate_to_account_management) that validate scene paths and call TransitionManager.~~

**Rationale:** This functionality is now provided by NavigationUtils autoload, eliminating duplication across multiple screens.

#### ~~Scenario: Private method path validation~~
**Removed** - validation now handled by NavigationUtils
