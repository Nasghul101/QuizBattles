## ADDED Requirements

### Requirement: Remote Data Change Signals
GlobalSignalBus SHALL expose `notifications_changed(added: Array, removed: Array)`, `friends_changed()` and `matches_changed()` signals emitted by `LiveUpdateService` when remote data for the signed-in user changes. These signals SHALL be distinct from `notification_received`, which remains the signal for creating a new notification.

#### Scenario: Signal is broadcast
- **WHEN** `LiveUpdateService` detects a changed friend list
- **THEN** `GlobalSignalBus.friends_changed` is emitted to all connected listeners
