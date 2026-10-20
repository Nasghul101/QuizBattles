## MODIFIED Requirements

### Requirement: Validate Email Format on Submit
The system SHALL validate that the email field is non-empty and submit it to Firebase Authentication for provider validation when CreateAccountButton is pressed.

**Rationale:** Firebase Authentication is authoritative for email/password account creation.

#### Scenario: Reject invalid email
- **GIVEN** the email field is not accepted by Firebase Authentication
- **WHEN** account creation is submitted
- **THEN** no Firestore profile is created
- **AND** the Auth error is logged and surfaced

#### Scenario: Reject invalid email format
- **GIVEN** the email field contains an invalid address
- **WHEN** account creation is submitted
- **THEN** Firebase Authentication rejects registration and no Firestore profile is created
- **AND** the Auth error is logged and surfaced

#### Scenario: Accept valid email
- **GIVEN** Firebase Authentication accepts the email and all other validations pass
- **WHEN** account creation is submitted
- **THEN** profile creation proceeds

#### Scenario: Accept valid email format
- **GIVEN** the email field contains a valid address and other validations pass
- **WHEN** account creation is submitted
- **THEN** Firebase Authentication accepts the address and profile creation proceeds

### Requirement: Check Username Uniqueness on Submit
The system SHALL check username availability against Firebase-backed username records when CreateAccountButton is pressed and SHALL enforce uniqueness when creating the profile.

**Rationale:** Prevent duplicate player identities across devices and concurrent registrations.

#### Scenario: Reject duplicate username
- **GIVEN** the username already exists in Firebase
- **WHEN** account creation is submitted with that username
- **THEN** no profile is created
- **AND** the existing duplicate-username error and button recovery behavior are preserved

#### Scenario: Accept unique username
- **GIVEN** the username is not registered in Firebase
- **WHEN** account creation is submitted and Firebase confirms the unique claim
- **THEN** the username is associated with the new Auth account

### Requirement: Create Account on Successful Validation
The system SHALL create a Firebase Authentication account and its Firestore profile after validation succeeds, establish the authenticated session, and persist the Firebase Auth session through the plugin's encrypted auth-file support. It SHALL NOT store the password in LocalCache.

**Rationale:** Complete registration with a remotely persisted profile and preserve automatic sign-in without caching the user's password.

**Cross-reference:** Firebase session persistence is defined by `local-device-cache`.

#### Scenario: Successful account creation with default avatar
- **GIVEN** all input fields are valid, the username is available, and the passwords match
- **WHEN** the user presses CreateAccountButton
- **THEN** Firebase Authentication creates the account and Firestore creates a profile with the default avatar
- **AND** the new user session includes the profile data
- **AND** the account-management screen is shown only after profile creation succeeds

#### Scenario: Avatar path persists after registration and sign-in
- **GIVEN** a new account was registered with its default avatar
- **WHEN** the profile is loaded after authentication
- **THEN** the current user data includes the default avatar path from Firestore
- **AND** the avatar is available on the account-management screen

#### Scenario: New account is remembered without saving its password
- **GIVEN** a new account was successfully created
- **WHEN** registration completes
- **THEN** the Firebase Auth session is saved for restoration
- **AND** LocalCache does not store the email/password pair

#### Scenario: New account is remembered for auto sign-in on future launches
- **GIVEN** a new account was successfully created
- **WHEN** registration completes
- **THEN** the Firebase Auth session is saved for restoration without storing the password in LocalCache

#### Scenario: Profile write fails
- **GIVEN** Firebase Authentication creates an account but Firestore profile creation fails
- **WHEN** registration completes
- **THEN** registration reports failure and does not navigate as if successful
- **AND** the backend error is logged and surfaced
