# Change: Add UI Localization System

## Why
All player-facing UI text (buttons, labels, popups) is hardcoded in English directly inside `.tscn` scene files and `.gd` scripts, which blocks translating the game into other languages. Quiz question and answer content already has its own translation pipeline via `data/questions_en.json` / `data/questions_de.json` and must stay untouched. Category names, however, are **not** translated by that pipeline (both JSON files use the same English category identifiers as canonical keys), so they are in scope for this change and must be translated for display while the canonical English identifier is still used for category matching, color lookups, and question filtering.

## What Changes
- Add a CSV-based translation resource (`localization/ui_translations.csv`) with one row per translation key and one column per supported locale (`en`, `de`), imported as a Godot Translation resource via Project Settings → Localization.
- Introduce a translation key naming convention and migrate every hardcoded `text = "..."` UI string in `.tscn` files, plus every `.gd` script that assigns `.text` dynamically, to use translation keys resolved through `tr()`.
- Add a `Utils.translate_category(category_name)` helper that maps a canonical English category name (e.g. `"General Knowledge"`) to a `CATEGORY_*` translation key for display, while callers keep using the canonical name for color lookups and question filtering.
- Add a `locale` setting to `LocalCache` to persist the player's chosen language across launches.
- Add a locale bootstrap routine run at startup: stored preference → OS locale (if supported) → English fallback.
- Add a `set_locale()`-style API (e.g. on `Utils` or a new autoload) that applies a locale immediately via `TranslationServer.set_locale()` and persists it — no UI entry point is added in this change; it will be wired into a settings screen in a future change.
- **Explicitly excluded**: quiz question text and answer options sourced from `data/questions_en.json` / `data/questions_de.json`, and the developer-only scenes under `scenes/ui/test_ui/`.

## Impact
- Affected specs: `ui-localization` (new capability)
- Affected code: `project.godot` (localization settings), new `localization/ui_translations.csv`, `autoload/local_cache.gd` (locale setting), `autoload/utils.gd` (locale bootstrap/switching, `translate_category` helper), all `scenes/ui/**/*.tscn` files (excluding `test_ui/`) with hardcoded text, and `.gd` scripts that assign `.text` dynamically (e.g. `category_popup_component.gd`, `friendly_duel_button.gd`, `result_component.gd`, `category_statistic_dissplay.gd`, `quiz_screen.gd`).
