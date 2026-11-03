## ADDED Requirements

### Requirement: Read Email Verification Status
The system SHALL retrieve the current email/password account's verification status from Firebase Authentication and SHALL return an explicit failure if that status cannot be refreshed.

#### Scenario: Read an unverified account
- **WHEN** the current account has not verified its email and the status is refreshed
- **THEN** the result reports that the email is not verified

#### Scenario: Read a newly verified account
- **WHEN** the current account has verified its email and the status is refreshed
- **THEN** the result reports that the email is verified

#### Scenario: Surface status refresh failure
- **WHEN** Firebase Authentication cannot provide the current account's status
- **THEN** the operation returns a failure
- **AND** the system does not substitute a verified status

### Requirement: Send Email Verification Messages
The system SHALL allow an authenticated email/password account to request a Firebase email-verification message and SHALL report whether the request succeeded.

#### Scenario: Send verification message
- **GIVEN** an authenticated email/password account
- **WHEN** a verification message is requested
- **THEN** Firebase Authentication is asked to send the message
- **AND** the operation reports the request result

#### Scenario: Surface verification request failure
- **GIVEN** an authenticated email/password account
- **WHEN** Firebase Authentication cannot send the verification message
- **THEN** the operation returns a failure that can be surfaced to the user

### Requirement: Permit Sign-In Before Email Verification
The system SHALL allow an email/password account to sign in and load its Firestore profile whether or not its email is verified. The application SHALL be able to retrieve verification status separately for display.

#### Scenario: Sign in with an unverified email
- **GIVEN** an email/password account has a valid password and a Firestore profile but has not verified its email
- **WHEN** the user signs in
- **THEN** authentication and profile loading succeed
- **AND** sign-in does not require the email to be verified

#### Scenario: Sign in with a verified email
- **GIVEN** an email/password account has a valid password, a Firestore profile, and a verified email
- **WHEN** the user signs in
- **THEN** authentication and profile loading succeed
- **AND** the application can retrieve the verified status separately

### Requirement: Request Password Reset Emails
The system SHALL request password-reset emails through Firebase Authentication and SHALL return the request outcome without storing or handling the user's password.

#### Scenario: Request a password reset
- **GIVEN** a syntactically valid email address
- **WHEN** a password reset is requested
- **THEN** Firebase Authentication is asked to send its password-reset email
- **AND** the operation reports the request outcome

#### Scenario: Surface password-reset service failure
- **GIVEN** Firebase Authentication is unavailable
- **WHEN** a password reset is requested
- **THEN** the operation returns a service failure
- **AND** no password or password-reset token is stored by the game
