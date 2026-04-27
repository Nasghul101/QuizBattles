# socials-page-friend-display Specification Delta

## REMOVED Requirements

### Requirement: Display Friends on Page Load
Replaced by "Display Friends with Statistics" to include win/loss records and category preferences.

### Requirement: Avatar Component Instantiation
Replaced by friend_display_component usage with statistics display.

---

## ADDED Requirements

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
