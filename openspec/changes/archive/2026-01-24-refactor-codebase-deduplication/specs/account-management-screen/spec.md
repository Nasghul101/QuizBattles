# Account Management Screen - Deduplication Changes

## MODIFIED Requirements

### Requirement: Navigation Implementation
The account management screen SHALL use NavigationUtils.navigate_to_scene() for all scene navigation instead of private helper methods to eliminate code duplication.

#### Scenario: Navigate back to main lobby
**Given** the user is on the account management screen  
**When** the Back button is pressed  
**Then** the screen calls NavigationUtils.navigate_to_scene("main_lobby")  
**And** transitions to the main lobby identically to previous behavior

#### Scenario: Navigate to register/login after log off
**Given** the user is logged in and on the account management screen  
**When** the Log Off button is pressed  
**And** UserDatabase.sign_out() completes  
**Then** the screen calls NavigationUtils.navigate_to_scene("register_login")  
**And** transitions to register/login identically to previous behavior

## REMOVED Requirements

### Requirement: Private Navigation Helpers
~~The account management screen SHALL implement private navigation helper methods (_navigate_to_main_lobby, _navigate_to_register_login) that validate scene paths and call TransitionManager.~~

**Rationale:** This functionality is now provided by NavigationUtils autoload.
