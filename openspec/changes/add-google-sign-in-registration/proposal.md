## Why

The registration screen already has a "Google" button ([account_registration_screen.tscn](../../../scenes/ui/account_ui/account_registration_screen.tscn)) and the `GodotGoogleSignIn` Android addon is installed, but nothing is wired up. Players should be able to register with their Google account instead of typing an email and password.

## What Changes

- Wire the existing `GoogleSignInButton` on the registration screen to the `GodotGoogleSignIn` Android singleton (`initialize`, `signInWithGoogleButton`, `sign_in_success` / `sign_in_failed` signals).
- Exchange the Google ID token for a Firebase Auth session (`accounts:signInWithIdp`, `providerId=google.com`). The installed GodotFirebase `login_with_oauth` only sends `access_token`, so a small ID-token login path is added.
- Extend `UserDatabase` with a Google registration/sign-in flow that reuses the existing username-claim + `users/{uid}` profile creation, rollback behavior, `_finish_sign_in`, and `remember_session()`.
- Auto-generate a valid, unique username (5–15 chars) from the Google display name, since Google provides none. Changing it later is out of scope (no rename feature exists; Firestore rules lock the username) and is tracked as a follow-up.
- Returning Google users (profile already exists) are signed in without creating a second profile.
- Hide/disable the Google button on platforms where the Android singleton is unavailable (editor, desktop, iOS) and log a console message instead of failing.
- Provide a comprehensive manual TODO list for Google Cloud Console / Firebase Console / keystore / export setup (documented only; not performed by the implementation).
- Keep emulator-first behavior: in `runtime_mode="emulator"` the Auth emulator accepts unsigned fake ID tokens, so the flow can be tested without real keys.

## Capabilities

### New Capabilities
- `google-sign-in`: Google ID-token authentication via the Android plugin, Firebase `signInWithIdp` exchange, generated usernames, and platform availability handling.

### Modified Capabilities
- `account-registration-screen`: the Google button becomes functional (new requirements for the Google registration flow, error feedback, and session persistence).

## Impact

- Code: `scenes/ui/account_ui/account_registration_screen.gd`/`.tscn`, `autoload/user_database.gd`, `addons/godot-firebase/auth/auth.gd` (small ID-token method), a new `autoload` or helper for the Google plugin wrapper, `export_presets.cfg` (Android gradle build already enabled; package name `com.example.$genname` must become a real fixed ID).
- Docs: new `docs/google_sign_in_setup.md` with the manual setup checklist; `docs/firebase_emulators.md` note for testing.
- Dependencies: `GodotGoogleSignIn` (already installed); Firebase Authentication Google provider (console).
- Security: Firestore rules need no change (they don't depend on email); the Web Client ID is public, but no client secret is stored in the repo.
