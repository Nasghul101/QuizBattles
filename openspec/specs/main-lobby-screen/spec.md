# main-lobby-screen Specification

## Purpose
TBD - created by archiving change add-account-screen-navigation. Update Purpose after archive.
## Requirements
### Requirement: User State Detection on Load
The main lobby screen SHALL detect the current user's login state when the scene is initialized.

**Rationale:** Enables conditional navigation based on authentication state for the AccountButton and other potential features.

#### Scenario: Detect logged-in user on load
**GIVEN** a user is signed in via UserDatabase  
**WHEN** the main lobby screen is loaded  
**THEN** the screen SHALL cache the user's logged-in state  
**AND** the state SHALL be available for navigation decisions

#### Scenario: Detect logged-out user on load
**GIVEN** no user is signed in  
**WHEN** the main lobby screen is loaded  
**THEN** the screen SHALL cache the logged-out state  
**AND** the state SHALL be available for navigation decisions

---

### Requirement: Conditional AccountButton Navigation
The main lobby SHALL query UserDatabase.is_signed_in() dynamically when AccountButton is pressed to determine navigation target.

**Rationale:** Ensure navigation accurately reflects current login state, including changes from login/logout actions during the session.

**Changes from previous version:**
- Previously cached login state in `_ready()` which didn't reflect login state changes
- Now queries UserDatabase directly on each button press for accurate state
- **NEW:** This requirement remains unchanged but is included for completeness; the AccountButton is part of the header which persists across all pages

#### Scenario: Navigate to account management when logged in
**Given** the user is on any page of the main lobby screen  
**And** UserDatabase.is_signed_in() returns true  
**When** the AccountButton is pressed  
**Then** the screen queries UserDatabase.is_signed_in()  
**And** the screen transitions to `res://scenes/ui/account_ui/account_management_screen.tscn`

#### Scenario: Navigate to register/login when not logged in
**Given** the user is on any page of the main lobby screen  
**And** UserDatabase.is_signed_in() returns false  
**When** the AccountButton is pressed  
**Then** the screen queries UserDatabase.is_signed_in()  
**And** the screen transitions to `res://scenes/ui/account_ui/register_login_screen.tscn`

#### Scenario: Reflect login state changes during session
**Given** the user was not logged in when entering main lobby  
**And** the user navigates to register/login screen and successfully logs in  
**And** the user returns to main lobby (to any page)  
**When** the AccountButton is pressed  
**Then** the screen queries UserDatabase.is_signed_in() and gets true  
**And** the screen transitions to account_management_screen (not register/login)

---

### Requirement: Navigation Error Handling
The main lobby screen SHALL handle navigation failures gracefully.

**Rationale:** Prevent user confusion and provide debugging information when transitions fail.

#### Scenario: Handle transition failure
**GIVEN** a scene transition is initiated  
**WHEN** the transition fails (e.g., scene path not found)  
**THEN** the screen SHALL log an error to the console using `push_error()`  
**AND** the screen SHALL remain on the main lobby screen  
**AND** the user SHALL be able to continue interacting with the lobby

### Requirement: Multi-Page Container Structure
The main lobby screen SHALL use a TabContainer to manage multiple content pages with hidden tabs.

**Rationale:** Provides a robust, built-in page management system while allowing custom navigation controls.

#### Scenario: Display TabContainer with hidden tabs
**GIVEN** the main lobby screen is loaded  
**WHEN** the scene initializes  
**THEN** a TabContainer named "PageContainer" SHALL exist between the header and bottom navigation  
**AND** the TabContainer's tabs_visible property SHALL be false  
**AND** the TabContainer SHALL contain exactly 3 child page scenes

#### Scenario: Initialize to first page
**GIVEN** the main lobby screen is loading for the first time  
**WHEN** the scene is ready  
**THEN** the TabContainer SHALL display page index 0 (DuelPage)  
**AND** the bottom navigation SHALL indicate page 0 as active

