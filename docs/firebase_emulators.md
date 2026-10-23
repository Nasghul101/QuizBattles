# Firebase Local Emulator Suite

Development and test builds use a Firebase demo project so Auth, Firestore, and Functions requests cannot target a production project. The repository pins the default emulator project ID to `demo-quizbattles`; the Godot runtime ignores the production project ID from the local plugin `.env` in emulator mode and requires a `demo-` project ID.

## Requirements

- Node.js 22
- JDK 21
- npm

Install the repository's Firebase CLI and Functions dependencies from the project root:

```sh
npm install
cd functions
npm install
cd ..
```

Start the emulators from the project root:

```sh
npm run emulators
```

Run the emulator-backed security checks from the project root:

```sh
# Firestore rules unit tests (Node)
npm run test:rules

# Godot Auth -> Firestore integration check
npm run test:auth-firestore

# Match-statistics Cloud Function (Auth + Firestore + Functions emulators)
npm run test:functions

# UserDatabase Auth, profile, social, match, and statistics integration
npm run test:user-database

# LocalCache settings preservation and legacy credential removal
npm run test:local-cache

# Headless cold-start smoke test against the emulators
npm run test:startup

# Fail-closed emulator mode, missing ports, and unavailable endpoint
npm run test:runtime-mode
```

The Godot integration checks use headless scripts rather than GUT. They cover email/password authentication, Firestore-backed profiles and social data, match/statistics operations, session persistence, cache cleanup, and startup. Login uses email; usernames are profile identifiers. Username search is case-insensitive prefix matching (Firestore does not support the legacy substring search).

## Interactive smoke-test checklist

Run `npm run emulators` and launch the Godot project with the emulator configuration. Use throwaway test accounts and the demo project; do not enter production credentials.

1. Register a new account with a unique username, email, and matching password. Confirm it opens account management with the default avatar and empty statistics.
-> works
2. Sign out. Try an incorrect password and confirm the app remains signed out; then sign in with the correct email and password.
-> works
3. Close and relaunch the app. Confirm the saved Auth session restores the same profile before the lobby loads. Sign out and confirm the next launch shows the signed-out state.
-> works
4. With account A, search for account B by username prefix, send a friend request, and sign out. Sign in as B, accept the request, and confirm A appears in the friends list. Open the profile, remove the friendship, and confirm it disappears.
-> works
5. With A, send a game invite to B. Sign in as B, accept it, and confirm the match appears in Friendly Battles. Play a turn, sign back in as A, and resume the same match.
-> works
6. Complete a match with both accounts taking turns. Confirm the finished result and updated win/loss/draw statistics, then dismiss the match from both accounts and confirm it is removed.
-> works
7. Confirm the emulator UI contains only the test accounts and records created during this run; no data from `data/user_database.json` should be present.
-> works

`processMatchStatistics` is an HTTP function (`POST /demo-quizbattles/us-central1/processMatchStatistics`) taking `{"match_id": "..."}` and an `Authorization: Bearer <Auth ID token>` header. The caller must be a match participant; the match's `players[i]` must be the username of `participant_uids[i]`.

If `firebase emulators:*` reports Java 8 even though JDK 21 is installed, set `JAVA_HOME` to the JDK 21 installation before running the commands.  
If `npm run test:auth-firestore` cannot find the `godot` command, set `GODOT_BIN` to your executable path (for example `C:\Ich hasse Windows\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe`).

Configured endpoints:

| Service | Host | Port |
|---|---|---:|
| Authentication | `127.0.0.1` | 9099 |
| Cloud Firestore | `127.0.0.1` | 8080 |
| Cloud Functions | `127.0.0.1` | 5001 |
| Emulator UI | `127.0.0.1` | 4000 |

The Firestore rules in `firestore.rules` are covered by `npm run test:rules`. Do not weaken them to make emulator requests pass.

The Godot runtime must explicitly select emulator mode and use the Auth, Firestore, and Functions ports above. Missing configuration or an unavailable emulator must fail visibly; it must never trigger a production fallback. A mobile device cannot resolve the development computer's `127.0.0.1`; configure the emulator host to the reachable development-machine address when testing on a device.

The three emulators bind to `0.0.0.0` so a device on the trusted development network can reach them. Desktop builds use `127.0.0.1` by default. For a physical device, set `firebase/emulator_host` in `project.godot` to the development computer's LAN IPv4 address; Android emulators can generally use `10.0.2.2` to reach the host. Keep the development machine's firewall enabled and use the emulators only on a trusted network.

## Runtime mode

`project.godot` sets `firebase/runtime_mode` to `emulator`, uses `demo-quizbattles`, and declares the same ports as `firebase.json`. The Firebase autoload validates the project ID, Functions region, and all three emulator ports before initializing the service modules. Blank plugin `.env` emulator ports use these explicit project settings; missing project settings or invalid values prevent initialization. An unavailable emulator produces a failed local request and never changes the endpoint to production. If you change an emulator port, update both `firebase.json` and `project.godot`.

Production is an explicit release-only choice: set `firebase/runtime_mode` to `production` in the release configuration and export a non-debug build. The Firebase autoload rejects production mode in editor and debug builds. Restore `emulator` before local development or tests.

## Security note

Emulator data is disposable and isolated from production. Never put production credentials, service-account keys, or private user data in this repository. Existing `data/user_database.json` contents are not loaded or imported.
