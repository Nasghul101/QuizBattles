# local-user-database Specification Delta

## MODIFIED Requirements

### Requirement: Enhanced User Data Retrieval
The system SHALL include avatar_path in the user data returned by `get_user_by_username()` to support avatar display in friend search results.

**Rationale:** Enable search results to display user avatars without requiring additional database lookups, maintaining consistency with user data returned by other methods like `get_current_user()`.

**Changes from previous version:**
- Previously returned only username and email
- Now includes avatar_path field

#### Scenario: Retrieve user with avatar path
**Given** a user exists with username "Player123" and avatar_path "res://assets/profile_pictures/man_suit.png"  
**When** `get_user_by_username("Player123")` is called  
**Then** the method returns a dictionary containing:
  - `username`: "Player123"
  - `email`: "player@example.com"
  - `avatar_path`: "res://assets/profile_pictures/man_suit.png"

#### Scenario: Return empty dictionary for non-existent user
**Given** no user exists with username "Ghost"  
**When** `get_user_by_username("Ghost")` is called  
**Then** the method returns an empty Dictionary `{}`

---

## ADDED Requirements

### Requirement: Username Search with Partial Matching
The system SHALL provide a method to search for users by partial username match, returning all matching users except the current logged-in user.

**Rationale:** Enable friend discovery by allowing users to search for others using partial usernames, supporting a flexible and user-friendly search experience.

#### Scenario: Search with partial match returns multiple users
**Given** registered users include "john", "Johnny", and "johanna"  
**And** the current user is "alice"  
**When** `search_users_by_username("joh")` is called  
**Then** the method returns an array of 3 dictionaries containing:
  - `{username: "john", email: "john@example.com", avatar_path: "res://..."}`
  - `{username: "Johnny", email: "johnny@example.com", avatar_path: "res://..."}`
  - `{username: "johanna", email: "johanna@example.com", avatar_path: "res://..."}`

#### Scenario: Case-insensitive search
**Given** a registered user has username "BobTheBuilder"  
**And** the current user is "alice"  
**When** `search_users_by_username("bob")` is called  
**Then** the method returns an array containing the user "BobTheBuilder"

#### Scenario: Exclude current user from search results
**Given** the current logged-in user is "alice"  
**And** registered users include "alice", "alicia", and "alexander"  
**When** `search_users_by_username("ali")` is called  
**Then** the method returns an array containing only "alicia" and "alexander"  
**And** the current user "alice" is NOT included in the results

#### Scenario: Empty query returns all users except current
**Given** registered users include "alice", "bob", and "charlie"  
**And** the current user is "alice"  
**When** `search_users_by_username("")` is called  
**Then** the method returns an array containing "bob" and "charlie"  
**And** "alice" is NOT included in the results

#### Scenario: No matches returns empty array
**Given** registered users do not include any usernames containing "xyz"  
**When** `search_users_by_username("xyz")` is called  
**Then** the method returns an empty array `[]`

#### Scenario: Search when no user is logged in
**Given** no user is currently logged in (UserDatabase.current_user is empty)  
**And** registered users include "alice", "bob", and "charlie"  
**When** `search_users_by_username("a")` is called  
**Then** the method returns all matching users (alice, charlie)  
**And** no user is excluded based on current_user

---

### Requirement: Search Result Data Consistency
User data returned by `search_users_by_username()` SHALL include username, email, and avatar_path fields, matching the format returned by `get_user_by_username()` and `get_current_user()`.

**Rationale:** Maintain consistent data structures across all user retrieval methods to simplify API usage and prevent integration errors.

#### Scenario: Search results contain required fields
**Given** a search matches user "TestUser"  
**When** `search_users_by_username()` returns results  
**Then** each user dictionary SHALL contain keys: `username`, `email`, `avatar_path`  
**And** no password_hash or other sensitive fields SHALL be included

#### Scenario: Search results format matches get_user_by_username
**Given** a user "TestUser" exists in the database  
**When** comparing results from `search_users_by_username("Test")` and `get_user_by_username("TestUser")`  
**Then** both methods return dictionaries with identical structure  
**And** both include username, email, and avatar_path fields
