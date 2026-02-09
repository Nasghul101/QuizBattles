# local-user-database Specification Delta

## MODIFIED Requirements

### Requirement: Store Multiplayer Matches Array
UserDatabase SHALL include a `multiplayer_matches` array in its data structure to persist match state.

**Rationale:** Enable asynchronous multiplayer gameplay with persistent state across sessions.

#### Scenario: Initialize schema on first load
**Given** the database file does not contain `multiplayer_matches` key  
**When** UserDatabase loads  
**Then** `data.multiplayer_matches` is initialized as an empty array  
**And** the database is saved with the updated schema

---

### Requirement: Provide Match CRUD Operations
UserDatabase SHALL expose methods for creating, retrieving, updating, and querying multiplayer matches.

**Rationale:** Centralize match data management in the database layer.

#### Scenario: Create match returns unique ID
**Given** `create_match(inviter, invitee, rounds, questions)` is called  
**When** the match is created  
**Then** a unique match_id is returned  
**And** the match is appended to `data.multiplayer_matches`

#### Scenario: Retrieve match by ID
**Given** a match with ID "match_123" exists  
**When** `get_match("match_123")` is called  
**Then** the complete match Dictionary is returned

#### Scenario: Update match persists changes
**Given** a match is modified  
**When** `update_match(modified_match)` is called  
**Then** the match in the array is replaced  
**And** the database file is saved

#### Scenario: Query active matches for player
**Given** Player A has 2 active matches and 1 completed match  
**When** `get_active_matches_for_player("PlayerA")` is called  
**Then** only the 2 active matches are returned

---

### Requirement: Handle Game Invite Acceptance Signal
UserDatabase SHALL connect to `GlobalSignalBus.game_invite_accepted` and automatically create matches when invites are accepted.

**Rationale:** Decouple match creation from UI logic and ensure consistent initialization.

#### Scenario: Auto-create match on signal
**Given** GlobalSignalBus.game_invite_accepted emits with ("PlayerA", "PlayerB")  
**When** UserDatabase receives the signal  
**Then** a new match is created between PlayerA and PlayerB  
**And** configuration is extracted from the game invite notification

---

### Requirement: Store Game Configuration in Notification Action Data
Game invite notifications SHALL include `rounds` and `questions` fields in their `action_data`.

**Rationale:** Enable match creation with correct configuration when invite is accepted.

#### Scenario: Enhanced notification structure
**Given** a game invite notification is created  
**When** the notification includes action_data  
**Then** `action_data.rounds` contains the configured rounds value  
**And** `action_data.questions` contains the configured questions value  
**And** existing fields (type, inviter_id) are preserved

---
