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
The main lobby screen SHALL use a page container to manage four content pages.

**Rationale:** Provides a robust page management system while allowing custom navigation controls.

#### Scenario: Display four pages
**GIVEN** the main lobby screen is loaded  
**WHEN** the scene initializes  
**THEN** the `PagesContainer` HBoxContainer SHALL contain exactly 4 child page scenes  
**AND** they SHALL appear in order: DuelPage, ShopPage, FriendlyBattlePage, SocialsPage

#### Scenario: Shop dummy page content
**GIVEN** the main lobby screen is loaded  
**WHEN** the ShopPage is visible  
**THEN** a centered label SHALL display the text `"Shop (Coming Soon)"`

#### Scenario: Initialize to first page
**GIVEN** the main lobby screen is loading for the first time  
**WHEN** the scene is ready  
**THEN** the page container SHALL display page index 0 (DuelPage)  
**AND** the bottom navigation SHALL indicate page 0 as active

---

### Requirement: Horizontal Swipe Gesture Detection
The `PageClipContainer` node SHALL own horizontal swipe gesture detection for page navigation, using its `_gui_input()` handler instead of a global input handler.

**Rationale:** Mobile-first UX requires touch-based navigation between pages. Scoping detection to `_gui_input()` on `PageClipContainer` removes the need for manual rect hit-testing and keeps gesture logic co-located with the pages it controls.

#### Scenario: Detect swipe left gesture
**GIVEN** the user is viewing a page in the main lobby
**AND** the current page is not the last page
**WHEN** the user touches `PageClipContainer` and drags left at least `swipe_threshold` pixels
**AND** releases the touch
**THEN** `PageClipContainer` SHALL emit `swipe_requested` with the next page index (current page + 1)
**AND** `PageClipContainer` SHALL animate `PagesContainer` to that page

#### Scenario: Detect swipe right gesture
**GIVEN** the user is viewing a page in the main lobby
**AND** the current page is not the first page
**WHEN** the user touches `PageClipContainer` and drags right at least `swipe_threshold` pixels
**AND** releases the touch
**THEN** `PageClipContainer` SHALL emit `swipe_requested` with the previous page index (current page - 1)
**AND** `PageClipContainer` SHALL animate `PagesContainer` to that page

#### Scenario: Ignore swipe below threshold
**GIVEN** the user is viewing a page in the main lobby
**WHEN** the user touches and drags less than `swipe_threshold` pixels
**AND** releases the touch
**THEN** `PageClipContainer` SHALL NOT emit `swipe_requested`
**AND** `PageClipContainer` SHALL animate `PagesContainer` back to the current page

#### Scenario: Prevent swipe beyond first page
**GIVEN** the user is on page 0 (first page)
**WHEN** the user swipes right on `PageClipContainer`
**THEN** `PageClipContainer` SHALL clamp the target page to 0
**AND** SHALL NOT emit `swipe_requested` with a negative index

#### Scenario: Prevent swipe beyond last page
**GIVEN** the user is on the last page
**WHEN** the user swipes left on `PageClipContainer`
**THEN** `PageClipContainer` SHALL clamp the target page to the last valid index
**AND** SHALL NOT emit `swipe_requested` with an out-of-range index

### Requirement: Bottom Navigation Component
The main lobby screen SHALL use an instance of `res://scenes/ui/navigation_bar.tscn` as its bottom navigation control.

**Rationale:** Replaces ad-hoc inline buttons with a polished, reusable NavigationBar component following the project's composition-based architecture.

#### Scenario: NavigationBar instance present in scene
**GIVEN** the main lobby screen scene file  
**WHEN** the scene tree is inspected  
**THEN** a `NavigationBar` node SHALL exist as the last child of `VBoxContainer`  
**AND** it SHALL be an instance of `res://scenes/ui/navigation_bar.tscn`

#### Scenario: Button press navigates to correct page
**GIVEN** the user is on any page of the main lobby  
**WHEN** the user taps a navigation button  
**THEN** the `NavigationBar` emits `page_changed(index)`  
**AND** the main lobby screen SHALL navigate to the page at that index  
**AND** `set_active_button(index)` SHALL be called on the NavigationBar

---

### Requirement: Active Page Indicator Synchronization
The NavigationBar SHALL visually indicate the currently active page using the focus style of the active button.

**Rationale:** The `NavigationButton` component already defines a focus StyleBox (purple glow). `grab_focus()` activates it without requiring additional state management.

#### Scenario: Update indicator after swipe navigation
**GIVEN** the user is on page 0 (Challenge)  
**WHEN** the user swipes left to navigate to page 1 (Shop)  
**THEN** `navigation_bar.set_active_button(1)` SHALL be called  
**AND** the Shop button SHALL have focus (purple glow)  
**AND** all other buttons SHALL NOT have focus

