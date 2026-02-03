# account-popup-component Specification

## Purpose
A reusable modal popup component that displays user account information fetched from UserDatabase. The popup provides a secure, read-only view of user statistics and profile data, excluding sensitive information like passwords and emails. Designed to be embedded in any scene that needs to display user profiles.

## ADDED Requirements

### Requirement: Display User Profile Data
The account popup SHALL fetch and display username, avatar, wins, losses, and current_streak for a given user_id.

**Rationale:** Provide players with a comprehensive view of another user's public profile and statistics.

#### Scenario: Display friend profile data
**Given** a user "PlayerOne" exists with wins=10, losses=3, current_streak=5, and avatar "man_beard.png"  
**When** `display_user("PlayerOne")` is called on the account_popup  
**Then** the NameLabel displays "PlayerOne"  
**And** the PlayerAvatar displays the texture from "man_beard.png"  
**And** wins, losses, and current_streak are available for display in future UI elements

---

### Requirement: Modal Overlay Behavior
The account popup SHALL display a semi-transparent overlay behind it that blocks interaction with underlying UI.

**Rationale:** Focus user attention on the popup and prevent accidental interactions with background elements.

#### Scenario: Show overlay when popup opens
**Given** the account_popup is hidden  
**When** `display_user("PlayerOne")` is called  
**Then** the PopupOverlay becomes visible  
**And** the account_popup panel becomes visible  
**And** the overlay has a semi-transparent color

---

### Requirement: Close on Overlay Click
The account popup SHALL close when the user clicks anywhere on the overlay outside the popup panel.

**Rationale:** Provide intuitive dismissal behavior consistent with modal dialog patterns.

#### Scenario: Close popup by clicking overlay
**Given** the account_popup is open and displaying user data  
**When** the user clicks on the PopupOverlay outside the popup panel  
**Then** the popup closes  
**And** the overlay becomes hidden

---

### Requirement: Close on Back Button
The account popup SHALL close when the user clicks the BackButton inside the popup.

**Rationale:** Provide explicit close action for users who prefer button-based navigation.

#### Scenario: Close popup by clicking back button
**Given** the account_popup is open and displaying user data  
**When** the user clicks the BackButton  
**Then** the popup closes  
**And** the overlay becomes hidden

---

### Requirement: Centered Responsive Positioning
The account popup SHALL be centered on screen with responsive margins that prevent it from covering the entire viewport.

**Rationale:** Maintain visual hierarchy and ensure the popup is clearly a modal overlay rather than a full-screen takeover.

#### Scenario: Popup displays centered with margins
**Given** the viewport size is 1152x648  
**When** the account_popup is opened  
**Then** the popup panel is centered horizontally and vertically  
**And** there is visible margin space around all edges of the popup

---

### Requirement: Exclude Sensitive User Data
The account popup SHALL NOT have access to or display sensitive user information including password_hash and email.

**Rationale:** Protect user privacy and security by ensuring sensitive credentials are never exposed in UI components.

#### Scenario: Sensitive data is not accessible
**Given** a user exists with email "player@example.com" and password_hash "abc123"  
**When** `display_user("PlayerOne")` is called  
**Then** the popup does NOT receive or store the email  
**And** the popup does NOT receive or store the password_hash

---

### Requirement: Fetch Data from UserDatabase
The account popup SHALL call UserDatabase methods to retrieve user data rather than receiving it as a parameter.

**Rationale:** Decouple the popup from parent scenes and ensure it always displays current data from the authoritative source.

#### Scenario: Fetch user data on display
**Given** UserDatabase contains user "PlayerOne" with current stats  
**When** `display_user("PlayerOne")` is called  
**Then** the popup calls `UserDatabase.get_user_data_for_display("PlayerOne")`  
**And** the returned data populates the popup UI elements

---

### Requirement: Handle Non-Existent Users
The account popup SHALL gracefully handle attempts to display data for users that don't exist.

**Rationale:** Prevent crashes and provide clear feedback when invalid user_ids are provided.

#### Scenario: Display error for non-existent user
**Given** no user exists with username "FakeUser"  
**When** `display_user("FakeUser")` is called  
**Then** the popup does not open or displays an error message  
**And** no crash or error is thrown

---

### Requirement: Reusable Across Scenes
The account popup SHALL be instantiable in any scene's scene tree and function identically regardless of parent.

**Rationale:** Maximize code reuse and ensure consistent user experience across different contexts (friends list, match results, leaderboards).

#### Scenario: Popup works in different parent scenes
**Given** account_popup is added to socials_page scene tree  
**And** account_popup is also added to match_results_page scene tree  
**When** `display_user("PlayerOne")` is called in either scene  
**Then** the popup displays identical data and behavior in both contexts

---

### Requirement: No Animation
The account popup SHALL appear and disappear instantly without fade-in, slide-in, or other animations.

**Rationale:** Keep implementation simple and meet explicit user requirement for no animation.

#### Scenario: Instant visibility toggle
**Given** the account_popup is hidden  
**When** `display_user("PlayerOne")` is called  
**Then** the popup and overlay become visible immediately without animation  
**When** the close action is triggered  
**Then** the popup and overlay become hidden immediately without animation
