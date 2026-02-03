# Spec Delta: Local User Database (Notification Storage)

## ADDED Requirements

### Requirement: User Data Schema with Notifications
The user database SHALL store a notifications array for each user containing notification objects.

**Rationale:** Notifications must persist across sessions and be tied to user accounts.

#### Scenario: New user has empty notifications array
**Given** a new user is created with username "newuser"  
**When** the user is registered via create_user()  
**Then** the user's data SHALL include a `notifications` key  
**And** the value SHALL be an empty array `[]`

#### Scenario: Existing users retain notifications on save/load
**Given** a user "testuser" has 2 notifications in their notifications array  
**When** the database is saved to disk  **And** the game is restarted  
**And** the database is loaded  
**Then** the user "testuser" SHALL have exactly 2 notifications  
**And** each notification SHALL contain all original data fields

---

### Requirement: Add Notification to User
The user database SHALL provide a function to add a notification to a specific user's notification array.

**Rationale:** Systems need to create notifications and store them for delivery.

#### Scenario: Add notification to existing user
**Given** a user "recipient" exists  
**When** `add_notification("recipient", notification_data)` is called  
**And** notification_data contains `{"id": "notif_001", "message": "Test", "timestamp": "2026-02-02T10:00:00Z", "sender": "sender_name", "is_read": false, "has_actions": true, "action_data": {}}`  
**Then** the notification SHALL be appended to the user's notifications array  
**And** the database SHALL be saved to disk  
**And** the function returns successfully

#### Scenario: Reject notification for non-existent user
**Given** no user exists with username "ghost"  
**When** `add_notification("ghost", notification_data)` is called  
**Then** the function SHALL log an error  
**And** no notification is stored  
**And** the database is not modified

---

### Requirement: Remove Notification from User
The user database SHALL provide a function to remove a notification by ID from a user's notification array.

**Rationale:** Notifications are removed when users interact with them or they expire.

#### Scenario: Remove notification by ID
**Given** user "testuser" has a notification with id "notif_123"  
**When** `remove_notification("testuser", "notif_123")` is called  
**Then** the notification with id "notif_123" SHALL be removed from the array  
**And** other notifications SHALL remain unchanged  
**And** the database SHALL be saved to disk

#### Scenario: Gracefully handle missing notification ID
**Given** user "testuser" has no notification with id "notif_999"  
**When** `remove_notification("testuser", "notif_999")` is called  
**Then** the function completes without error  
**And** the user's notifications array remains unchanged

---

### Requirement: Get User Notifications
The user database SHALL provide a function to retrieve all notifications for a specific user.

**Rationale:** UI components need to load and display user notifications.

#### Scenario: Get notifications for user with notifications
**Given** user "testuser" has 3 notifications  
**When** `get_notifications("testuser")` is called  
**Then** the function SHALL return an array containing all 3 notifications  
**And** each notification SHALL be a complete dictionary with all fields

#### Scenario: Get notifications for user with no notifications
**Given** user "emptyuser" has 0 notifications  
**When** `get_notifications("emptyuser")` is called  
**Then** the function SHALL return an empty array `[]`

#### Scenario: Handle non-existent user gracefully
**Given** no user exists with username "ghost"  
**When** `get_notifications("ghost")` is called  
**Then** the function SHALL return an empty array `[]`  
**And** log a warning about the missing user

---

### Requirement: Mark Notification as Read
The user database SHALL provide a function to mark a specific notification as read.

**Rationale:** Track which notifications the user has acknowledged without removing them immediately.

#### Scenario: Mark notification as read
**Given** user "testuser" has a notification with id "notif_001"  
**And** the notification's `is_read` field is `false`  
**When** `mark_notification_read("testuser", "notif_001")` is called  
**Then** the notification's `is_read` field SHALL be set to `true`  
**And** the database SHALL be saved to disk

#### Scenario: Handle already-read notification
**Given** user "testuser" has a notification with id "notif_002"  
**And** the notification's `is_read` field is already `true`  
**When** `mark_notification_read("testuser", "notif_002")` is called  
**Then** the function completes without error  
**And** the notification remains marked as read

---

### Requirement: Get Unread Notification Count
The user database SHALL provide a function to retrieve the count of unread notifications for a user.

**Rationale:** UI needs to display badge counts and determine if visual indicators should appear.

#### Scenario: Count unread notifications
**Given** user "testuser" has 5 notifications  
**And** 3 notifications have `is_read: false`  
**And** 2 notifications have `is_read: true`  
**When** `get_unread_count("testuser")` is called  
**Then** the function SHALL return `3`

#### Scenario: User with no unread notifications
**Given** user "testuser" has 2 notifications  
**And** both have `is_read: true`  
**When** `get_unread_count("testuser")` is called  
**Then** the function SHALL return `0`

#### Scenario: User with no notifications
**Given** user "emptyuser" has 0 notifications  
**When** `get_unread_count("emptyuser")` is called  
**Then** the function SHALL return `0`

---

### Requirement: Generate Unique Notification IDs
The user database SHALL generate unique IDs for notifications when they are added.

**Rationale:** Ensure each notification can be uniquely identified for removal and read-status tracking.

#### Scenario: Auto-generate ID if not provided
**Given** a notification_data dictionary without an `id` field  
**When** `add_notification("testuser", notification_data)` is called  
**Then** the database SHALL generate a unique ID  
**And** add it to the notification before storing  
**And** the ID SHALL be unique across all notifications

#### Scenario: Use provided ID if present
**Given** notification_data contains `{"id": "custom_id_001", ...}`  
**When** `add_notification("testuser", notification_data)` is called  
**Then** the notification SHALL be stored with id "custom_id_001"  
**And** no auto-generated ID is created

---

### Requirement: Notification Timestamp Auto-Population
The user database SHALL automatically add a timestamp to notifications if not provided.

**Rationale:** Track when notifications were created for sorting and expiration purposes.

#### Scenario: Auto-add timestamp to notification
**Given** notification_data does not contain a `timestamp` field  
**When** `add_notification("testuser", notification_data)` is called  
**Then** the database SHALL add a `timestamp` field with the current ISO 8601 datetime  
**And** the notification SHALL be stored with the timestamp

#### Scenario: Preserve provided timestamp
**Given** notification_data contains `{"timestamp": "2026-02-01T10:00:00Z", ...}`  
**When** `add_notification("testuser", notification_data)` is called  
**Then** the notification SHALL be stored with timestamp "2026-02-01T10:00:00Z"  
**And** the timestamp is not overwritten
