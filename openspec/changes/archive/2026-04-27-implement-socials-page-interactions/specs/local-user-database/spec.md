# local-user-database Specification Delta

## ADDED Requirements

### Requirement: Store Category Play Statistics
The system SHALL store a `category_stats` dictionary in each user record that maps category names (Strings) to play counts (integers), tracking how many times each category has been played.

**Rationale:** Enable display of most-played categories in social features and provide data for category preference analysis.

**Cross-reference**: Used by `socials-page-friend-display` and `friend-display-component`.

#### Scenario: New user receives empty category stats
**Given** no user exists with username "NewPlayer"  
**When** `create_user("NewPlayer", "password", "player@example.com")` is called  
**Then** the user record SHALL be created with `category_stats: {}`  
**And** the dictionary SHALL be empty (no default categories)

#### Scenario: Category stats included in user data for display
**Given** user "Player123" has category_stats: {"History": 12, "Science": 8}  
**When** `get_user_data_for_display("Player123")` is called  
**Then** the returned dictionary SHALL include `"category_stats": {"History": 12, "Science": 8}`

#### Scenario: Category stats excluded from current user data
**Given** user "Player123" is signed in  
**When** `get_current_user()` is called  
**Then** the returned dictionary SHALL NOT include category_stats  
**And** only username, email, and avatar_path SHALL be returned (existing behavior)

---

### Requirement: Migrate Existing Users with Category Stats
The system SHALL automatically add an empty `category_stats` dictionary to all existing user records during database load if the field is missing.

**Rationale:** Ensure backward compatibility and prevent errors when accessing category statistics.

#### Scenario: Migrate user without category stats
**Given** user database contains user "OldUser" without category_stats field  
**When** the database is loaded via `_load_database()`  
**Then** `_migrate_user_data()` SHALL add `category_stats: {}` to "OldUser"  
**And** the database SHALL be saved with the updated schema  
**And** no existing data SHALL be lost

#### Scenario: Skip migration for users already having category stats
**Given** user "ModernUser" already has category_stats field  
**When** `_migrate_user_data()` runs  
**Then** the existing category_stats SHALL NOT be modified  
**And** no changes SHALL be made to that user record

---

### Requirement: Provide Placeholder Category Data Generation
The system SHALL provide a helper function to generate placeholder category statistics for testing and UI development before real category tracking is implemented.

**Rationale:** Allow social features to be developed and tested visually without waiting for gameplay integration.

**Note:** This is temporary functionality marked with TODO comments for future replacement.

#### Scenario: Generate random placeholder category data
**Given** no real category tracking exists yet  
**When** `_generate_placeholder_category_stats()` is called  
**Then** it SHALL return a Dictionary with 3 random category names  
**And** each category SHALL have a random play count between 1 and 20  
**And** the function SHALL include comment: "TODO: Replace with real category tracking from gameplay_screen match completion"

#### Scenario: Use placeholder data when category stats empty
**Given** user "Player123" has category_stats: {} (empty)  
**When** UI components need to display category preferences  
**Then** they MAY call `_generate_placeholder_category_stats()` to get display data  
**And** the generated data SHALL NOT be saved to the database (display only)

---

### Requirement: Category Stats Schema and Data Types
The `category_stats` field SHALL be a Dictionary where keys are category name Strings and values are non-negative integers representing play counts.

**Rationale:** Provide clear data structure for incrementing counts and sorting by frequency.

**Constraints:**
- Keys: String type (category names from TriviaQuestionService.CATEGORY_MAPPING)
- Values: int type (non-negative, incremented on each round played)
- Empty dictionary allowed (new users, no games played)

#### Scenario: Valid category stats format
**Given** a user record is being created or updated  
**When** category_stats is set  
**Then** it SHALL be a Dictionary type  
**And** all keys SHALL be Strings  
**And** all values SHALL be integers >= 0

#### Scenario: Increment category count after gameplay
**Given** user "Player123" has category_stats: {"History": 5}  
**When** the user plays a round in "History" category (future implementation)  
**Then** category_stats["History"] SHALL be incremented to 6  
**And** the database SHALL be saved with updated counts

**Note:** Actual gameplay integration is out of scope for this change. This scenario documents the intended future behavior.

---
