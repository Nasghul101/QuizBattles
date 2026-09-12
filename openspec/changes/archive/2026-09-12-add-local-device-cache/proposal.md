# Change: Add Local Device Cache

## Why
The game has no persistent, device-local storage for session and preference data. Every time the app starts, the player has to log in again and any future in-game settings (volume, notifications, etc.) would have nowhere to live. We need a small on-device cache, created on first launch, that remembers the last logged-in user (so the app can auto sign-in) and stores in-game settings, while safely handling the case where the account's password was changed after the credentials were cached.

## What Changes
- Add a new `LocalCache` autoload that creates an encrypted cache file under `user://` on first run (or loads it if it already exists).
- Cache stores two things:
  - `remembered_login`: `{username, password}`, written whenever a user successfully logs in or registers, encrypted at rest.
  - `settings`: a small placeholder dictionary of in-game settings (e.g. music/sfx volume, notifications enabled) with sensible defaults, exposed via generic `get_setting()` / `set_setting()`.
- On startup, `LocalCache` attempts to silently sign in using the remembered credentials via the existing `UserDatabase.sign_in()` flow.
  - **Password-reset safety:** because sign-in re-validates the password against `UserDatabase`, if the account's password was changed since the credentials were cached, the remembered password will no longer match and auto sign-in SHALL fail. The stale remembered credentials are then cleared so the app doesn't keep retrying, and the player must log in manually.
- `register_login_screen.gd` calls `LocalCache.remember_login()` after a successful manual login.
- `account_registration_screen.gd` calls `LocalCache.remember_login()` after the automatic post-registration sign-in.
- `account_management_screen.gd` calls `LocalCache.forget_login()` when the user explicitly logs off, so a manual sign-out isn't immediately undone by auto sign-in on next launch.
- Credentials are stored using Godot's built-in encrypted file API (`FileAccess.open_encrypted_with_pass`), consistent with this project's existing "best-effort, not production-grade" local security posture (see `UserDatabase`'s SHA-256 password hashing, which is a placeholder for real Firebase Authentication).

## Out of Scope
- No password-reset / forgot-password UI is implemented in this change. This change only ensures that *if* a password changes by any means, cached auto sign-in becomes invalid rather than logging in with stale credentials.
- No settings screen UI is implemented. Only the underlying storage/API for settings is added, to be consumed by a future settings screen.
- `UserDatabase`'s own `res://data/user_database.json` persistence is unchanged.
- The cache is permanently device-local: it is never synced to a server/database and is not part of the future Firebase Authentication migration. It is not bundled/shipped with the app; it only ever exists as a file generated at runtime on the player's device. A player switching to a new device SHALL find no remembered login and default settings, and must log in and reconfigure settings again — this is expected, permanent behavior, not a temporary limitation to revisit later.

## Impact
- Affected specs: `local-device-cache` (new), `register-login-screen`, `account-registration-screen`, `account-management-screen`
- Affected code:
  - `autoload/local_cache.gd` (new)
  - `project.godot` (register new autoload)
  - `scenes/ui/account_ui/register_login_screen.gd`
  - `scenes/ui/account_ui/account_registration_screen.gd`
  - `scenes/ui/account_ui/account_management_screen.gd`