---

### Requirement: Horizontal Swipe Gesture Detection
The main lobby screen SHALL detect horizontal swipe gestures for page navigation.

**Rationale:** Mobile-first UX requires touch-based navigation between pages.

#### Scenario: Detect swipe left gesture
**GIVEN** the user is viewing a page in the main lobby  
**AND** the current page is not the last page  
**WHEN** the user touches the screen and drags left at least 100 pixels  
**AND** releases the touch  
**THEN** the system SHALL navigate to the next page (current page + 1)  
**AND** a smooth transition animation SHALL play

#### Scenario: Detect swipe right gesture
**GIVEN** the user is viewing a page in the main lobby  
**AND** the current page is not the first page  
**WHEN** the user touches the screen and drags right at least 100 pixels  
**AND** releases the touch  
**THEN** the system SHALL navigate to the previous page (current page - 1)  
**AND** a smooth transition animation SHALL play

#### Scenario: Ignore swipe below threshold
**GIVEN** the user is viewing a page in the main lobby  
**WHEN** the user touches and drags less than 100 pixels  
**AND** releases the touch  
**THEN** the system SHALL NOT change pages  
**AND** the current page SHALL remain active

#### Scenario: Prevent swipe beyond first page
**GIVEN** the user is on page 0 (first page)  
**WHEN** the user swipes right  
**THEN** the system SHALL NOT navigate to page -1  
**AND** the current page SHALL remain 0

#### Scenario: Prevent swipe beyond last page
**GIVEN** the user is on page 2 (last page)  
**WHEN** the user swipes left  
**THEN** the system SHALL NOT navigate to page 3  
**AND** the current page SHALL remain 2

---

### Requirement: Bottom Navigation Page Switching
The bottom navigation buttons SHALL directly navigate to specific pages when pressed.

**Rationale:** Provides quick access to any page without multiple swipes, common mobile UX pattern.

#### Scenario: Navigate to DuelPage via bottom button
**GIVEN** the user is on any page in the main lobby  
**WHEN** the user taps the "DuelPage" button in the bottom navigation  
**THEN** the system SHALL navigate to page 0 (DuelPage)  
**AND** the TabContainer SHALL display page 0  
**AND** the DuelPage button SHALL show as pressed/active

#### Scenario: Navigate to Page2 via bottom button
**GIVEN** the user is on any page in the main lobby  
**WHEN** the user taps the "Page2" button in the bottom navigation  
**THEN** the system SHALL navigate to page 1 (Page2)  
**AND** the TabContainer SHALL display page 1  
**AND** the Page2 button SHALL show as pressed/active

#### Scenario: Navigate to SocialPage via bottom button
**GIVEN** the user is on any page in the main lobby  
**WHEN** the user taps the "SocialPage" button in the bottom navigation  
**THEN** the system SHALL navigate to page 2 (SocialsPage)  
**AND** the TabContainer SHALL display page 2  
**AND** the SocialPage button SHALL show as pressed/active

---

### Requirement: Active Page Indicator Synchronization
The bottom navigation buttons SHALL visually indicate the currently active page.

**Rationale:** Users need clear feedback about which page they are viewing.

#### Scenario: Update indicator after swipe navigation
**GIVEN** the user is on page 0  
**WHEN** the user swipes left to navigate to page 1  
**THEN** the DuelPage button SHALL no longer show as pressed  
**AND** the Page2 button SHALL show as pressed  
**AND** the SocialPage button SHALL remain unpressed

#### Scenario: Update indicator after button navigation
**GIVEN** the user is on page 1  
**WHEN** the user taps the SocialPage button  
**THEN** the Page2 button SHALL no longer show as pressed  
**AND** the SocialPage button SHALL show as pressed  
**AND** the DuelPage button SHALL remain unpressed

