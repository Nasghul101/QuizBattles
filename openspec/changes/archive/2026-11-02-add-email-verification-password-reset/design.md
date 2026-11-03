## Context

`UserDatabase` owns Firebase email/password account creation and sign-in. The Firebase Auth addon already has email-verification and password-reset OOB requests, a user-data lookup, and `FirebaseUserData.email_verified`; those email-action methods currently expose no awaited result to `UserDatabase`. The ForgotPasswordButton is already connected to a handler, but that handler is empty. The change spans authentication service behavior and multiple account screens, while the Firebase Auth emulator remains the safe integration-test target.

## Goals / Non-Goals

**Goals:**
- Keep credential and email-action handling in Firebase Authentication.
- Make Auth operations awaitable and report request, status-refresh, and service failures through the existing result-dictionary pattern.
- Let unverified email/password users sign in and continue using the app, while providing a reminder, resend action, and status refresh.
- Reuse the login screen's existing email input and ForgotPasswordButton.

**Non-Goals:**
- Building or hosting a custom website, Cloud Function, email service, or password-reset token system.
- Blocking gameplay or other app access until the email is verified.
- Changing the Firestore profile schema or storing passwords, email-action codes, or reset tokens in the game.
- Changing Google sign-in behavior.

## Decisions

1. **Use Firebase Auth's existing email-action APIs and hosted action handler.** Wrap the addon's verification and reset requests in awaitable `UserDatabase` operations so callers receive explicit success/failure results. Firebase Auth remains responsible for creating and validating action links. A custom action URL or website is unnecessary for the default flow; configure the Firebase Console provider, support contact, and email templates for the deployed project.

   **Alternative considered:** A custom web flow or Cloud Function could provide branded links, but would add deployment and security responsibilities without being required by the requested behavior.

2. **Read verification status from Firebase, not the Firestore profile.** Use the addon's account-data lookup and `FirebaseUserData.email_verified` when the main lobby loads and when the user explicitly refreshes status from the reminder. Keep the status refresh separate from password sign-in so a temporary lookup failure does not prevent an otherwise valid sign-in. The reminder reports the status failure and offers a retry instead of treating an unknown status as verified.

   **Alternative considered:** Copying verification state into Firestore would create stale duplicated data and require synchronization when the user verifies through the email link.

   **Reminder as a local notification.** The reminder is a client-side entry in the notification list, not a Firestore notification, so it disappears as soon as Firebase reports the email verified and needs no cleanup. "Mark all as read" marks stored notifications read and records the reminder as read in `UserDatabase` for the current session (reset on sign-out); the entry stays listed but no longer highlights the notifications button.

3. **Send the initial verification request after registration has created the account/profile and established the session.** A send failure must not roll back a valid account or convert registration into failure; report the failure and leave the in-app resend action available. Existing session persistence and navigation remain unchanged.

4. **Use the login screen's email field for password recovery.** No password is required. An empty field prompts the player to enter an email. Give the same confirmation for a successful request and Firebase's unknown-email response to avoid account enumeration; report input and connectivity/service errors without exposing whether an account exists.

5. **Test requests and status through the Auth emulator.** Extend the existing Godot/Auth emulator integration path. Validate request success/failure and verification status transitions using emulator-supported action links/codes; do not send real messages or use production accounts in automated tests.

## Risks / Trade-offs

- **Firebase Console configuration is project-specific** → document the Email/Password provider, support contact, and verification/reset templates as release setup. Surface Firebase request failures in the app.
- **An accepted Auth request does not guarantee inbox delivery** → describe the UI state as a request being sent, preserve resend, and avoid treating delivery as proof of verification.
- **A user verifies in an external browser while the app remains open** → provide an explicit status-refresh action; do not rely on app restart or a custom deep link.
- **Password-reset responses can disclose account existence** → normalize the unknown-email response to the same user-facing confirmation as a successful request.

## Migration Plan

No Firestore migration is needed. Existing email/password accounts retain their Firebase Auth verification state and can sign in as before; unverified accounts gain the reminder. Before release, configure and verify the Firebase Console email actions for the target project. Rollback can remove the app-side actions and reminder without changing stored profiles or credentials.
