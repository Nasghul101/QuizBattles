# Navigation Utils Specification

## ADDED Requirements

### Requirement: Scene Path Registry
The navigation utils service SHALL maintain a centralized registry of scene paths organized by logical scene keys to eliminate hardcoded path duplication across UI scripts.

#### Scenario: Scene path lookup
**Given** the NavigationUtils autoload is initialized  
**When** a script requests a scene path by key (e.g., "main_lobby")  
**Then** the service returns the corresponding scene file path  
**And** if the key is invalid, returns empty string

### Requirement: Unified Navigation Function
The navigation utils service SHALL provide a single navigate_to_scene() function that consolidates scene path validation, error handling, and transition logic to replace duplicated navigation methods across UI screens.

#### Scenario: Navigate to valid scene
**Given** a valid scene key is provided  
**When** navigate_to_scene() is called  
**Then** the service validates the scene file exists  
**And** calls TransitionManager.change_scene() with the validated path  
**And** no errors are logged

#### Scenario: Navigate to invalid scene with fallback
**Given** an invalid scene key is provided  
**And** a valid fallback scene key is provided  
**When** navigate_to_scene() is called  
**Then** the service logs an error for the primary scene  
**And** attempts to navigate to the fallback scene  
**And** calls TransitionManager.change_scene() with the fallback path

#### Scenario: Navigate to invalid scene without fallback
**Given** an invalid scene key is provided  
**And** no fallback scene key is provided  
**When** navigate_to_scene() is called  
**Then** the service logs an error  
**And** remains on the current scene (no transition occurs)

### Requirement: Autoload Registration
The navigation utils service SHALL be registered as an autoload singleton in project.godot to provide global access without coupling between UI screens.

#### Scenario: Access from any script
**Given** NavigationUtils is registered as autoload  
**When** any script calls NavigationUtils.navigate_to_scene()  
**Then** the call succeeds without requiring imports or dependencies

### Requirement: Error Message Consistency
The navigation utils service SHALL preserve existing error message formats and console output patterns to maintain debugging consistency with the current codebase.

#### Scenario: Scene not found error
**Given** a scene file does not exist at the registered path  
**When** navigate_to_scene() is called  
**Then** the service logs "Failed to navigate: {scene}.tscn not found at {path}"  
**And** the message format matches existing navigation error patterns

### Requirement: Behavioral Compatibility
The navigation utils service SHALL produce identical external behavior and scene transitions compared to the duplicated navigation methods it replaces.

#### Scenario: Scene transition execution
**Given** a UI screen calls NavigationUtils.navigate_to_scene()  
**When** the transition executes  
**Then** the behavior is identical to the previous private navigation method  
**And** the same fade effects occur  
**And** the target scene initializes identically
