## Context

See [proposal.md](./proposal.md) for the motivation and scope. `UserDatabase` currently owns the user and match dictionaries, loads `res://data/user_database.json`, and exposes synchronous methods used throughout account, lobby, social, notification, and gameplay screens. The local cache also auto-signs-in from a device-stored email/username and password.

The installed GodotFirebase add-on uses Firebase REST APIs. Its Auth calls complete through signals; Firestore collection/document operations are awaited. It documents saving and restoring Auth sessions with an encrypted auth file. The Firestore module documents that it does not currently provide offline behavior. The Firebase autoload currently defaults to production endpoints, and its Auth, Firestore, and Functions emulator URLs use `localhost`. Missing emulator ports only produce a plugin error, so the application must validate mode and configuration before allowing requests.

The existing `project.godot` registers Firebase after `UserDatabase` and `LocalCache`, while user-data callers assume the database is immediately ready. Initialization order and those async assumptions must change together. It also lists both the installed `res://addons/godot-firebase/plugin.cfg` and a second `res://addons/GodotFirebase-main/addons/godot-firebase/plugin.cfg` editor-plugin path; the latter is currently absent in the worktree. Reconcile the enabled plugin list with the installed add-on without restoring unrelated working-tree deletions. The current Firestore plugin code also does not attach the Auth ID-token header when `Firebase.emulating` is true; this must be verified and corrected for authenticated emulator requests and security-rule testing.

## Goals / Non-Goals

**Goals:**
- Use Firebase Auth for email/password identity and Firestore for shared profiles, notifications, friendships, matches, and statistics.
- Preserve the existing user-facing profile and game-data behavior while making network operations asynchronous and failures explicit.
- Use Firebase Auth, Firestore, and Functions emulators for development and testing, with no fallback to production endpoints.
- Keep settings device-local, restore sessions without storing passwords, and leave the legacy JSON data unimported.

**Non-Goals:**
- Importing, seeding, or reconciling accounts or matches from `data/user_database.json`.
- Adding offline Firestore behavior or an application-managed local replica of shared records.
- Reworking the game UI beyond the email login identifier and loading/error states required for asynchronous data.
- Adding analytics, storage of avatar image binaries, or new social/gameplay features.

## Decisions

### Firebase Auth and Firestore, not Realtime Database

Use the project's documented Firebase Auth + Firestore architecture. Auth owns email/password credentials; Firestore stores only account/profile and game data. Realtime Database is not needed for CRUD or the current UI. Do not use Firestore listeners for this migration: the plugin documents listener polling and a Realtime Database dependency, while the current screens can load data through awaited requests.

The user chose email/password login. Usernames remain unique public profile identifiers, but are not used to authenticate. This avoids exposing email addresses through a pre-authentication username lookup.

### Firestore record layout

- `users/{uid}` holds public profile and display statistics only; Firebase Auth remains the source of the user's email and credentials.
- `usernames/{normalized_username}` reserves a unique username and maps it to the Auth UID. Normalize consistently and enforce create-only uniqueness in Firestore rules.
- `friendships/{sorted_uid_pair}` represents a bidirectional relationship as one record, avoiding divergent copies in two user profiles.
- `notifications/{notification_id}` stores recipient UID, sender UID, message/action data, read state, and creation time; query by recipient and expiry.
- `matches/{match_id}` stores match state and participant UIDs, and supports queries for each participant.

Retain the current service's username-facing data contract where practical by resolving usernames through the index and hydrating public profiles. Never put passwords, ID tokens, or private email fields in a public profile document. Initialize new profiles with empty notifications, friendships, and category statistics and zeroed counters.

### Keep `UserDatabase` as the game-data boundary

Retain `UserDatabase` as the domain-facing service, but remove its local `data` dictionary as the authoritative store and remove `_load_database()` / `_save_database()` behavior. Expose async results for Firebase-backed reads and writes, retaining established result dictionaries where appropriate. Set `current_user` only after Auth succeeds and the Firestore profile is loaded.

Update every direct caller identified in the existing account, lobby, social, notification, duel, and gameplay scripts to await operations and handle failures. In particular, remove direct use of `data.multiplayer_matches` in test-match cleanup and route cleanup through the match service. The in-app test players and matches must be created only against the emulator, not implicitly against a production project.

### Use a trusted function for atomic match-statistics processing

The current contract requires both players' statistics and the match's `stats_processed` state to be updated atomically and only once. Implement a small authenticated Cloud Function that performs this operation in a Firestore transaction. The Godot client continues to read and write ordinary profile, notification, friendship, and match data through the plugin; it requests statistics processing through the Functions module. Do not treat a failed function response as a completed update or emit success signals before the transaction commits.

