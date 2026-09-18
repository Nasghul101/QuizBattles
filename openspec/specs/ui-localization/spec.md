# ui-localization Specification

## Purpose
Provides CSV-based localization of player-facing UI text (screens, components, and category names), with a persisted, runtime-switchable locale, so the game can be played in multiple languages. Quiz question/answer content keeps its own separate translation pipeline via `data/questions_en.json` / `data/questions_de.json`.

## Requirements

### Requirement: CSV Translation Source
The system SHALL store all static and dynamic player-facing UI text (excluding quiz question text and answer options from `data/questions_en.json` / `data/questions_de.json`, and developer-only test scenes) as translation keys in a CSV file (`localization/ui_translations.csv`) with columns `keys`, `en`, and `de`, imported as a Godot Translation resource.

#### Scenario: Translation key resolves to correct locale text
- **WHEN** the active locale is `de` and a UI element displays the key `SETUP_SCREEN_START_BUTTON`
- **THEN** the rendered text matches the `de` column value for that key in `ui_translations.csv`

#### Scenario: Quiz question and answer content is not part of the CSV
- **WHEN** a quiz question or answer option from `data/questions_en.json` / `data/questions_de.json` is displayed
- **THEN** its text is not looked up through `ui_translations.csv` translation keys

### Requirement: UI Text Uses Translation Keys
All hardcoded English UI text in `.tscn` scene files (excluding `scenes/ui/test_ui/`) and in `.gd` scripts that assign `.text` dynamically SHALL be replaced with translation keys resolved via Godot's automatic Control translation or explicit `tr()` calls.

#### Scenario: Static scene text is translated automatically
- **WHEN** a `Label` or `Button` node's `text` property is set to a translation key in a `.tscn` file
- **THEN** the node displays the translated string for the current locale without additional script code

#### Scenario: Dynamically built text is translated explicitly
- **WHEN** a script assigns `.text` at runtime using a translation key wrapped in `tr(...)`
- **THEN** the displayed text reflects the current locale, including any interpolated values

### Requirement: Category Name Translation
The system SHALL translate category names for display using a derived `CATEGORY_*` translation key, while code that matches, colors, or filters by category continues to use the canonical English category name unchanged.

#### Scenario: Category name is translated for display
- **WHEN** the active locale is `de` and a category named `"Science"` is shown on a category button, statistics tile, or quiz/result label
- **THEN** the displayed text matches the `de` column value for `CATEGORY_SCIENCE`

#### Scenario: Category selection still uses the canonical name
- **WHEN** a player selects a translated category button in the category popup
- **THEN** the emitted category name used for question filtering and color lookup is the original canonical English identifier, not the translated display text

#### Scenario: Unmapped category falls back to its canonical name
- **WHEN** a category name has no matching `CATEGORY_*` key in `ui_translations.csv`
- **THEN** the category is displayed using its original (English) name instead of a raw translation key

### Requirement: Locale Persistence
The system SHALL persist the player's selected locale in `LocalCache` settings and restore it on subsequent app launches.

#### Scenario: Selected locale persists across restarts
- **WHEN** a player selects a supported locale and later relaunches the app
- **THEN** the app starts in the previously selected locale without requiring the player to re-select it

### Requirement: Locale Bootstrap and Fallback
On startup, the system SHALL determine the active locale by checking, in order: a stored player preference, the device's OS locale (if it is a supported locale), and otherwise English (`en`).

#### Scenario: No stored preference falls back to supported OS locale
- **WHEN** no locale preference is stored and the device's OS locale is `de`
- **THEN** the app starts in `de`

#### Scenario: Unsupported OS locale falls back to English
- **WHEN** no locale preference is stored and the device's OS locale is not `en` or `de`
- **THEN** the app starts in `en`

### Requirement: Runtime Locale Switching API
The system SHALL provide a function to change the active locale at runtime that immediately updates currently visible auto-translated UI and persists the new selection, without requiring an app restart.

#### Scenario: Switching locale updates visible UI immediately
- **WHEN** the locale-switching function is called with a supported locale while a screen using translation keys is visible
- **THEN** all auto-translated Control text on that screen updates to the new locale immediately
