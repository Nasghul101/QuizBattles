# Spec: Notification Component

## ADDED Requirements

### Requirement: NotificationComponent Scene Structure
The system SHALL provide a NotificationComponent at `scenes/ui/components/notification_component.tscn` that displays notification content with optional action buttons.

#### Scenario: NotificationComponent exists as a scene
**Given** the components directory exists  
**When** a developer looks for notification_component.tscn  
**Then** the file exists at `scenes/ui/components/notification_component.tscn`  
**And** it is a valid Godot scene with a root PanelContainer node

---

### Requirement: Notification Message Display
NotificationComponent SHALL display the notification message text in a readable label.

#### Scenario: Notification displays message text
**Given** a NotificationComponent instance exists  
**When** `notification_data` is set to `{"message": "Friend request from TestUser", ...}`  
**Then** the MessageLabel displays "Friend request from TestUser"  
**And** the text is visible to the user

---

### Requirement: Conditional Action Buttons
NotificationComponent SHALL show accept/deny buttons only when `has_actions` is true in the notification data.

#### Scenario: Notification with actions shows buttons
**Given** a NotificationComponent is instantiated  
**When** `notification_data.has_actions` is `true`  
**Then** both AcceptButton and DenyButton are visible  
**And** both buttons are interactive

#### Scenario: Notification without actions hides buttons
**Given** a NotificationComponent is instantiated  
**When** `notification_data.has_actions` is `false`  
**Then** both AcceptButton and DenyButton are hidden  
**And** only the message is displayed

---

### Requirement: Accept Action Signal
NotificationComponent SHALL emit an `action_taken` signal when the accept button is pressed.

#### Scenario: User clicks accept button
**Given** a NotificationComponent displays a notification with `id` "notif_123"  
**And** `has_actions` is true  
**When** the user clicks the AcceptButton  
**Then** the component emits `action_taken("notif_123", "accept")`  
**And** the signal includes the notification ID and action string

---

### Requirement: Deny Action Signal
NotificationComponent SHALL emit an `action_taken` signal when the deny button is pressed.

#### Scenario: User clicks deny button
**Given** a NotificationComponent displays a notification with `id` "notif_456"  
**And** `has_actions` is true  
**When** the user clicks the DenyButton  
**Then** the component emits `action_taken("notif_456", "deny")`  
**And** the signal includes the notification ID and action string

---

### Requirement: Notification Data Storage
NotificationComponent SHALL store the complete notification data dictionary for reference.

#### Scenario: Component stores full notification data
**Given** a NotificationComponent is instantiated  
**When** `set_notification_data(notification_dict)` is called  
**Then** the component stores the entire dictionary internally  
**And** the data can be accessed for signal emission or debugging

---

### Requirement: Configurable Appearance
NotificationComponent SHALL expose customizable properties for visual styling to support future experimentation with shaders or effects.

#### Scenario: Component has customizable indicator color
**Given** a NotificationComponent exists  
**When** a developer inspects exported properties  
**Then** an `indicator_color` property exists  
**And** changing it affects the component's visual appearance  
**And** it can be easily modified for shader experiments

---

### Requirement: Minimal Initial Design
NotificationComponent SHALL use a clean, minimal design matching existing UI components.

#### Scenario: Component matches project style
**Given** the project has defined UI components (answer_button, result_component, etc.)  
**When** a NotificationComponent is placed in a scene  
**Then** it visually aligns with the existing component style  
**And** uses consistent spacing, fonts, and panel styling
