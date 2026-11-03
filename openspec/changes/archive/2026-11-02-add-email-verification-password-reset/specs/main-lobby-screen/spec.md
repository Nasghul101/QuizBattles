## ADDED Requirements

### Requirement: Email Verification Reminder Notification
The main lobby notification list SHALL show a persistent reminder notification for a signed-in email/password account while its email remains unverified. The reminder SHALL be a local notification that is not stored in Firestore, SHALL provide actions to resend the verification email and refresh verification status, and SHALL not restrict access to the app.

#### Scenario: Show reminder for an unverified account
- **GIVEN** a signed-in email/password account has an unverified email
- **WHEN** the main lobby loads or the verification status is refreshed
- **THEN** the notification list contains the verification reminder with resend and status-refresh actions
- **AND** the notifications button is highlighted until the reminder is marked read
- **AND** the user can continue using the app

#### Scenario: Resend verification email
- **GIVEN** the verification reminder is displayed
- **WHEN** the user requests another verification email
- **THEN** the system requests a new Firebase verification message
- **AND** the reminder reports success or failure and remains listed

#### Scenario: Remove reminder after verification
- **GIVEN** the user has verified the email using the Firebase email action
- **WHEN** the user refreshes verification status
- **THEN** the reminder is removed from the notification list

#### Scenario: Do not show reminder for a verified or non-password account
- **GIVEN** a signed-in account has a verified email or does not use the email/password provider
- **WHEN** the main lobby loads or refreshes the verification status
- **THEN** no verification reminder is listed

#### Scenario: Surface verification status refresh failure
- **GIVEN** the main lobby cannot refresh email-verification status
- **WHEN** Firebase Authentication returns a service failure
- **THEN** an existing reminder reports that the status could not be checked and allows a retry
- **AND** the email is not reported as verified

### Requirement: Mark All Notifications Read
The MarkAsReadButton SHALL mark all stored notifications of the signed-in user as read and SHALL clear the notifications button highlight. It SHALL not remove the email verification reminder, which remains listed until the email is verified.

#### Scenario: Mark all read with an unverified email
- **GIVEN** unread notifications exist and the verification reminder is listed
- **WHEN** the user presses MarkAsReadButton
- **THEN** all stored notifications are marked read
- **AND** the verification reminder remains in the list
- **AND** the notifications button is no longer highlighted

#### Scenario: New notification after marking read
- **GIVEN** the user has marked all notifications read
- **WHEN** a new notification arrives
- **THEN** the notifications button is highlighted again
