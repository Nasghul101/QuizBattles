# socials-page-friend-display Specification

## Purpose
TBD - created by archiving change add-friend-list-management. Update Purpose after archive.
## Requirements
### Requirement: Real-Time Friend List Update
The socials page SHALL update the displayed friend list immediately when a new friendship is created while the page is open.

**Cross-reference**: Listens to `global-signal-bus.notification_action_taken`.

#### Scenario: Add friend while page is open
**Given** user "alice" is signed in with friends ["bob"]  
**And** the socials page is open displaying 1 avatar (bob)  
**And** user "charlie" sends alice a friend request  
**When** alice accepts the friend request via notification  
**And** GlobalSignalBus.notification_action_taken emits with action "accept" and type "friend_request"  
**Then** the FriendsList SHALL be cleared and repopulated  
**And** 2 avatar components SHALL now be displayed (bob and charlie)  
**And** charlie's avatar SHALL show their correct name and picture

#### Scenario: Ignore non-friend-request notifications
**Given** the socials page is open  
**When** GlobalSignalBus.notification_action_taken emits with action_data.type "game_invite"  
**Then** the FriendsList SHALL NOT be updated  
**And** no repopulation SHALL occur

---

### Requirement: Clear Friends List Before Repopulation
The socials page SHALL clear all existing avatar components from FriendsList before repopulating to prevent duplicates.

**Cross-reference**: Ensures clean state for `socials-page-friend-display`.

#### Scenario: Clear existing avatars before refresh
**Given** the FriendsList contains 3 avatar components  
**When** `_populate_friends_list()` is called  
**Then** all 3 existing avatar components SHALL be freed via queue_free()  
**And** the FriendsList SHALL have 0 children before new avatars are added  
**And** new avatar components SHALL be instantiated based on current friend data

---

### Requirement: Display Friends with Statistics
The socials page SHALL instantiate friend_display_component instances (not avatar_component) and populate them with player statistics including win/loss records and top 3 most-played categories.

**Rationale:** Provide competitive context and category preferences for each friend.

**Cross-reference**: Uses `local-user-database.get_user_data_for_display()` and `friend-display-component`.

#### Scenario: Display friend with complete statistics
**Given** user "alice" is signed in  
**And** alice has friend "bob" with:
- avatar_path: "res://assets/profile_pictures/man_standard.png"
- friend_wins["alice"]: 5 (bob has beaten alice 5 times)
- category_stats: {"History": 12, "Science": 8, "Geography": 3}
**And** alice's friend_wins["bob"]: 3 (alice has beaten bob 3 times)  
**When** the socials page populates the friends list  
**Then** a friend_display_component SHALL be instantiated  
**And** `set_player_name("bob")` SHALL be called  
**And** `set_win_count(3)` SHALL be called (alice's wins against bob)  
**And** `set_loss_count(5)` SHALL be called (bob's wins against alice)  
**And** `set_first_category(color)` SHALL be called with History color  
**And** `set_second_category(color)` SHALL be called with Science color  
**And** `set_third_category(color)` SHALL be called with Geography color  
**And** the component SHALL be added to FriendDisplayContainer above AddNewFriendsButton

#### Scenario: Display friend with no head-to-head history
**Given** user "alice" is signed in  
**And** alice has friend "charlie" with no mutual wins (neither has beaten the other)  
**When** the socials page populates the friends list  
**Then** `set_win_count(0)` SHALL be called  
**And** `set_loss_count(0)` SHALL be called  
**And** no errors SHALL be logged

#### Scenario: Display friend with missing category statistics
**Given** user "alice" has friend "david"  
**And** david has empty or missing category_stats field  
**When** the socials page populates the friends list  
**Then** category setters MAY be called with default/placeholder colors OR skipped  
**And** the component SHALL display without errors  
**And** no category bars SHALL be shown (or placeholder colors used)

---

### Requirement: Position Friend Components Above Add Button
The socials page SHALL add all friend_display_component instances to FriendDisplayContainer BEFORE the AddNewFriendsButton node, maintaining button position at the bottom.

**Rationale:** Keep the "Add New Friends" button consistently positioned at the end of the scrollable list.

#### Scenario: Insert friends before add button
**Given** FriendDisplayContainer contains AddNewFriendsButton at index 0  
**And** user has 3 friends to display  
**When** `_populate_friends_list()` is called  
**Then** 3 friend_display_components SHALL be added as children  
**And** all components SHALL be positioned before AddNewFriendsButton in the node tree  
**And** AddNewFriendsButton SHALL remain the last child of FriendDisplayContainer

---

### Requirement: Calculate Win/Loss Ratio from Friend Wins
The socials page SHALL calculate head-to-head win/loss records by cross-referencing friend_wins dictionaries between the current user and each friend.

**Rationale:** Display competitive records specific to each friendship relationship.

#### Scenario: Calculate win count from current user perspective
**Given** user "alice" has friend_wins["bob"] = 7  
**When** displaying bob in alice's friend list  
**Then** bob's component SHALL show win_count = 7 (alice's wins against bob)

#### Scenario: Calculate loss count from friend's perspective
**Given** friend "bob" has friend_wins["alice"] = 4  
**When** displaying bob in alice's friend list  
**Then** bob's component SHALL show loss_count = 4 (bob's wins against alice)

