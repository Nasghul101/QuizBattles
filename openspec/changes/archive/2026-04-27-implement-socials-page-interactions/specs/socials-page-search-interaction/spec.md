# socials-page-search-interaction Specification Delta

## Purpose
Provides search-as-you-type functionality for finding and adding new friends via the AddFriendsPopup. Handles user selection, friend request sending, and popup state management.

## ADDED Requirements

### Requirement: Real-Time User Search
The socials page SHALL filter and display user search results in real-time as the player types in the NameInput field, instantiating name_display_button components for each matching user.

**Rationale:** Provide immediate feedback and fast user discovery without requiring a search button.

**Cross-reference**: Uses `local-user-database.search_users_by_username()` and `name-display-button-component`.

#### Scenario: Search displays matching users
**Given** the AddFriendsPopup is open  
**And** the database contains users ["alice", "alison", "bob", "charlie"]  
**And** current user is "bob"  
**When** the player types "ali" in NameInput  
**Then** the FriendsContainer SHALL contain 2 name_display_button instances  
**And** the buttons SHALL display "alice" and "alison"  
**And** "bob" SHALL NOT appear in results (current user excluded)  
**And** "charlie" SHALL NOT appear in results (no match)

#### Scenario: Clear results on empty query
**Given** the FriendsContainer displays 3 search results  
**When** the player clears the NameInput (empty string)  
**Then** the FriendsContainer SHALL be cleared  
**And** all name_display_button instances SHALL be freed  
**And** no results SHALL be displayed

#### Scenario: Search is case-insensitive
**Given** the database contains user "Alice"  
**When** the player types "alice" (lowercase) in NameInput  
**Then** the FriendsContainer SHALL display "Alice"  
**And** the search SHALL match case-insensitively

#### Scenario: No results found
**Given** the database contains users ["alice", "bob"]  
**When** the player types "xyz" in NameInput  
**Then** the FriendsContainer SHALL be empty  
**And** no error SHALL be displayed  
**And** no name_display_button instances SHALL be created

---

### Requirement: Single Selection Management
The socials page SHALL implement radio-button selection behavior where only one name_display_button can be highlighted at a time, automatically deselecting the previously highlighted button.

**Rationale:** Prevent confusion about which user will receive the friend request.

**Cross-reference**: Uses `name-display-button-component.selection_changed` signal.

#### Scenario: Select user from search results
**Given** the FriendsContainer displays 3 name_display_button instances  
**And** no button is currently highlighted  
**When** the player clicks on the button for "alice"  
**Then** the "alice" button SHALL be highlighted  
**And** the SendFriendRequestButton SHALL become enabled  
**And** selected_username SHALL be stored as "alice"

#### Scenario: Switch selection to different user
**Given** the "alice" button is currently highlighted  
**When** the player clicks on the button for "bob"  
**Then** the "alice" button SHALL be unhighlighted  
**And** the "bob" button SHALL be highlighted  
**And** selected_username SHALL be updated to "bob"  
**And** the SendFriendRequestButton SHALL remain enabled

#### Scenario: Deselect by clicking highlighted button
**Given** the "alice" button is currently highlighted  
**When** the player clicks on the "alice" button again  
**Then** the "alice" button SHALL be unhighlighted  
**And** selected_username SHALL be cleared  
**And** the SendFriendRequestButton SHALL become disabled

---

### Requirement: Send Friend Request Button State
The socials page SHALL enable the SendFriendRequestButton only when a name_display_button is highlighted, and disable it when no selection exists.

**Rationale:** Prevent accidental friend requests and provide clear visual feedback about selection state.

#### Scenario: Button disabled by default
**Given** the AddFriendsPopup is opened  
**When** no name_display_button is highlighted  
**Then** the SendFriendRequestButton SHALL be disabled  
**And** clicking it SHALL have no effect

#### Scenario: Button enabled on selection
**Given** the player highlights a name_display_button  
**When** the button's selection state changes to highlighted  
**Then** the SendFriendRequestButton SHALL become enabled  
**And** clicking it SHALL send a friend request

