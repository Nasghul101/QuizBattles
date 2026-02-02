# Spec Delta: Main Lobby Screen (Notification System)

## MODIFIED Requirements

### Requirement: NotificationsPopUp Toggle on Button Press
The main lobby screen SHALL open the NotificationsPopUp when the NotificationsButton is pressed and close it when ClosePopUpButton is pressed.

**Cross-reference:** Depends on `notification-component` and `global-signal-bus` specs.

#### Scenario: Open NotificationsPopUp on button press
**Given** the user is on the main lobby screen  
**And** the NotificationsPopUp is not visible  
**When** the NotificationsButton is pressed  
**Then** the NotificationsPopUp SHALL become visible  
**And** the popup SHALL display all notifications for the current user

#### Scenario: Close NotificationsPopUp on close button press
**Given** the NotificationsPopUp is visible  
**When** the ClosePopUpButton is pressed  
**Then** the NotificationsPopUp SHALL become hidden  
**And** the user returns to the lobby view

---

### Requirement: Notification List Display
The main lobby screen SHALL display all notifications for the currently logged-in user in a scrollable list within the NotificationsPopUp.

**Rationale:** Users need to see all pending notifications in one place.

#### Scenario: Display notifications for logged-in user
**Given** the user "testuser" is logged in  
**And** the user has 3 notifications in UserDatabase  
**When** the NotificationsPopUp is opened  
**Then** 3 NotificationComponent instances SHALL be displayed  
**And** each component shows the correct message from the notification data

#### Scenario: Scrollable notification list
**Given** the user has more notifications than can fit in the viewport  
**When** the NotificationsPopUp is opened  
**Then** the notification list SHALL be scrollable  
**And** the user can scroll to view all notifications

#### Scenario: No notifications state
**Given** the user has 0 notifications  
**When** the NotificationsPopUp is opened  
**Then** the popup displays without error  
**And** shows an empty notification container

---

### Requirement: Dynamic Notification Instantiation
The main lobby screen SHALL dynamically instantiate NotificationComponent instances when notifications are received or loaded from the database.

**Rationale:** Notifications arrive asynchronously and must be added to UI in real-time.

#### Scenario: Instantiate component for new notification
**Given** the user is on the main lobby screen  
**When** GlobalSignalBus.notification_received signal is emitted  
**And** the notification is for the current user  
**Then** a new NotificationComponent SHALL be instantiated  
**And** added to the NotificationContainer  
**And** configured with the notification data

#### Scenario: Load existing notifications on screen init
**Given** the user has 2 notifications stored in UserDatabase  
**When** the main lobby screen initializes  
**Then** 2 NotificationComponent instances SHALL be created  
**And** populated with data from UserDatabase

---

### Requirement: Notification Button Visual Indicator
The main lobby screen SHALL display a visual indicator on the NotificationsButton when the user has unread notifications.

**Rationale:** Users need immediate feedback about pending notifications without opening the popup.

#### Scenario: Show indicator with unread notifications
**Given** the user has 1 or more unread notifications  
**When** the main lobby screen is displayed  
**Then** the NotificationsButton SHALL have a color modulation applied  
**And** the color change is easily modifiable in code for future shader experiments

#### Scenario: Hide indicator with no unread notifications
**Given** the user has 0 unread notifications  
**When** the main lobby screen is displayed  
**Then** the NotificationsButton SHALL display in its default state  
**And** no color modulation is applied

#### Scenario: Update indicator when notification is handled
**Given** the NotificationsButton shows an unread indicator  
**And** the user has exactly 1 unread notification  
**When** the user accepts or denies that notification  
**Then** the notification is removed  
**And** the NotificationsButton indicator is removed

---

### Requirement: Notification Action Handling
The main lobby screen SHALL handle notification actions (accept/deny) by removing the notification from UI and database, then broadcasting the action.

**Cross-reference:** Interacts with `global-signal-bus` for action broadcasting.

#### Scenario: Handle accept action
**Given** a NotificationComponent displays notification "notif_123"  
**When** the user clicks the accept button  
**Then** the component emits action_taken("notif_123", "accept")  
**And** the main lobby screen removes the component from UI  
**And** calls UserDatabase.remove_notification() with the notification ID  
**And** emits GlobalSignalBus.notification_action_taken("notif_123", "accept")  
**And** updates the notification button indicator state

#### Scenario: Handle deny action
**Given** a NotificationComponent displays notification "notif_456"  
**When** the user clicks the deny button  
**Then** the component emits action_taken("notif_456", "deny")  
**And** the main lobby screen removes the component from UI  
**And** calls UserDatabase.remove_notification() with the notification ID  
**And** emits GlobalSignalBus.notification_action_taken("notif_456", "deny")  
**And** updates the notification button indicator state

---

### Requirement: Listen for Notification Received Signal
The main lobby screen SHALL connect to GlobalSignalBus.notification_received signal on initialization to handle incoming notifications in real-time.

**Rationale:** Enable real-time notification display when user is viewing the lobby.

#### Scenario: Receive notification while on lobby screen
**Given** the user is viewing the main lobby screen  
**And** the user is logged in as "testuser"  
**When** another system emits GlobalSignalBus.notification_received with recipient_username "testuser"  
**Then** the main lobby screen receives the signal  
**And** instantiates a new NotificationComponent  
**And** updates the notification button indicator

#### Scenario: Ignore notification for different user
**Given** the user is logged in as "userA"  
**When** GlobalSignalBus.notification_received is emitted with recipient_username "userB"  
**Then** the main lobby screen does not instantiate a component  
**And** the notification button indicator remains unchanged

---

## ADDED Requirements

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
