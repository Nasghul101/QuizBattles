## 1. Firebase Authentication Operations

- [x] 1.1 Wrap the addon's verification-email and password-reset requests in awaitable `UserDatabase` operations that return explicit results; verify success, Auth errors, busy state, and timeout behavior with focused Auth integration checks.
- [x] 1.2 Add an authenticated email-verification status refresh using Firebase user data; verify true, false, and service-failure results with the Auth emulator.

## 2. Registration and Account Screens

- [x] 2.1 Request email verification after successful email/password registration and preserve the signed-in session and account-management navigation if sending fails; verify a failed send does not roll back the account/profile.
- [x] 2.2 Show a localized reminder notification in the main lobby notification list for unverified email/password accounts, with resend and status-refresh actions; it stays until verified, "Mark all as read" only clears the button highlight, and it does not block app access.
- [x] 2.3 Implement the connected ForgotPasswordButton using EmailInput, including empty-email feedback and a generic confirmation for existing and unknown accounts; verify service failures do not expose account existence.

## 3. Emulator Coverage and Setup Documentation

- [x] 3.1 Extend the existing Godot/Auth emulator integration tests to cover verification request, resend, status refresh after verification, password-reset request, and the unknown-email response; verify with `npm run test:user-database`.
- [x] 3.2 Document Firebase Console Email/Password provider, support contact, and verification/reset email-template setup, plus emulator email-action testing; verify the instructions match the configured emulator workflow.
- [x] 3.3 Run the account-flow smoke test with the Auth emulator and a real non-production Firebase project after completing section 4; verify signup, resend, external email verification plus status refresh, and password reset without blocking unverified sign-in.

## 4. Firebase Console Setup (Manual)

- [x] 4.1 In the target Firebase project, enable Authentication → Sign-in method → Email/Password; verify the setting is saved.
- [x] 4.2 Configure the project support email and review/customize the Authentication email templates for email verification and password reset; verify the displayed sender/support details and links.
- [x] 4.3 Confirm Firebase-hosted email action links work for the target project; configure a custom domain only if one is intentionally chosen (the default hosted flow does not require one).