#### Scenario: Update indicator after button press
**GIVEN** the user is on page 0  
**WHEN** the user taps the Social button (index 3)  
**THEN** `navigation_bar.set_active_button(3)` SHALL be called  
**AND** the Social button SHALL have focus  
**AND** all other buttons SHALL NOT have focus

#### Scenario: Initialize indicator on scene load
**GIVEN** the main lobby screen is loading  
**WHEN** `_ready()` runs and `_update_page_indicator(0)` is called  
**THEN** `navigation_bar.set_active_button(0)` SHALL be called  
**AND** the Challenge button SHALL have focus on initial display

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
**THEN** the NavigationBar SHALL NOT move or animate  
**AND** the navigation buttons SHALL remain in fixed positions  
**AND** only the button states (focused/unfocused) SHALL change

---

### Requirement: Separate Page Content Scenes
Each page content area SHALL be implemented as an independent scene file.

**Rationale:** Modularity, reusability, and clear separation of concerns following project architecture patterns.

#### Scenario: Load DuelPage scene
**GIVEN** the main lobby screen is initializing  
**WHEN** the page container loads its children  
**THEN** the first child SHALL be an instance of `res://scenes/ui/lobby_pages/duel_page.tscn`  
**AND** the DuelPage scene SHALL display its content correctly

#### Scenario: Load ShopPage scene
**GIVEN** the main lobby screen is initializing  
**WHEN** the page container loads its children  
**THEN** the second child SHALL be an instance of `res://scenes/ui/lobby_pages/shop_page.tscn`  
**AND** the ShopPage scene SHALL display `"Shop (Coming Soon)"` placeholder content

#### Scenario: Load FriendlyBattlePage scene
**GIVEN** the main lobby screen is initializing  
**WHEN** the page container loads its children  
**THEN** the third child SHALL be an instance of `res://scenes/ui/lobby_pages/friendly_battle_page.tscn`

#### Scenario: Load SocialsPage scene
**GIVEN** the main lobby screen is initializing  
**WHEN** the page container loads its children  
**THEN** the fourth child SHALL be an instance of `res://scenes/ui/lobby_pages/socials_page.tscn`  
**AND** the SocialsPage scene SHALL display its social content

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

### Requirement: PageClipContainer Swipe Component Ownership
The `PageClipContainer` node SHALL be the sole owner of drag tracking, drag-following visuals, and swipe-to-page-index computation, implemented in a dedicated script attached to that node.

**Rationale:** Consolidating swipe mechanics on the node that visually clips/contains the pages removes duplicated bounds/position math from `main_lobby_screen.gd` and makes the pager reusable independent of the lobby screen.

#### Scenario: Drag follows finger within bounds
**GIVEN** the user is dragging on `PageClipContainer`
**WHEN** the drag position would move `PagesContainer` beyond the first or last page
**THEN** `PageClipContainer` SHALL clamp `PagesContainer.position.x` to stay within the first/last page bounds

#### Scenario: main_lobby_screen remains source of truth for current page
**GIVEN** `PageClipContainer` emits `swipe_requested(target_page)` after a completed swipe
**WHEN** `main_lobby_screen.gd` receives the signal
**THEN** `main_lobby_screen.gd` SHALL update its own `current_page` value
**AND** SHALL update the `NavigationBar` active indicator to match

#### Scenario: Navigation bar drives PageClipContainer
**GIVEN** the user presses a `NavigationBar` button for page index N
**WHEN** `main_lobby_screen.gd` handles the `page_changed` signal
**THEN** `main_lobby_screen.gd` SHALL update its own `current_page` to N
**AND** SHALL call `PageClipContainer.animate_to_page(N)` to perform the transition

### Requirement: Isolated Swipe Animation Function
The page transition animation SHALL be implemented in a single dedicated function on `PageClipContainer` that only plays the tween, separate from gesture-detection and page-index logic, with its duration, transition type, and ease type exposed as editable `@export` properties.

**Rationale:** Isolating the animation lets it be tuned or replaced without touching swipe detection logic, and exported parameters let the animation feel be adjusted in the editor Inspector without code changes.

#### Scenario: Animation function only plays the transition
**GIVEN** `PageClipContainer.animate_to_page(page_index)` is called
**WHEN** the target x position for `PagesContainer` has been computed
**THEN** a dedicated animation function SHALL be called with only that target x
**AND** that function SHALL contain no swipe-detection or page-index-computation logic

#### Scenario: Animation parameters are editable
**GIVEN** the `PageClipContainer` node is selected in the Godot editor
**WHEN** the Inspector is opened
**THEN** the animation duration, transition type, and ease type SHALL appear as editable exported properties
