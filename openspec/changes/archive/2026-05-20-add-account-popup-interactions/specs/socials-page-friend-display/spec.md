# Spec Delta: socials-page-friend-display (Account Popup Interactions)

## MODIFIED Requirements

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
