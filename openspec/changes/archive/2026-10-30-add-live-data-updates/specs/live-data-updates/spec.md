## ADDED Requirements

### Requirement: LiveUpdateService Autoload
The system SHALL provide a `LiveUpdateService` autoload at `autoload/live_update_service.gd`, independent of `UserDatabase`, that periodically checks the signed-in user's notifications, friends and matches for remote changes.

#### Scenario: Service is available at launch
- **WHEN** the game launches
- **THEN** `LiveUpdateService` is accessible as an autoload singleton

### Requirement: Poll Lifecycle
The service SHALL poll every 5 seconds only while a user is signed in and the app has focus, and SHALL run one immediate poll on sign-in and on app focus regain.

#### Scenario: Signed out
- **WHEN** no user is signed in
- **THEN** no Firestore requests are made by the service

#### Scenario: App regains focus
- **WHEN** the app returns to the foreground while signed in
- **THEN** a poll runs immediately

### Requirement: Change Detection
The service SHALL keep a snapshot per data type and emit a change signal only when the new result differs from the snapshot. The first poll after sign-in SHALL establish the baseline and SHALL NOT emit change signals.

#### Scenario: New notification arrives
- **WHEN** another player creates a notification for the signed-in user
- **THEN** within one poll interval `notifications_changed` is emitted with the added notifications

#### Scenario: Nothing changed
- **WHEN** a poll returns data equal to the snapshot
- **THEN** no signal is emitted

### Requirement: Poll Resilience
The service SHALL NOT start a poll while one is in flight, SHALL keep the previous snapshot when a request fails, and SHALL double the interval (max 30 s) after consecutive failures, resetting on success.

#### Scenario: Request fails
- **WHEN** a poll request returns an error
- **THEN** the snapshot is unchanged, no signal is emitted and the next poll is delayed
