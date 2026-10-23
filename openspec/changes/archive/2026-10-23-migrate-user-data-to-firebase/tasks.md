## 1. Firebase Emulator and Security Setup

- [x] 1.1 Add Firebase Emulator Suite project configuration for Authentication, Firestore, and Functions, and document the required local ports; verify `firebase emulators:start` starts all three services.
- [x] 1.2 Add explicit development/test emulator mode and an explicit production release mode; verify a missing port or unavailable emulator produces a visible failure without sending requests to production.
- [x] 1.3 Reconcile enabled Firebase editor-plugin paths with the installed `addons/godot-firebase` add-on; verify the Godot editor loads exactly the intended plugin without a missing-path error.
- [x] 1.4 Add a configurable emulator host for desktop and mobile test targets and fix GodotFirebase's emulated Firestore Authorization header; verify an Auth Emulator ID token reaches Firestore and security rules see the signed-in UID.
- [x] 1.5 Define Firestore rules for public profiles, username claims, notifications, friendships, and participant-only matches; verify allowed and denied cases with Emulator Suite rules tests.
- [x] 1.6 Add the authenticated match-statistics Cloud Function and required Functions emulator configuration; verify its transaction updates both profiles and the match exactly once.

## 2. Firebase User Data Service

- [x] 2.1 Replace JSON-backed user loading/saving with an asynchronous `UserDatabase` Firebase service; verify startup succeeds when `data/user_database.json` is absent and no legacy records are read or seeded.
- [x] 2.2 Implement Firebase Auth registration/sign-in and Firestore profile/unique-username creation; verify email/password authentication, unique usernames, profile defaults, and partial-registration failure against emulators.
- [x] 2.3 Implement Firestore profile lookup/search, notifications, friendships, and match CRUD while preserving existing data contracts; verify each read/write and explicit error path with GUT and emulator-backed tests.
- [x] 2.4 Route completed-match statistics through the authenticated Cloud Function; verify draw/win/loss statistics, duplicate processing, and function failure behavior.
- [x] 2.5 Remove authoritative in-memory database fields and legacy file APIs from `UserDatabase`; verify no runtime user-data path reads or writes `res://data/user_database.json`.

## 3. Authentication and Device Session

- [x] 3.1 Change registration and login to email/password and await Auth plus profile operations; verify success, invalid credentials, unavailable service, and profile-write failure behavior.
- [x] 3.2 Replace remembered passwords in `LocalCache` with GodotFirebase encrypted Auth-session save/restore and retain device settings; verify a valid session restores, invalid sessions are cleared, and legacy remembered credentials are removed without changing settings.
- [x] 3.3 Initialize Firebase and emulator mode before dependent autoloads or requests; verify cold startup restores the session and profile before authenticated screens use them.

## 4. Migrate Existing Callers

- [x] 4.1 Update account-management, lobby, social, and notification screens to await Firebase-backed reads/writes and handle loading/errors; verify profile, friend, and notification flows on the emulators.
- [x] 4.2 Update gameplay and friendly-battle flows to await match reads/writes and stop accessing `UserDatabase.data.multiplayer_matches`; verify create, resume, update, completion, and cleanup flows.
- [x] 4.3 Move built-in test-player/test-match setup to emulator-only test fixtures or flows; verify a development test cannot seed production accounts or matches.

## 5. Integration Validation and Documentation

- [x] 5.1 Run focused headless Godot and emulator tests for user data, authentication, cache settings, and callers; verify all changed tests pass. (GUT is not installed; native headless scripts are used by agreement.)
- [x] 5.2 Run Auth, Firestore, Functions, and security-rule integration tests against the Emulator Suite; verify emulator-down and missing-config cases fail closed.
- [x] 5.3 Manually exercise registration, email login, restored session, profile/social/notification reads, match play/resume, and statistics; confirm no legacy JSON data appears in Firebase.
- [x] 5.4 Document emulator setup, host selection for desktop/mobile, test commands, and the explicit production-build switch; verify the instructions match the committed emulator configuration.
