# account-management-screen Specification Delta

## ADDED Requirements

### Requirement: Back Navigation to Main Lobby
The account management screen SHALL provide navigation back to the main lobby screen.

**Rationale:** Allow users to return to the main lobby after viewing or managing account settings.

#### Scenario: Navigate back to main lobby
**GIVEN** the user is on the account management screen  
**WHEN** the BackButton is pressed  
**THEN** the screen SHALL transition to `res://scenes/ui/main_lobby_screen.tscn` using TransitionManager  
**AND** the transition SHALL include fade effects

---

### Requirement: Navigation Error Handling
The account management screen SHALL handle navigation failures gracefully by returning to the main lobby.

**Rationale:** Ensure users can recover from navigation errors and have a safe fallback screen.

#### Scenario: Handle transition failure and return to main lobby
**GIVEN** a scene transition is initiated  
**WHEN** the transition fails (e.g., scene path not found)  
**THEN** the screen SHALL log an error to the console using `push_error()`  
**AND** the screen SHALL transition back to `res://scenes/ui/main_lobby_screen.tscn`  
**AND** the fallback transition SHALL use TransitionManager with fade effects
