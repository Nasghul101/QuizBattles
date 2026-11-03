## ADDED Requirements

### Requirement: Request Email Verification After Registration
After an email/password account and its Firestore profile are created successfully, the registration flow SHALL request an email-verification message and continue the existing sign-in and account-management flow regardless of whether email delivery succeeds.

#### Scenario: Verification message requested after successful registration
- **GIVEN** account creation and Firestore profile creation succeed
- **WHEN** the registration flow completes
- **THEN** a Firebase verification message is requested for the new account
- **AND** the existing authenticated-session and account-management navigation behavior is preserved

#### Scenario: Verification message request fails
- **GIVEN** account creation and Firestore profile creation succeed
- **AND** Firebase Authentication cannot send the verification message
- **WHEN** the registration flow completes
- **THEN** the new account remains available and signed in
- **AND** registration is not reported as failed
- **AND** the user is told the message could not be sent
- **AND** the user can retry from the verification reminder in the main lobby notification list
