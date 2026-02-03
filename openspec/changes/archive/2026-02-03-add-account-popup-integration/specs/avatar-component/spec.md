# avatar-component Specification Delta

## MODIFIED Requirements

### Requirement: Emit Signal on Avatar Click
The avatar component SHALL emit an `avatar_clicked` signal with the user_id when the button is pressed.

**Rationale:** Enable parent scenes to react to avatar clicks without tight coupling, supporting the account popup integration pattern.

#### Scenario: Emit user_id on button press
**Given** an avatar_component has user_id set to "PlayerOne"  
**When** the avatar button is pressed  
**Then** the signal `avatar_clicked("PlayerOne")` is emitted

---

### Requirement: Store and Retrieve User ID
The avatar component SHALL provide methods to store and retrieve a user_id string.

**Rationale:** Enable the avatar to know which user it represents so it can pass that information when clicked.

#### Scenario: Set and get user_id
**Given** an avatar_component instance  
**When** `set_user_id("PlayerOne")` is called  
**Then** `get_user_id()` returns "PlayerOne"

---

### Requirement: Maintain Existing Display Functionality
The avatar component SHALL continue to support existing methods `set_avatar_name()`, `set_avatar_picture()`, and `get_avatar_path()` without behavioral changes.

**Rationale:** Ensure backward compatibility with existing code that uses avatar components.

#### Scenario: Existing methods still work
**Given** an avatar_component instance  
**When** `set_avatar_name("TestName")` is called  
**Then** the NameLabel displays "TestName"  
**And** all other existing functionality remains unchanged
