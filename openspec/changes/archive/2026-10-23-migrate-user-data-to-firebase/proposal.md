# Proposal: Migrate User Data to Firebase

## Why

`UserDatabase` currently loads and saves account, social, statistics, notification, and match data through `res://data/user_database.json`, while authentication is simulated locally. This prevents accounts and game state from being shared across devices and makes the local file the source of truth. Replacing that path with Firebase Auth and Firestore enables shared persistence while keeping development and testing isolated from production services.

## What Changes

- Replace local user-database reads and writes with Firebase Authentication and Cloud Firestore through the installed GodotFirebase plugin.
- Preserve existing profile, friend, notification, statistics, and multiplayer-match behavior while moving reads and writes to asynchronous Firebase operations with explicit error handling.
- **BREAKING:** Use email and password for login, matching Firebase Auth and the user's decision; usernames remain profile identifiers and must remain unique.
- Configure development and test builds to use the Authentication, Firestore, and Functions emulators by default. If an emulator is unavailable or misconfigured, surface the connection failure and do not fall through to production.
- Use Firebase Auth's documented local auth-file support for remembered sessions; keep device-only preferences in `LocalCache`.
- Stop loading, creating, or saving `data/user_database.json`. Do not import, seed, or otherwise copy its existing contents into Firebase.
- Add Firebase Emulator Suite configuration for Authentication, Firestore, and the trusted match-statistics operation, plus security-rule coverage for the data accessed by the game.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `local-user-database` — move authentication and all shared player/social/match data from the local JSON database to Firebase Auth and Firestore; specify no legacy-data import and safe asynchronous failure behavior.
- `register-login-screen` — change the login identifier from username to email and use Firebase-backed authentication.
- `account-registration-screen` — create the Firebase Auth account and Firestore profile, then establish the session without storing the password for auto-login.
- `local-device-cache` — retain device-local settings, but replace remembered password credentials and local-database auto-sign-in with the GodotFirebase encrypted auth-file/session flow.

## Impact

- **Code:** `autoload/user_database.gd`, `autoload/local_cache.gd`, the account registration/login and account-management flows, lobby/social/notification screens, and gameplay/match call sites that currently expect synchronous in-memory data.
- **Configuration:** Firebase emulator ports and host selection, startup ordering for Firebase versus dependent autoloads, Emulator Suite project configuration, Firestore security rules, and the enabled editor-plugin paths. The plugin currently defaults to production URLs and hard-codes `localhost` for Auth/Firestore emulation, so the emulator endpoint must be explicit and suitable for the development target.
- **Data:** New Auth accounts and Firestore records start empty; the existing JSON file is deliberately not read or migrated. User settings remain device-local.
- **Tests:** Add or update GUT coverage for the data-service contract and emulator-backed integration checks for Auth, Firestore access, and security rules.
- **Documentation:** Document emulator startup/configuration and the explicit production-build selection.
