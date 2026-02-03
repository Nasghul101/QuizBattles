# Spec: Global Signal Bus

## ADDED Requirements

### Requirement: GlobalSignalBus Autoload Singleton
The system SHALL provide a GlobalSignalBus autoload singleton at `autoload/global_signal_bus.gd` that serves as a central hub for application-wide signals.

#### Scenario: GlobalSignalBus is registered in project settings
**Given** the project is configured  
**When** the game launches  
**Then** `GlobalSignalBus` is available as an autoload singleton  
**And** can be accessed from any scene via `GlobalSignalBus`

---

### Requirement: Notification Received Signal
GlobalSignalBus SHALL expose a `notification_received` signal that any scene can emit to send notifications.

#### Scenario: Scene emits notification_received signal
**Given** a scene needs to notify a user  
**When** the scene calls `GlobalSignalBus.notification_received.emit(notification_data)`  
**And** `notification_data` contains `{"recipient_username": "testuser", "message": "Test message", "sender": "sender_name", "has_actions": true, "action_data": {}}`  
**Then** the signal is broadcast to all connected listeners  
**And** the notification data is passed unchanged

---

### Requirement: Notification Action Taken Signal
GlobalSignalBus SHALL expose a `notification_action_taken` signal that is emitted when users interact with notifications.

#### Scenario: User accepts a notification
**Given** a notification is displayed to the user  
**When** the user clicks the accept button  
**Then** `GlobalSignalBus.notification_action_taken.emit(notification_id, "accept")` is called  
**And** all connected listeners receive the notification ID and action string

#### Scenario: User denies a notification
**Given** a notification is displayed to the user  
**When** the user clicks the deny button  
**Then** `GlobalSignalBus.notification_action_taken.emit(notification_id, "deny")` is called  
**And** all connected listeners receive the notification ID and action string

---

### Requirement: Extensible Signal Hub
GlobalSignalBus SHALL be designed to support additional global signals in the future without modifying existing functionality.

#### Scenario: New global signal is added
**Given** a developer needs a new application-wide signal  
**When** they add a new signal definition to `global_signal_bus.gd`  
**Then** existing signals continue to function  
**And** scenes can connect to the new signal without code changes elsewhere

---

### Requirement: Signal Documentation
GlobalSignalBus script SHALL include documentation comments describing each signal's purpose, parameters, and usage patterns.

#### Scenario: Developer reads GlobalSignalBus documentation
**Given** a developer opens `autoload/global_signal_bus.gd`  
**When** they read the file  
**Then** each signal has a documentation comment explaining its purpose  
**And** parameter types and expected data structures are documented  
**And** usage examples are provided
