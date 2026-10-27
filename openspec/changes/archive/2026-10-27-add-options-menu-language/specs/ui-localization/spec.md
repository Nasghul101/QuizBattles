## MODIFIED Requirements

### Requirement: CSV Translation Source
The system SHALL store all static and dynamic player-facing UI text (excluding quiz question text and answer options from the `data/questions_<lang>.json` files, and developer-only test scenes) as translation keys in a CSV file (`localization/ui_translations.csv`) with columns `keys`, `en`, `de`, and `zh_TW`, imported as a Godot Translation resource.

#### Scenario: Translation key resolves to correct locale text
- **WHEN** the active locale is `de` and a UI element displays the key `SETUP_SCREEN_START_BUTTON`
- **THEN** the rendered text matches the `de` column value for that key in `ui_translations.csv`

#### Scenario: Traditional Chinese text resolves
- **WHEN** the active locale is `zh_TW` and a UI element displays a translation key
- **THEN** the rendered text matches the `zh_TW` column value for that key

#### Scenario: Quiz question and answer content is not part of the CSV
- **WHEN** a quiz question or answer option from a `data/questions_<lang>.json` file is displayed
- **THEN** its text is not looked up through `ui_translations.csv` translation keys

### Requirement: Locale Bootstrap and Fallback
On startup, the system SHALL determine the active locale by checking, in order: a stored player preference, the device's OS locale (if it maps to a supported locale), and otherwise English (`en`). Supported locales are `en`, `de` and `zh_TW`. OS Chinese locales using Traditional script or the TW/HK/MO regions SHALL map to `zh_TW`.

#### Scenario: No stored preference falls back to supported OS locale
- **WHEN** no locale preference is stored and the device's OS locale is `de`
- **THEN** the app starts in `de`

#### Scenario: Traditional Chinese OS locale
- **WHEN** no locale preference is stored and the device's OS locale is `zh_TW`
- **THEN** the app starts in `zh_TW`

#### Scenario: Unsupported OS locale falls back to English
- **WHEN** no locale preference is stored and the device's OS locale is not `en`, `de` or a Traditional Chinese locale
- **THEN** the app starts in `en`

## ADDED Requirements

### Requirement: Clearing the Stored Locale
The system SHALL provide a function to clear the stored locale preference and re-apply the startup resolution (OS locale, then `en`) at runtime.

#### Scenario: Reset locale to system default
- **WHEN** the reset function is called with a stored locale `de` and OS locale `en`
- **THEN** the stored `locale` is empty and the active locale is `en`
