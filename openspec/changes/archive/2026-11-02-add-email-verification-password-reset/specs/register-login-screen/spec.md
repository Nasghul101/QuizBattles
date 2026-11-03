## ADDED Requirements

### Requirement: Request Password Reset From Login
The register/login screen SHALL use the existing ForgotPasswordButton and EmailInput to request a Firebase password-reset email without requiring a password. It SHALL not reveal whether the submitted email belongs to an account.

#### Scenario: Request a reset for an entered email
- **GIVEN** EmailInput contains a non-empty email address
- **WHEN** the user presses ForgotPasswordButton
- **THEN** the screen requests a password-reset email through Firebase Authentication
- **AND** the user receives the same confirmation whether or not an account exists for that address

#### Scenario: Request a reset with an empty email
- **GIVEN** EmailInput is empty
- **WHEN** the user presses ForgotPasswordButton
- **THEN** the screen asks the user to enter an email address
- **AND** no password-reset request is sent

#### Scenario: Password-reset service is unavailable
- **GIVEN** EmailInput contains an email address
- **AND** Firebase Authentication cannot complete the request
- **WHEN** the user presses ForgotPasswordButton
- **THEN** the screen reports a service failure without exposing account-existence information

#### Scenario: Sign in before email verification
- **GIVEN** an email/password account has not verified its email
- **WHEN** the user enters valid credentials and presses LogInButton
- **THEN** sign-in succeeds and follows the existing account-management navigation flow
- **AND** the main lobby notification list can show the verification reminder