This function preserves atomicity but does not make client-submitted gameplay results authoritative; anti-cheat result validation is outside this change.

### Configure an explicit emulator-first runtime

Set the emulator mode before any Auth, Firestore, or Functions request. Development and test configuration selects emulation by default; production endpoints are enabled only by an explicit release configuration. Validate every required emulator port and endpoint before initialization and fail closed if a value is missing or a connection fails.

Use Emulator Suite configuration for Authentication, Firestore, and Functions, and exercise the Firestore security rules in the emulator. The plugin currently hard-codes `localhost`; provide a configurable emulator host for targets where the emulator runs on a different host address (for example, a mobile emulator/device). Make the smallest add-on change needed and keep it isolated so updating the upstream plugin remains manageable. Ensure the Firestore emulator receives the Auth Emulator ID token so rules evaluate the real authenticated UID.

The official Emulator Suite documentation describes local emulators as an isolated development/testing environment and documents supported Auth, Firestore, and Functions emulators: [Firebase Local Emulator Suite](https://firebase.google.com/docs/emulator-suite?hl=de). Follow the installed plugin's [GodotFirebase wiki](https://github.com/GodotNuts/GodotFirebase/wiki), including its [Authentication and User Management](https://github.com/GodotNuts/GodotFirebase/wiki/Authentication-and-User-Management), [Firestore](https://github.com/GodotNuts/GodotFirebase/wiki/Firestore), and [Functions](https://github.com/GodotNuts/GodotFirebase/wiki/Functions) guidance.

### Keep device preferences separate from authentication

Keep `LocalCache` for settings only. Restore Firebase Auth sessions using the plugin's `check_auth_file()` / `load_auth()` flow, persist successful Auth results with `save_auth()`, and clear them through Firebase Auth logout. On upgrade, discard any old `remembered_login` password entry while retaining settings. Do not migrate local user data or cached passwords into Firebase.

### Explicit asynchronous errors and no local success fallback

Firebase Auth uses success/failure signals; Firestore and Functions requests are asynchronous. The service layer must convert these into a consistent awaited result for callers, and screens must keep pending operations from being submitted repeatedly. Network, authorization, missing-record, and emulator-configuration failures remain failures; do not return empty/default values that appear successful or silently fall back to JSON. The plugin's documented lack of offline support means offline UX should report that shared data could not be loaded or saved.

## Risks / Trade-offs

- [Auth account creation succeeds but the Firestore profile write fails] → Do not report registration success; compensate by deleting the newly created Auth account when possible and surface both the original and cleanup failures.
- [GodotFirebase's emulator Firestore path omits the Auth token header] → Add a focused regression test and ensure the emulator receives the ID token before relying on authenticated security rules.
- [The plugin hard-codes emulator hosts and missing ports are only logged] → Add explicit startup validation and a configurable host; verify desktop and intended mobile test targets cannot reach production.
- [Many screens currently make synchronous calls and read shared dictionaries directly] → Migrate all known call sites as one dependency-ordered change and add focused GUT coverage for loading, mutation, and failure paths.
- [Firestore is unavailable offline in this plugin] → Show/propagate backend failures and do not pretend a local copy was saved; offline support remains a separate design decision.
- [A rollback to the old application cannot use newly created Firebase records] → Keep Firebase data untouched, preserve the existing JSON file during the migration rollout, and document that rolling code back restores only the old local dataset.
- [Client-side match results could still be manipulated] → Restrict direct Firestore writes with rules and process statistics transactionally in the authenticated function; authoritative gameplay validation remains out of scope.

## Migration Plan

1. Add Firebase Emulator Suite configuration, security rules, and the authenticated match-statistics function. Configure Auth, Firestore, and Functions emulator ports and host selection.
2. Verify the plugin's emulated Auth-token handling and startup ordering; add the smallest isolated plugin changes required for fail-closed, authenticated emulator requests.
3. Implement the Firestore/Auth-backed `UserDatabase` service and new profile/index/relationship/notification/match records. Do not read or import `data/user_database.json`.
4. Update registration/login, session restore, social/notification/lobby, match, and statistics callers for awaited operations; remove remembered passwords from `LocalCache` while preserving settings.
5. Run focused GUT tests, Auth/Firestore/Functions emulator integration tests, and Firestore rules tests. Confirm emulator-down and missing-port cases fail without production traffic.
6. Keep production endpoint selection explicit and separate from development/test settings. Do not delete or rewrite the old JSON file as part of this change.

Rollback restores the previous local implementation and its untouched JSON file, but Firebase accounts and records created after cutover remain in Firebase and are not visible to the old build.
