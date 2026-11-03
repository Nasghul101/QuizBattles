## ADDED Requirements

### Requirement: Google Sign-Up Button
The registration screen SHALL provide a Google button that starts registration with the user's Google account, independent of the email/username/password fields.

#### Scenario: Fields empty
- **WHEN** the user presses the Google button with all text fields empty
- **THEN** the Google flow starts and the other fields are neither required nor validated

#### Scenario: Unavailable platform
- **WHEN** Google Sign-In is unavailable on the current platform
- **THEN** the Google button is disabled

### Requirement: Google Registration Result Handling
The registration screen SHALL complete Google registration the same way as email registration.

#### Scenario: Success
- **WHEN** Google registration succeeds
- **THEN** the session is remembered and the app navigates to `account_management` with `register_login` as the back target

#### Scenario: Failure or cancellation
- **WHEN** Google registration fails or is cancelled
- **THEN** the error is logged to the console, the user stays on the registration screen, and all buttons are re-enabled

### Requirement: Prevent Concurrent Account Creation
The registration screen SHALL allow only one account creation (email or Google) at a time.

#### Scenario: Google flow in progress
- **WHEN** a Google registration is in progress
- **THEN** the Google and Create Account buttons are disabled until it finishes

#### Scenario: Email flow in progress
- **WHEN** an email registration is in progress
- **THEN** the Google button is disabled until it finishes
