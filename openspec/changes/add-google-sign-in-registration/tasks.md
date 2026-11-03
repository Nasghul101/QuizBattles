## 1. Manual Setup TODO (user, not automated — keys/console)

- [x] 1.1 Decide the final Android package name and set `package/unique_name` in the Android export preset (replace `com.example.$genname`)
- [x] 1.2 Create/choose a release keystore; keep it outside the repo and back it up
- [x] 1.3 Get SHA-1 (and SHA-256) of the debug keystore (`keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android`) and of the release keystore
- [x] 1.4 Firebase Console: add an Android app with the package name and SHA-1/SHA-256 fingerprints
- [x] 1.5 Firebase Console → Authentication → Sign-in method: enable the Google provider and set the support email
- [x] 1.6 Google Cloud Console (same project) → APIs & Services → OAuth consent screen: configure app name, support email, and test users while in testing mode
- [x] 1.7 Google Cloud Console → Credentials: confirm the Android OAuth client (package name + SHA-1) exists for debug and release signing; create one per keystore
- [x] 1.8 Google Cloud Console → Credentials: copy the **Web application** OAuth client ID (auto-created by Firebase) — this is the Web Client ID used by the plugin (never the client secret)
- [x] 1.9 Firebase Console → Authentication → Settings: check the "one account per email" setting (default: linked) and decide if it is acceptable
- [x] 1.10 Put the Web Client ID into the project setting `google_sign_in/web_client_id` (public value only)
- [x] 1.11 Godot: Project → Install Android Build Template, confirm Gradle build is enabled and the GodotGoogleSignIn plugin is enabled in the export preset
- [ ] 1.12 Test on a real Android device with a Google account and up-to-date Play Services; for production runtime also switch `[firebase] runtime_mode` and real Firebase config

## 2. Firebase Auth addon

- [x] 2.1 Add `login_with_google_id_token(id_token: String)` to `addons/godot-firebase/auth/auth.gd` reusing the OAuth login request pipeline with `id_token=...&providerId=google.com`
- [x] 2.2 Confirm the response (including `isNewUser`) is processed like other logins (`auth_request`, `login_succeeded`, `save_auth` compatibility) and works against the Auth emulator

## 3. Services

- [x] 3.1 Create `autoload/google_sign_in_service.gd` (UID first line) with `is_available()` and `sign_in()` wrapping the `GodotGoogleSignIn` singleton; register the autoload in `project.godot`
- [x] 3.2 Add the `[google_sign_in] web_client_id` project setting (empty) and read it in the service; error on empty value
- [x] 3.3 Extract the claim + profile creation (with rollback) from `UserDatabase.create_user` into a shared helper without changing email registration behavior
- [x] 3.4 Implement `_generate_username` and `UserDatabase.register_with_google(id_token, display_name)` covering new, returning, and profile-missing accounts, rolling back only accounts created in the call

## 4. UI

- [x] 4.1 Connect `GoogleSignInButton` in `account_registration_screen.gd`; disable when unavailable or while `_creating_account`
- [x] 4.2 Share the success path (remember session, navigate to `account_management` from `register_login`) and console-only error logging with the email flow
- [x] 4.3 Make the Google button text localizable if appropriate (`localization/ui_translations.csv`)

## 5. Tests and docs

- [x] 5.1 Add emulator tests (alongside `tests/firebase_auth_firestore_rules_test.gd`) for new user, returning user, username collision retry, and rollback using fake ID tokens
- [x] 5.2 Add a test for `_generate_username` bounds (5–15 chars, valid characters)
- [x] 5.3 Write `docs/google_sign_in_setup.md` containing the manual checklist above and note the addon patch; add an emulator testing note to `docs/firebase_emulators.md`
- [ ] 5.4 Manually verify on a device: first registration, repeat sign-in, cancel, offline
- [ ] 5.5 Follow-up (separate change): username editing / rename for generated usernames
