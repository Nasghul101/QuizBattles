## Context

- `UserDatabase` ([user_database.gd](../../../autoload/user_database.gd)) owns Firebase Auth + Firestore flows. `create_user` signs up, claims `usernames/{normalized}`, creates `users/{uid}`, and rolls back on failure. `_finish_sign_in` loads the profile; `remember_session()` saves the encrypted auth file.
- `GodotGoogleSignIn` is Android-only (Credential Manager). It exposes the `GodotGoogleSignIn` singleton and emits `sign_in_success(id_token, email, display_name)` / `sign_in_failed(error)`.
- GodotFirebase `Auth.login_with_oauth` sends `access_token=...`, but the plugin yields a Google **ID token**; Firebase `signInWithIdp` needs `id_token=...&providerId=google.com`.
- Firestore rules do not use email, only `usernames` claim + `users/{uid}` (username 5–15, immutable keys), so no rules change is required.
- The project runs in `runtime_mode="emulator"` by default; the Auth emulator accepts unsigned fake ID tokens.

## Goals / Non-Goals

**Goals:** Working Google registration/sign-in on Android that reuses existing profile/rollback/session logic; safe no-op elsewhere; documented manual setup.

**Non-Goals:** Creating Google Cloud/Firebase credentials, keystores, or console config (manual TODO); iOS/desktop Google login; username editing UI; Google sign-in on the login screen (the same `UserDatabase` method makes this trivial later); account linking UX.

## Decisions

1. **ID-token login in the Auth addon.** Add `login_with_google_id_token(id_token)` to `addons/godot-firebase/auth/auth.gd`, reusing the existing request pipeline (`_signin_with_oauth_request_url`, `LOGIN_OAUTH` handling, `auth_request` signal, emulator base URL) with `postBody = "id_token=<token>&providerId=google.com"`, `requestUri = "http://localhost"`. Alternative (separate `HTTPRequest` in the game) was rejected: it would bypass `is_busy`, emulator URL handling, token refresh and `save_auth`. Risk: vendored addon edit; keep it isolated and note it in the docs so addon updates re-apply it.
2. **`UserDatabase.register_with_google(id_token, display_name)`** orchestrates: `_auth_request(login_with_google_id_token)` → check `isNewUser`/profile via `_fs_get("users", uid)` → if profile exists `_finish_sign_in`; otherwise claim + create profile (shared helper extracted from `create_user`, same rollback incl. `_discard_new_account`) → `_finish_sign_in`. Rollback deletes the Auth account only when this call created it (never delete a pre-existing account).
3. **Username generation** in a pure helper `_generate_username(display_name, attempt)`: strip to `[A-Za-z0-9_]`, fallback "Player", pad to ≥5 with random digits, truncate so base + suffix ≤ 15; up to 5 attempts on `ALREADY_EXISTS`, then `USERNAME_EXISTS`. Chosen with user: auto-generate, editable later (follow-up).
4. **`GoogleSignInService` autoload** (`autoload/google_sign_in_service.gd`) wraps the singleton: `is_available()`, `sign_in() -> Dictionary` (awaits plugin signals, returns `{success, id_token, email, display_name}` or failure). Keeps plugin specifics out of UI and `UserDatabase`, and makes the emulator test path injectable (a test can stub `sign_in`). Web Client ID is read from a `[google_sign_in] web_client_id` project setting (public value; empty by default).
5. **UI**: `account_registration_screen.gd` connects `GoogleSignInButton.pressed`; disabled when unavailable or when `_creating_account`; shares `_creating_account` flag and the post-success path (`remember_session`, navigate) with email flow via a small extracted helper.
6. **Export**: `package/unique_name` must be a fixed real package id (currently `com.example.$genname`) matching the Google Cloud Android client and `google-services` setup; this is a manual TODO decision, not changed in code.

## Risks / Trade-offs

- Generated usernames may look unattractive and cannot be changed until a rename feature exists (rules lock them) → documented follow-up.
- Firebase "one account per email" default links Google to an existing email/password account with the same email; the user then has the existing profile → handled by "Profile exists" path. Behavior depends on console setting; documented in TODO.
- Plugin only testable on a real Android device with correct SHA-1; emulator tests cover the Firebase/profile part using fake ID tokens.
- Vendored addon change may be lost on addon update.

## Open Questions

- Final Android package name (affects OAuth client). Needs the owner's decision before the manual Cloud Console setup.
