# socials-page-friend-display Specification

## Purpose
TBD - created by archiving change add-friend-list-management. Update Purpose after archive.
## Requirements
### Requirement: Display Friends on Page Load
The socials page SHALL display all of the current user's friends as avatar components in the FriendsList GridContainer when the page is opened.

**Cross-reference**: Uses `local-user-database.get_friends()` and `avatar-component`.

#### Scenario: Display friends for user with multiple friends
**Given** user "alice" is signed in  
**And** alice has friends ["bob", "charlie"]  
**And** the socials page is opened  
**When** the page enters the scene tree (_ready() is called)  
**Then** the FriendsList GridContainer SHALL contain 2 avatar components  
**And** the first avatar SHALL display bob's name and avatar picture  
**And** the second avatar SHALL display charlie's name and avatar picture

#### Scenario: Display empty list for user with no friends
**Given** user "alice" is signed in  
**And** alice has no friends (friends array is empty)  
**And** the socials page is opened  
**When** the page enters the scene tree  
**Then** the FriendsList GridContainer SHALL contain 0 children  
**And** no error SHALL be logged

#### Scenario: Skip display if user not signed in
**Given** no user is signed in  
**And** the socials page is opened  
**When** the page enters the scene tree  
**Then** the FriendsList GridContainer SHALL remain empty  
**And** no database queries SHALL be made

---

### Requirement: Avatar Component Instantiation
The socials page SHALL instantiate avatar components for each friend using the existing avatar_component.tscn.

**Cross-reference**: Reuses `avatar-component` for friend display.

#### Scenario: Instantiate avatar with friend data
**Given** user "alice" has friend "bob" with avatar_path "res://assets/profile_pictures/man_standard.png"  
**When** the socials page populates the friends list  
**Then** an avatar component SHALL be instantiated from avatar_component.tscn  
**And** the avatar SHALL be added as a child to FriendsList GridContainer  
**And** `set_avatar_name("bob")` SHALL be called on the component  
**And** `set_avatar_picture("res://assets/profile_pictures/man_standard.png")` SHALL be called on the component

---

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