#### Scenario: Handle missing friend_wins entries
**Given** user "alice" has friend "charlie"  
**And** alice.friend_wins does not contain "charlie" key  
**And** charlie.friend_wins does not contain "alice" key  
**When** displaying charlie in alice's friend list  
**Then** win_count SHALL default to 0  
**And** loss_count SHALL default to 0

---

### Requirement: Display Top 3 Categories from Category Stats
The socials page SHALL extract the top 3 most-played categories from each friend's category_stats dictionary and display them as colored category bars using friend_display_component setters.

**Rationale:** Show friend's category preferences and expertise.

**Cross-reference**: Uses `local-user-database.category_stats` field.

#### Scenario: Sort and display top 3 categories
**Given** friend "bob" has category_stats: {"History": 15, "Science": 10, "Geography": 8, "Sports": 5}  
**When** displaying bob in the friend list  
**Then** the component SHALL call category setters for History (15), Science (10), and Geography (8)  
**And** Sports SHALL NOT be displayed (only top 3)

#### Scenario: Handle friend with fewer than 3 categories
**Given** friend "bob" has category_stats: {"History": 10, "Science": 5}  
**When** displaying bob in the friend list  
**Then** `set_first_category()` and `set_second_category()` SHALL be called  
**And** `set_third_category()` MAY be skipped or called with default/empty color

#### Scenario: Map category name to color
**Given** category "History" needs to be displayed  
**When** calling `set_first_category(color)`  
**Then** the color SHALL be determined from color_codes.json or category color mapping  
**And** the color SHALL be passed as a Color object

---

### Requirement: Use Placeholder Category Data When Empty
The socials page SHALL use placeholder category statistics when a friend's category_stats dictionary is empty or missing, until real category tracking is implemented.

**Rationale:** Allow UI testing and visual design validation before gameplay integration.

#### Scenario: Generate placeholder categories for empty stats
**Given** friend "bob" has category_stats: {} (empty dictionary)  
**When** displaying bob in the friend list  
**Then** placeholder category data SHALL be generated  
**And** 3 random categories with random counts SHALL be used for display  
**And** a comment SHALL note this is placeholder data

---

### Requirement: FriendDisplayComponent Exposes Pressed Signal
`FriendDisplayComponent` SHALL expose a `pressed` signal that forwards the internal button press so parent scenes can connect without accessing internal nodes.

**Rationale:** Encapsulation — callers should not reach into `%FriendDisplayButton.pressed` directly.

#### Scenario: Signal emitted on button press
**Given** a `FriendDisplayComponent` has been instantiated  
**When** the user taps the component's button area  
**Then** `FriendDisplayComponent.pressed` SHALL be emitted  
**And** no parameters are required (caller already knows which component emitted)

---

### Requirement: SocialsPage Connects to FriendDisplayComponent Press
SocialsPage SHALL connect to each `FriendDisplayComponent`'s `pressed` signal when instantiating it and SHALL call `AccountPopup.open_for_friend(friend_username)` in the handler.

**Cross-reference**: `AccountPopup.open_for_friend()` is defined in `account-management-screen`.

#### Scenario: Press opens AccountPopup with correct friend
**Given** the socials page is open  
**And** alice's friends list contains "bob" and "charlie"  
**And** two `FriendDisplayComponent` instances are displayed  
**When** the user taps "bob"'s component  
**Then** `AccountPopup.open_for_friend("bob")` SHALL be called  
**And** the AccountPopup SHALL become visible showing bob's data  
**And** charlie's component press SHALL NOT affect bob's popup data

#### Scenario: Signal connected during population
**Given** `_populate_friends_list()` is called  
**When** each `FriendDisplayComponent` is instantiated and added to the scene tree  
**Then** its `pressed` signal SHALL be connected to the socials page handler  
**And** the connection SHALL pass the correct friend username as a bound argument

---

### Requirement: SocialsPage Refreshes Friends List After Unfriend
SocialsPage SHALL repopulate the `FriendDisplayContainer` after a successful unfriend action.

**Rationale:** The removed friend's component must disappear immediately without a page reload.

**Cross-reference**: Triggered by the AccountPopup unfriend confirmation flow in `account-management-screen`.

#### Scenario: Friend list updates after unfriending
**Given** alice's friends list shows "bob" and "charlie"  
**When** alice confirms unfriending "bob" in the AccountPopup  
**Then** `_populate_friends_list()` SHALL be called  
**And** only "charlie"'s component SHALL be visible in the list  
**And** "bob"'s component SHALL be freed

#### Scenario: AccountPopup reference is valid after refresh
**Given** the friends list was repopulated after an unfriend  
**When** the user taps "charlie"'s component  
**Then** the AccountPopup SHALL open for "charlie" without errors  
**And** the AccountPopup SHALL NOT show stale data from the previous popup session

---

