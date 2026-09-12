## 1. LocalCache Autoload Foundation
- [x] 1.1 Create `autoload/local_cache.gd` with `# uid://...` header line (per project GDScript UID convention)
- [x] 1.2 Define `DATABASE_PATH := "user://local_cache.dat"` and a `PASSPHRASE` constant, documented as obfuscation-only
- [x] 1.3 Define default cache structure: `{"remembered_login": {}, "settings": {"music_volume": 1.0, "sfx_volume": 1.0, "notifications_enabled": true}}`
- [x] 1.4 Implement `_load_cache()`: open with `FileAccess.open_encrypted_with_pass()`, parse JSON, fall back to defaults on missing/corrupt file (log a warning)
- [x] 1.5 Implement `_save_cache()`: serialize current state to JSON and write via `FileAccess.open_encrypted_with_pass()`
- [x] 1.6 Register `LocalCache` as an autoload in `project.godot`, positioned after `UserDatabase`

## 2. Remembered Login API
- [x] 2.1 Implement `remember_login(username: String, password: String) -> void`, updates in-memory state and calls `_save_cache()`
- [x] 2.2 Implement `forget_login() -> void`, clears `remembered_login` and calls `_save_cache()`
- [x] 2.3 In `_ready()`, if `remembered_login` is non-empty, call `UserDatabase.sign_in(username, password)`
- [x] 2.4 On auto sign-in failure, call `forget_login()` so stale credentials aren't retried next launch
- [x] 2.5 On auto sign-in success, log a confirmation message (console only, consistent with existing auth screens)

## 3. Settings API
- [x] 3.1 Implement `get_setting(key: String, default: Variant) -> Variant`
- [x] 3.2 Implement `set_setting(key: String, value: Variant) -> void`, updates in-memory state and calls `_save_cache()`

## 4. Wire Up Existing Screens
- [x] 4.1 In `register_login_screen.gd::_on_log_in_button_pressed()`, call `LocalCache.remember_login(username, password)` after a successful `sign_in()`
- [x] 4.2 In `account_registration_screen.gd::_on_create_account_button_pressed()`, call `LocalCache.remember_login(username, password)` after the automatic post-registration `sign_in()` succeeds
- [x] 4.3 In `account_management_screen.gd::_on_log_off_button_pressed()`, call `LocalCache.forget_login()` alongside the existing `UserDatabase.sign_out()`

## 5. Validation
- [x] 5.1 Manually test: fresh install (no cache file) launches without errors and creates `user://local_cache.dat`
- [x] 5.2 Manually test: log in, restart the game, confirm the app auto signs in without visiting the login screen
- [x] 5.3 Manually test: log off, restart the game, confirm the app shows the guest state (no auto sign-in)
- [x] 5.4 Manually test: with a remembered login cached, simulate a password change for that account directly in `UserDatabase`'s stored data, restart, and confirm auto sign-in fails safely and the guest state is shown
- [x] 5.5 Manually test: `get_setting()`/`set_setting()` round-trip persists across a restart
