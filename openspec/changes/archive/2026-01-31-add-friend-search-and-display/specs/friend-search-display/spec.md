# friend-search-display Specification Delta

## ADDED Requirements

### Requirement: Real-Time Username Search
The system SHALL search for users automatically as text is entered into the NameInput field in the AddFriendsPopup, performing case-insensitive partial matching against registered usernames.

**Rationale:** Provide immediate feedback and improved user experience by showing results as the user types, similar to modern search interfaces.

#### Scenario: Search triggers on text input
**Given** the AddFriendsPopup is open with the NameInput field visible  
**When** the user types "joh" into the NameInput field  
**Then** the system SHALL automatically trigger a search  
**And** the system SHALL perform case-insensitive partial matching against all registered usernames  
**And** matching usernames (e.g., "john", "Johnny", "JOHANNA") SHALL be identified

#### Scenario: Search updates dynamically with each keystroke
**Given** the user has typed "jo" and sees matching results  
**When** the user types an additional "h" (making "joh")  
**Then** the search SHALL re-execute immediately  
**And** the results SHALL update to reflect the new query  
**And** previous results that no longer match SHALL be removed

#### Scenario: Empty input clears search results
**Given** the user has entered a search query with displayed results  
**When** the user clears all text from the NameInput field  
**Then** all search results SHALL be removed from the SearchResults container  
**And** the SearchResults container SHALL be empty

---

### Requirement: Search Result Display Using Avatar Components
The system SHALL display search results as avatar_component instances in the SearchResults GridContainer, showing the username and profile picture of each matching user.

**Rationale:** Provide visual identification of users and maintain consistency with existing avatar display patterns in the application.

#### Scenario: Display matching users as avatar components
**Given** the search query "joh" matches users "john" and "Johnny"  
**When** the search completes  
**Then** two avatar_component instances SHALL be instantiated  
**And** each instance SHALL be added to the SearchResults GridContainer  
**And** the first component SHALL have `set_avatar_name("john")` and `set_avatar_picture(<john's avatar path>)` called  
**And** the second component SHALL have `set_avatar_name("Johnny")` and `set_avatar_picture(<Johnny's avatar path>)` called

#### Scenario: Clear previous results before displaying new ones
**Given** three avatar components are currently displayed in SearchResults  
**When** a new search is performed with different results  
**Then** all existing avatar components SHALL be removed from SearchResults  
**And** the SearchResults container SHALL be cleared  
**And** new avatar components SHALL be instantiated for the new results

#### Scenario: Handle no matching results
**Given** the user enters a search query "xyz123"  
**And** no registered users match this query  
**When** the search completes  
**Then** no avatar components SHALL be displayed  
**And** the SearchResults container SHALL be empty

---

### Requirement: Current User Exclusion from Search Results
The system SHALL exclude the currently logged-in user from appearing in their own search results.

**Rationale:** Users should not be able to add themselves as friends, and seeing themselves in search results would be confusing and serve no purpose.

#### Scenario: Current user excluded from partial match
**Given** the current logged-in user is "john123"  
**When** the user searches for "joh"  
**Then** the search SHALL identify all users matching "joh"  
**And** the results SHALL exclude "john123"  
**And** other matching users (e.g., "johnny", "johanna") SHALL appear in results

#### Scenario: Current user excluded from exact match
**Given** the current logged-in user is "alice"  
**When** the user searches for "alice"  
**Then** no results SHALL be displayed  
**And** the SearchResults container SHALL be empty

---

### Requirement: Case-Insensitive Partial Username Matching
The system SHALL perform case-insensitive partial (substring) matching when searching usernames.

**Rationale:** Improve user experience by making search flexible and forgiving, allowing users to find others without knowing exact capitalization or full username.

#### Scenario: Match username with different case
**Given** a registered user has username "JohnDoe"  
**When** the user searches for "johndoe"  
**Then** the user "JohnDoe" SHALL appear in the results

#### Scenario: Match partial username at start
**Given** a registered user has username "AliceWonderland"  
**When** the user searches for "alice"  
**Then** the user "AliceWonderland" SHALL appear in the results

#### Scenario: Match partial username in middle
**Given** a registered user has username "SuperBob123"  
**When** the user searches for "bob"  
**Then** the user "SuperBob123" SHALL appear in the results

#### Scenario: Match partial username at end
**Given** a registered user has username "Player123"  
**When** the user searches for "123"  
**Then** the user "Player123" SHALL appear in the results

---

### Requirement: Future Friend Relationship Filtering Placeholder
The system design SHALL accommodate future filtering of users who are already friends with the current user, though this filtering is NOT implemented in this change.

**Rationale:** Prepare the architecture for friend relationship management without implementing it yet, ensuring the search system can be easily extended.

#### Scenario: Design note for future implementation
**Given** the search system is implemented  
**When** friend relationships are added in a future change  
**Then** the search method SHALL be designed to accept an optional exclusion list  
**And** the exclusion list SHALL be used to filter already-befriended users from results  
**And** this filtering SHALL be implemented in a future change

---

### Requirement: Search Performance for In-Memory User Database
The system SHALL execute username search efficiently against the in-memory UserDatabase without introducing UI lag or freezing.

**Rationale:** Ensure responsive search experience even with multiple users, though performance optimization is not critical at current scale.

#### Scenario: Search executes without blocking UI
**Given** the UserDatabase contains 50 registered users  
**When** the user types a character in the NameInput field  
**Then** the search SHALL execute without blocking the UI thread  
**And** the UI SHALL remain responsive  
**And** results SHALL appear within a reasonable time frame (< 100ms)

#### Scenario: Multiple rapid keystrokes handled gracefully
**Given** the user is typing quickly in the NameInput field  
**When** multiple text_changed events fire in rapid succession  
**Then** each search SHALL execute independently  
**And** the final results SHALL reflect the current query text  
**And** no search results SHALL be incorrectly displayed for outdated queries
