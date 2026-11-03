## Why

Email/password accounts currently have no in-app email verification or password recovery flow. Firebase Auth already provides the email-action APIs and the login screen now has a connected Forgot Password button, so wiring those capabilities into the existing account flows will improve account security and recovery without requiring a custom website or email backend.

## What Changes

- Send a Firebase verification email after successful email/password registration and expose the account's verification status.
- Let signed-in users continue using the app while unverified, with a persistent reminder notification in the main lobby notification list and a way to resend the verification email. Refresh the status so the reminder can clear after verification; "Mark all as read" removes the notification button highlight but keeps the reminder.
- Implement the existing Forgot Password button using the login email field and Firebase Auth's password-reset email. Give the same user-facing confirmation whether or not an account exists for the submitted email.
- Surface actionable validation and service failures without exposing account-existence information.
- Document Firebase Console email-provider/template setup and add emulator-backed coverage for the new flows.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `local-user-database`: Add verification-status retrieval, verification-email sending, and password-reset requests while retaining Firebase as the credential and email-action authority.
- `account-registration-screen`: Send the verification email as part of successful email/password registration without changing its profile-creation and session behavior.
- `register-login-screen`: Implement the existing Forgot Password action and preserve ordinary sign-in for unverified accounts.
- `main-lobby-screen`: Show a persistent, local unverified-email reminder in the notification list with resend/refresh actions, and make "Mark all as read" clear the notification highlight without removing the reminder.

## Impact

- Affected GDScript: `autoload/user_database.gd`, `addons/godot-firebase/auth/auth.gd`, and the registration, login, and main-lobby/notification controllers/scenes.
- Affected localization and docs: account-flow strings and Firebase setup/emulator documentation.
- Affected tests: Firebase Auth emulator integration tests for registration verification, resend/status refresh, and password-reset requests.
- Firebase Console configuration: Email/Password provider and email action templates/support contact must be configured for the deployed project. Firebase's hosted action handler is sufficient by default; a custom website, Cloud Function, and third-party email service are not required.
- No new runtime dependency or change to Firestore profile schema is expected.
