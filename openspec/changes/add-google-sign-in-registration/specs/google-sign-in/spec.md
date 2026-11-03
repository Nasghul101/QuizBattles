## Purpose
Defines how players authenticate with their Google account on Android via the GodotGoogleSignIn plugin and how that identity maps onto Firebase Auth and the Firestore user profile.

## ADDED Requirements

### Requirement: Platform Availability
The system SHALL use Google Sign-In only when running on Android with the `GodotGoogleSignIn` engine singleton present.

#### Scenario: Singleton unavailable
- **WHEN** the game runs in the editor, on desktop, or on iOS
- **THEN** Google Sign-In is reported as unavailable, the Google button is disabled, and no error dialog is shown

#### Scenario: Singleton available
- **WHEN** the game runs on Android with the plugin loaded
- **THEN** the plugin is initialized once with the configured Web Client ID

### Requirement: Missing Configuration Handling
The system SHALL NOT attempt sign-in when the Web Client ID is not configured.

#### Scenario: Web Client ID empty
- **WHEN** the user presses the Google button and no Web Client ID is configured
- **THEN** a console error describes the missing configuration and no sign-in is started

### Requirement: Firebase Session From Google ID Token
The system SHALL exchange the Google ID token for a Firebase Auth session using `signInWithIdp` with provider `google.com`, honoring the existing emulator/production runtime mode.

#### Scenario: Successful exchange
- **WHEN** the plugin emits `sign_in_success` with an ID token
- **THEN** a Firebase session is established and its localId is used as the user's uid

#### Scenario: Plugin failure or cancellation
- **WHEN** the plugin emits `sign_in_failed`
- **THEN** a failure result `{success: false, error_code, message}` is returned and no account data is created

#### Scenario: Auth service busy or unreachable
- **WHEN** Firebase Auth is busy or does not answer within the auth timeout
- **THEN** a failure result with `AUTH_BUSY` or `SERVICE_UNAVAILABLE` is returned

### Requirement: Generated Username For New Google Users
The system SHALL generate a unique username of 5–15 characters from the Google display name when a Google account registers for the first time.

#### Scenario: Display name is usable
- **WHEN** the display name is "Max Mustermann"
- **THEN** the username is derived from it by removing characters other than letters, digits and underscore and truncating to 15 characters

#### Scenario: Display name too short or empty
- **WHEN** the sanitized display name has fewer than 5 characters
- **THEN** it is padded with random digits to at least 5 characters (or a "Player" base is used if empty)

#### Scenario: Username already taken
- **WHEN** the generated username is already claimed
- **THEN** a random numeric suffix is appended (keeping length ≤ 15) and the claim is retried a bounded number of times before failing with `USERNAME_EXISTS`

### Requirement: Profile Creation For New Google Users
The system SHALL create the `usernames` claim and `users/{uid}` profile for a newly created Google account using the same document shape and default avatar as email registration.

#### Scenario: New Google account
- **WHEN** Firebase reports the Google sign-in created a new account
- **THEN** the username claim and profile are created and the user becomes the current user

#### Scenario: Profile creation fails
- **WHEN** claim or profile creation fails for a newly created account
- **THEN** the claim and the new Firebase Auth account are rolled back and a failure result is returned

### Requirement: Returning Google Users
The system SHALL sign in an existing Google user without creating a second profile.

#### Scenario: Profile exists
- **WHEN** the Google account already has a `users/{uid}` profile
- **THEN** the existing profile is loaded and no claim or profile is created

#### Scenario: Auth account exists without profile
- **WHEN** the Firebase account exists but has no profile (e.g. earlier interrupted registration)
- **THEN** the profile is created using a generated username as for a new user, and no existing account is deleted

### Requirement: Session Persistence
The system SHALL persist the Google-created Firebase session with `remember_session()` so the user is restored on the next launch via `restore_session()`.

#### Scenario: Restore after restart
- **WHEN** the app restarts after Google registration
- **THEN** `restore_session()` signs the user in without showing the Google account picker

### Requirement: Secrets Handling
The system SHALL NOT store OAuth client secrets, keystores or private keys in the repository.

#### Scenario: Configuration committed
- **WHEN** the Web Client ID is added to project configuration
- **THEN** only the public Web Client ID is stored