#### Scenario: Button disabled on deselection
**Given** the SendFriendRequestButton is currently enabled  
**When** the highlighted name_display_button is deselected  
**Then** the SendFriendRequestButton SHALL become disabled

---

### Requirement: Send Friend Request via Notification
The socials page SHALL send friend requests by emitting a notification through GlobalSignalBus.notification_received with the selected username as the recipient.

**Rationale:** Reuse existing notification infrastructure for consistent friend request handling.

**Cross-reference**: Uses `global-signal-bus.notification_received` signal and `local-user-database` notification system.

#### Scenario: Send friend request to selected user
**Given** user "bob" is signed in  
**And** name_display_button for "alice" is highlighted  
**And** SendFriendRequestButton is enabled  
**When** the player presses SendFriendRequestButton  
**Then** GlobalSignalBus.notification_received SHALL be emitted with:
- recipient_username: "alice"
- sender: "bob"
- message: "Friend request from bob"
- has_actions: true
- action_data.type: "friend_request"
**And** the selected_username SHALL be cleared  
**And** the SendFriendRequestButton SHALL become disabled  
**And** the highlighted button SHALL remain highlighted (until new search)

#### Scenario: Prevent sending without selection
**Given** no name_display_button is highlighted  
**And** SendFriendRequestButton is disabled  
**When** the button is pressed (hypothetically)  
**Then** no notification SHALL be sent  
**And** no errors SHALL occur

---

### Requirement: Popup Cleanup on Close
The socials page SHALL clear the NameInput text and search results when the AddFriendsPopup is closed, resetting the popup to a clean initial state.

**Rationale:** Prevent stale UI state and provide a fresh search experience on next popup open.

#### Scenario: Clear popup state on back button press
**Given** the AddFriendsPopup is open  
**And** NameInput contains "alic"  
**And** FriendsContainer displays 2 search results  
**And** one name_display_button is highlighted  
**When** the player presses the BackButton  
**Then** NameInput.text SHALL be set to "" (empty string)  
**And** FriendsContainer SHALL be cleared (all children freed)  
**And** selected_username SHALL be cleared  
**And** SendFriendRequestButton SHALL be disabled  
**And** AddFriendsPopup SHALL become invisible

#### Scenario: Fresh state on popup reopen
**Given** the popup was previously closed with search results and selection  
**When** the player opens the AddFriendsPopup again  
**Then** NameInput SHALL be empty  
**And** FriendsContainer SHALL be empty  
**And** SendFriendRequestButton SHALL be disabled  
**And** no previous state SHALL persist

---

### Requirement: Share Button Placeholder
The socials page SHALL provide a non-functional share button with a TODO comment indicating future native share menu integration for mobile platforms.

**Rationale:** Reserve UI space for future feature without blocking current development.

#### Scenario: Share button press logs placeholder message
**Given** the AddFriendsPopup is open  
**When** the player presses the ShareButton  
**Then** a log message SHALL be printed: "Share button pressed - feature not yet implemented"  
**And** no errors SHALL occur  
**And** no share dialog SHALL open

#### Scenario: Share button contains TODO comment
**Given** the ShareButton handler is implemented  
**When** reviewing the code  
**Then** a comment SHALL exist: "TODO: Implement native share menu integration for mobile"  
**And** the comment SHALL note it should open the phone's native share dialog

---

### Requirement: Search Result Repopulation
The socials page SHALL clear and repopulate the FriendsContainer with fresh name_display_button instances on each search query change, preventing duplicate or stale results.

**Rationale:** Ensure search results accurately reflect the current query without state accumulation.

#### Scenario: Clear previous results before showing new ones
**Given** the FriendsContainer contains 3 name_display_button instances  
**And** the player modifies the search query  
**When** `_on_name_input_text_changed()` is called  
**Then** all existing name_display_button instances SHALL be freed via queue_free()  
**And** the FriendsContainer SHALL have 0 children  
**And** new search results SHALL be instantiated and added  
**And** no duplicate buttons SHALL appear

---
