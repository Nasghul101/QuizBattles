# local-device-cache Specification

## Purpose
Defines local persistence for device-scoped settings and cached application state.

## Requirements

### Requirement: Cache File Creation on First Run
The system SHALL create a device-local cache for settings on first run and SHALL load existing device settings on later runs. The cache SHALL NOT require or create a `remembered_login` entry.

**Rationale:** Keep device preferences local while delegating authentication-session persistence to Firebase Auth.

#### Scenario: First launch creates a settings cache
- **GIVEN** no cache file exists
- **WHEN** LocalCache initializes
- **THEN** it creates a cache containing default settings
- **AND** it does not store user credentials

#### Scenario: Subsequent launch loads settings
- **GIVEN** a cache file contains device settings
- **WHEN** LocalCache initializes
- **THEN** those settings are loaded without treating the cache as the authentication source

#### Scenario: First launch creates a new cache file
- **GIVEN** no cache file exists
- **WHEN** LocalCache initializes
- **THEN** a settings cache is created using encrypted file storage
- **AND** it contains no remembered credentials

#### Scenario: Subsequent launch loads the existing cache file
- **GIVEN** a cache file already exists
- **WHEN** LocalCache initializes
- **THEN** its settings are loaded without overwriting them

#### Scenario: Corrupted or unreadable cache file is treated as missing
- **GIVEN** the cache file cannot be decrypted or parsed
- **WHEN** LocalCache initializes
- **THEN** a warning is logged and default settings are persisted
- **AND** no remembered credentials are recreated

### Requirement: Encrypted Storage
The system SHALL store the cache file contents encrypted at rest using Godot's built-in encrypted file API.

**Rationale:** Avoid storing the username and password in a plain, human-readable file on the device.

#### Scenario: Cache file is written encrypted
**Given** the `LocalCache` autoload needs to persist its in-memory state  
**When** `_save_cache()` is called  
**Then** the JSON-serialized cache Dictionary SHALL be written via `FileAccess.open_encrypted_with_pass(DATABASE_PATH, FileAccess.WRITE, PASSPHRASE)`  
**And** opening the raw file with a plain text editor SHALL NOT reveal the username or password in plaintext

---

### Requirement: In-Game Settings Storage
The system SHALL provide a generic key-based settings store that persists device preferences locally and does not synchronize them to Firebase.

**Rationale:** Keep device-scoped preferences separate from shared account data.

#### Scenario: Read and write a device setting
- **GIVEN** a setting is changed
- **WHEN** `set_setting()` persists it
- **THEN** a later `get_setting()` returns the stored value on that device
- **AND** the setting is not written to Firebase

#### Scenario: Reading a default setting before it is ever changed
- **GIVEN** a fresh settings cache
- **WHEN** a default setting is read
- **THEN** the documented default is returned

#### Scenario: Reading an unknown setting key returns the provided default
- **GIVEN** the settings cache has no value for the requested key
- **WHEN** `get_setting()` is called with a default
- **THEN** the supplied default is returned

#### Scenario: Writing a setting persists it immediately
- **GIVEN** a cache file exists
- **WHEN** `set_setting()` changes a value
- **THEN** the change is persisted locally and returned by a later read

### Requirement: Restore Firebase Auth Sessions Without Cached Passwords
The system SHALL restore a remembered Firebase Auth session from the GodotFirebase encrypted auth file and SHALL load the matching Firestore profile before exposing a signed-in user.

#### Scenario: Restore a valid session
- **GIVEN** a valid encrypted Firebase Auth session exists
- **WHEN** the application starts
- **THEN** Firebase Auth refreshes the session and the associated profile is loaded
- **AND** LocalCache does not read or store an email/password pair

#### Scenario: Clear an invalid remembered session
- **GIVEN** an encrypted Auth session is expired or rejected
- **WHEN** session restoration completes
- **THEN** the invalid Auth session is cleared
- **AND** the user remains signed out with the Firebase error surfaced

### Requirement: Remove Legacy Remembered Credentials
The system SHALL discard the old `remembered_login` entry when loading the device cache and SHALL preserve the user's device settings.

#### Scenario: Remove previously cached credentials
- **GIVEN** the existing encrypted device cache contains `remembered_login`
- **WHEN** the updated application loads the cache
- **THEN** the old credentials are not used for sign-in
- **AND** the cache is saved without `remembered_login`
- **AND** existing settings remain unchanged