#### Scenario: Initialize indicator on scene load
**GIVEN** the main lobby screen is loading  
**WHEN** the scene is ready  
**THEN** the DuelPage button SHALL show as pressed (page 0 is default)  
**AND** the Page2 and SocialPage buttons SHALL be unpressed

---

### Requirement: Static Header and Bottom Navigation During Transitions
The header PanelContainer and bottom navigation PanelContainer SHALL remain static during page transitions.

**Rationale:** Consistent navigation elements improve UX and reduce motion sickness on mobile devices.

#### Scenario: Maintain header position during swipe
**GIVEN** the user is swiping between pages  
**WHEN** the page transition animation plays  
**THEN** the header PanelContainer SHALL NOT move or animate  
**AND** the AccountButton and title SHALL remain in fixed positions

#### Scenario: Maintain bottom navigation during swipe
**GIVEN** the user is swiping between pages  
**WHEN** the page transition animation plays  
**THEN** the bottom PanelContainer3 SHALL NOT move or animate  
**AND** the navigation buttons SHALL remain in fixed positions  
**AND** only the button states (pressed/unpressed) SHALL change

---

### Requirement: Separate Page Content Scenes
Each page content area SHALL be implemented as an independent scene file.

**Rationale:** Modularity, reusability, and clear separation of concerns following project architecture patterns.

#### Scenario: Load DuelPage scene
**GIVEN** the main lobby screen is initializing  
**WHEN** the TabContainer loads its children  
**THEN** the first tab SHALL be an instance of `res://scenes/ui/lobby_pages/duel_page.tscn`  
**AND** the DuelPage scene SHALL display its content correctly

#### Scenario: Load Page2 scene
**GIVEN** the main lobby screen is initializing  
**WHEN** the TabContainer loads its children  
**THEN** the second tab SHALL be an instance of `res://scenes/ui/lobby_pages/page2.tscn`  
**AND** the Page2 scene SHALL display placeholder content

#### Scenario: Load SocialsPage scene
**GIVEN** the main lobby screen is initializing  
**WHEN** the TabContainer loads its children  
**THEN** the third tab SHALL be an instance of `res://scenes/ui/lobby_pages/socials_page.tscn`  
**AND** the SocialsPage scene SHALL display placeholder content

---

### Requirement: Smooth Page Transition Animation
Page transitions SHALL include smooth animations for better user experience.

**Rationale:** Polished animations reduce perceived lag and improve mobile UX quality.

#### Scenario: Animate page transition with cubic easing
**GIVEN** a page navigation is triggered (by swipe or button)  
**WHEN** the page index changes  
**THEN** a Tween animation SHALL be created  
**AND** the animation SHALL use TRANS_CUBIC transition type  
**AND** the animation SHALL use EASE_OUT easing  
**AND** the animation duration SHALL be approximately 0.3 seconds

#### Scenario: Complete animation before accepting new input
**GIVEN** a page transition animation is playing  
**WHEN** the user attempts another swipe or button press  
**THEN** the system SHOULD queue or ignore the input until animation completes  
**OR** the system MAY interrupt and start a new transition to the new target page

---

### Requirement: ScrollContainer for Notification List
The NotificationsPopUp SHALL contain a ScrollContainer to handle overflow when notification count exceeds viewport height.

#### Scenario: ScrollContainer wraps notification list
**Given** the NotificationsPopUp exists in the scene  
**When** the scene is inspected  
**Then** a ScrollContainer SHALL exist as a child of the NotificationContainer  
**And** NotificationComponent instances are added as children of the ScrollContainer's content container

---

### Requirement: ClosePopUpButton Connection
The ClosePopUpButton SHALL be connected to hide the NotificationsPopUp when pressed.

#### Scenario: ClosePopUpButton closes popup
**Given** the NotificationsPopUp is visible  
**When** the ClosePopUpButton is pressed  
**Then** the pressed signal triggers _on_close_popup_button_pressed()  
**And** NotificationsPopUp.visible is set to false

