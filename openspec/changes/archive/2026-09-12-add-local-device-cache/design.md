## Context
The project currently has no on-device persistence outside of `UserDatabase` (which simulates a shared backend and writes to `res://data/user_database.json` — a path that only happens to be writable in the editor and would not be writable in an exported build). We need genuine per-device local storage for:
1. Remembering the last logged-in user so the player isn't forced to log in every launch.
2. A place for in-game settings (volume, notifications, etc.) to live once a settings screen is built.

This is modeled after the GDQuest save-game pattern (https://www.gdquest.com/library/save_game_godot4/): a single JSON-serializable Dictionary, written to `user://`, loaded on `_ready()`, saved immediately after mutation.

**This cache is device-local only, permanently.** It is not a staging area for future backend data and is explicitly out of scope for the eventual Firebase migration: it is never uploaded to, synced with, or restored from any server/database, and the Firebase migration will not touch or replace it. It is not shipped with the app (there is no bundled cache file — it is only ever created at runtime on the player's device). Consequently, a player on a new/different device always starts with no remembered login and default settings: they must log in again and reconfigure settings from scratch. This is intentional, not a gap to close later.

## Goals / Non-Goals
- Goals:
  - Create the cache file automatically on first run; load it on subsequent runs.
  - Store remembered login credentials so returning players are signed in automatically.
  - Ensure a changed password invalidates the remembered login instead of silently succeeding with stale credentials.
  - Provide a minimal, generic settings storage API for future use.
- Non-Goals:
  - Building a settings screen UI.
  - Building password-reset functionality.
  - Cryptographically strong secret storage — Godot's encrypted `FileAccess` uses an embedded passphrase, which only obfuscates the file from casual inspection/save-scumming, matching this project's existing "temporary, pre-Firebase" security posture.

## Decisions

### Decision: New `LocalCache` autoload, separate from `UserDatabase`
`UserDatabase` models the (future) shared backend / all registered accounts. `LocalCache` models purely device-local state (which account this device last used, this device's settings). Keeping them separate avoids conflating "server-side" user records with "client-side" device preferences, and keeps `UserDatabase` easy to swap for real Firebase Auth later without dragging device-cache concerns along.

Autoload order: `LocalCache` MUST be registered after `UserDatabase` in `project.godot` so that `UserDatabase` is fully initialized (users loaded from `res://data/user_database.json`) before `LocalCache._ready()` attempts an auto sign-in.

### Decision: Storage path `user://local_cache.dat`
Per Godot convention and the GDQuest tutorial, persistent per-device data belongs under `user://`, which is guaranteed writable on all export targets (unlike `res://`). The file extension is arbitrary (`.dat`) since the file is encrypted, not plain JSON.

### Decision: Encrypt the whole file with `FileAccess.open_encrypted_with_pass`
Godot exposes `FileAccess.open_encrypted_with_pass(path, mode, pass) -> FileAccess` which transparently AES-256 encrypts/decrypts the file contents. The cache is written as a single JSON-serialized Dictionary:
```gdscript
{
    "remembered_login": {"username": String, "password": String} or {},
    "settings": {"music_volume": float, "sfx_volume": float, "notifications_enabled": bool}
}
```
The passphrase is a constant embedded in `local_cache.gd`. This is explicitly **obfuscation, not real secret storage** (anyone with the game binary can extract the constant) — the same caveat already documented for `UserDatabase`'s SHA-256 hashing. This is acceptable because there is no real backend yet; this is called out in the proposal and should be revisited when Firebase Auth replaces `UserDatabase`.

### Decision: Auto sign-in re-uses `UserDatabase.sign_in()` rather than a custom hash comparison
Instead of duplicating password-verification logic, `LocalCache` simply calls `UserDatabase.sign_in(username, password)` with the remembered plaintext credentials during `_ready()`. This gets password-reset safety "for free": `sign_in()` re-hashes the remembered password and compares it against the account's *current* stored hash. If the account's password has since changed (by any future mechanism), the comparison fails naturally, auto sign-in fails, and `LocalCache` clears `remembered_login` so it doesn't retry every launch with known-stale credentials.

### Decision: "Remember me" is implicit, not an opt-in checkbox
Every successful login/registration calls `remember_login()` unconditionally (confirmed with stakeholder). Explicit logout (`LogOffButton`) calls `forget_login()` to clear the remembered credentials, so logging out is respected until the player logs in again.

## Risks / Trade-offs
- **Plaintext-adjacent credential storage**: the password is stored (encrypted-at-rest, but decrypt key is embedded) rather than a hash, because `UserDatabase.sign_in()` needs the plaintext password to verify. Mitigation: this mirrors the project's existing temporary/local-only security model; documented as a known limitation to fix when migrating to Firebase Auth (Firebase would use ID tokens/refresh tokens instead of raw passwords).
- **Autoload ordering coupling**: `LocalCache` depends on `UserDatabase` initializing first. Mitigation: documented explicitly in `project.godot` autoload order and in code comments.
- **Corrupted/unreadable cache file** (e.g. wrong Godot version, manual tampering): `LocalCache` SHALL treat a decrypt/parse failure as "no cache" and regenerate a fresh default cache file rather than crashing.

## Migration Plan
No existing data to migrate — this is a new file created on first run. No changes to `UserDatabase`'s existing storage format.

## Open Questions
None — clarified with stakeholder before writing this proposal (new autoload, `user://` storage, auto sign-in skips the login screen, remember-me is implicit, settings are a minimal placeholder, password-reset UI is out of scope).
