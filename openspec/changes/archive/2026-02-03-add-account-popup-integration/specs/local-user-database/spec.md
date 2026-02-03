# local-user-database Specification Delta

## ADDED Requirements

### Requirement: Store User Gameplay Statistics
The user database SHALL store wins, losses, and current_streak as integer fields for each user.

**Rationale:** Enable tracking and display of player performance metrics for competitive gameplay features.

#### Scenario: New user has default statistics
**Given** a new user "PlayerOne" is created  
**When** the user record is stored  
**Then** the user has wins=0, losses=0, and current_streak=0 by default

---

### Requirement: Migrate Existing Users to New Schema
The user database SHALL automatically add wins, losses, and current_streak fields with value 0 to existing user records that don't have these fields.

**Rationale:** Ensure backward compatibility when the schema is extended without requiring manual data migration or losing existing user data.

#### Scenario: Existing user gains new fields on load
**Given** the database file contains a user "OldPlayer" without wins/losses/streak fields  
**When** the database is loaded via `_load_database()`  
**Then** "OldPlayer" automatically gains wins=0, losses=0, current_streak=0  
**And** the database is saved with the migrated data

---

### Requirement: Provide Safe User Data for Display
The user database SHALL provide a method `get_user_data_for_display(username: String) -> Dictionary` that returns user data safe for UI display.

**Rationale:** Create a secure API boundary that prevents UI components from accidentally accessing sensitive user credentials.

#### Scenario: Get display-safe user data
**Given** a user "PlayerOne" exists with wins=10, losses=3, current_streak=5, password_hash="abc123", and email="player@example.com"  
**When** `get_user_data_for_display("PlayerOne")` is called  
**Then** the returned dictionary includes: username, avatar_path, wins, losses, current_streak  
**And** the returned dictionary does NOT include: password_hash, email

---

### Requirement: Handle Non-Existent User in Display Method
The user database SHALL return an empty dictionary when `get_user_data_for_display()` is called with a non-existent username.

**Rationale:** Provide safe fallback behavior that prevents crashes when querying invalid usernames.

#### Scenario: Request display data for non-existent user
**Given** no user exists with username "FakeUser"  
**When** `get_user_data_for_display("FakeUser")` is called  
**Then** an empty dictionary `{}` is returned

---

## MODIFIED Requirements

### Requirement: User Registration (modified)
The system SHALL create new user accounts with username, password, email, and initialize gameplay statistics fields (wins, losses, current_streak) to 0.

**Rationale:** Extend user registration to include new gameplay tracking fields with sensible defaults.

#### Scenario: New user has all fields initialized
**Given** no user exists with username "NewPlayer"  
**When** `create_user("NewPlayer", "password123", "new@example.com")` is called  
**Then** the user is created with wins=0, losses=0, current_streak=0  
**And** all other fields are initialized as specified in original requirement
