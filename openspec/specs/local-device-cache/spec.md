# local-device-cache Specification

## Purpose
TBD - created by archiving change add-local-device-cache. Update Purpose after archive.

## Requirements

### Requirement: Cache File Creation on First Run
The system SHALL create a new local device cache file if none exists when the game starts, and SHALL load the existing file otherwise.

**Rationale:** Ensure the cache is always available without requiring manual setup, and never lose previously stored data on subsequent launches.

#### Scenario: First launch creates a new cache file
**Given** no cache file exists at `user://local_cache.dat`  
**When** the `LocalCache` autoload initializes  
**Then** a new cache file SHALL be created with default `remembered_login: {}` and default `settings`  
**And** the file SHALL be written using `FileAccess.open_encrypted_with_pass()`

#### Scenario: Subsequent launch loads the existing cache file
**Given** a cache file already exists at `user://local_cache.dat`  
**When** the `LocalCache` autoload initializes  
**Then** the existing file SHALL be decrypted and parsed  
**And** its `remembered_login` and `settings` values SHALL be loaded into memory  
**And** no new file SHALL overwrite the existing data

#### Scenario: Corrupted or unreadable cache file is treated as missing
**Given** a cache file exists at `user://local_cache.dat` but cannot be decrypted or parsed as valid JSON  
**When** the `LocalCache` autoload initializes  
**Then** the system SHALL log a warning  
**And** SHALL fall back to default `remembered_login: {}` and default `settings`  
**And** SHALL overwrite the corrupted file with a fresh default cache

---

### Requirement: Encrypted Storage
The system SHALL store the cache file contents encrypted at rest using Godot's built-in encrypted file API.

**Rationale:** Avoid storing the username and password in a plain, human-readable file on the device.

#### Scenario: Cache file is written encrypted
**Given** the `LocalCache` autoload needs to persist its in-memory state  
**When** `_save_cache()` is called  
**Then** the JSON-serialized cache Dictionary SHALL be written via `FileAccess.open_encrypted_with_pass(DATABASE_PATH, FileAccess.WRITE, PASSPHRASE)`  
**And** opening the raw file with a plain text editor SHALL NOT reveal the username or password in plaintext

---

### Requirement: Remember Login Credentials
The system SHALL provide a `remember_login(username: String, password: String) -> void` method that stores the given credentials in the cache and persists them to disk immediately.

**Rationale:** Allow calling screens to opt every successful login/registration into remembered auto sign-in.

#### Scenario: Remember login stores and persists credentials
**Given** a user "Player123" just signed in successfully with password "hunter2"  
**When** `LocalCache.remember_login("Player123", "hunter2")` is called  
**Then** the cache's `remembered_login` SHALL be set to `{"username": "Player123", "password": "hunter2"}`  
**And** the cache file SHALL be saved to disk immediately

---

### Requirement: Forget Login Credentials
The system SHALL provide a `forget_login() -> void` method that clears any remembered login credentials and persists the change to disk immediately.

**Rationale:** Respect an explicit user sign-out by preventing the next launch from automatically logging the same account back in.

#### Scenario: Forget login clears remembered credentials
**Given** the cache has `remembered_login: {"username": "Player123", "password": "hunter2"}`  
**When** `LocalCache.forget_login()` is called  
**Then** the cache's `remembered_login` SHALL be set to `{}`  
**And** the cache file SHALL be saved to disk immediately

---

### Requirement: Automatic Sign-In on Startup
The system SHALL attempt to automatically sign in the remembered user, if any, during `LocalCache` autoload initialization, by calling `UserDatabase.sign_in()` with the remembered credentials.

**Rationale:** Let returning players skip the login screen without requiring a separate, duplicated credential-verification mechanism.

**Constraints:**
- `LocalCache` MUST be initialized after `UserDatabase` in the autoload order so `UserDatabase` has already loaded its user records.

#### Scenario: Auto sign-in succeeds with valid remembered credentials
**Given** the cache has `remembered_login: {"username": "Player123", "password": "hunter2"}`  
**And** "Player123" exists in `UserDatabase` with password "hunter2"  
**When** the `LocalCache` autoload initializes  
**Then** `UserDatabase.sign_in("Player123", "hunter2")` SHALL be called  
**And** on success, `UserDatabase.is_signed_in()` SHALL return true afterward  
**And** the main lobby SHALL treat the player as already logged in without visiting the login screen

#### Scenario: Auto sign-in fails and clears stale credentials after a password change
**Given** the cache has `remembered_login: {"username": "Player123", "password": "old_password"}`  
**And** "Player123" exists in `UserDatabase` with a current password of "new_password" (changed since the credentials were cached)  
**When** the `LocalCache` autoload initializes  
**Then** `UserDatabase.sign_in("Player123", "old_password")` SHALL fail with `error_code: "INVALID_PASSWORD"`  
**And** the player SHALL NOT be automatically signed in  
**And** the cache's `remembered_login` SHALL be cleared and persisted so the stale credentials are not retried on the next launch

#### Scenario: No remembered login means no auto sign-in attempt
**Given** the cache has `remembered_login: {}`  
**When** the `LocalCache` autoload initializes  
**Then** no call to `UserDatabase.sign_in()` SHALL be made  
**And** the player SHALL see the normal guest state on the main lobby

---

### Requirement: In-Game Settings Storage
The system SHALL provide a generic key-based settings store within the cache, with `get_setting(key: String, default: Variant) -> Variant` and `set_setting(key: String, value: Variant) -> void` methods, initialized with a minimal set of default settings.

**Rationale:** Give a future settings screen a ready-made, persistent place to read and write user preferences without needing its own storage mechanism.

**Default settings:**
- `music_volume: float = 1.0`
- `sfx_volume: float = 1.0`
- `notifications_enabled: bool = true`

#### Scenario: Reading a default setting before it is ever changed
**Given** a freshly created cache file  
**When** `LocalCache.get_setting("music_volume", 1.0)` is called  
**Then** it SHALL return `1.0`

#### Scenario: Reading an unknown setting key returns the provided default
**Given** the cache does not contain a key `"language"`  
**When** `LocalCache.get_setting("language", "en")` is called  
**Then** it SHALL return `"en"` without raising an error

#### Scenario: Writing a setting persists it immediately
**Given** a cache file already exists  
**When** `LocalCache.set_setting("music_volume", 0.5)` is called  
**Then** the in-memory `settings.music_volume` SHALL become `0.5`  
**And** the cache file SHALL be saved to disk immediately  
**And** a subsequent `LocalCache.get_setting("music_volume", 1.0)` SHALL return `0.5`
