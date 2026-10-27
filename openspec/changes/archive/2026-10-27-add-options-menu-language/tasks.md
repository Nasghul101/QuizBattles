## 1. Localization infrastructure

- [x] 1.1 Add `zh_TW` to `Utils.SUPPORTED_LOCALES`; refactor `_bootstrap_locale` into `_resolve_locale()` with Traditional Chinese OS-locale mapping
- [x] 1.2 Add `Utils.reset_app_locale()` (clear stored `locale`, re-apply resolved locale)
- [x] 1.3 Add `zh_TW` column and translations for all rows in `localization/ui_translations.csv`; add `COMMON_OPTIONS_BUTTON`, `OPTIONS_POPUP_SELECT_LANGUAGE`, `OPTIONS_POPUP_REVERT_CHANGES` in all columns
- [x] 1.4 Re-import the CSV, register `ui_translations.zh_TW.translation` and `zh_TW` in `project.godot` translations/locale filter

## 2. Questions follow language

- [x] 2.1 Update `TriviaQuestionService._get_user_language()` to use the `locale` setting and map `zh_TW` -> `zt`, with English fallback
- [x] 2.2 Update/add tests for language resolution

## 3. Account management screen options

- [x] 3.1 Remove stub `_on_options_button_pressed`; confirm `OptionsButton` opens and `ClosePopUpButton` closes `OptionsPopUp`
- [x] 3.2 In `account_management_screen.gd` add `LANGUAGE_LOCALES`, `_load_options()` (select dropdown entry from active locale), called early in `_ready()`
- [x] 3.3 Implement and connect `_on_language_options_item_selected(index)` calling `Utils.set_app_locale()`
- [x] 3.4 Implement and connect `_on_revert_changes_button_pressed()` calling `Utils.reset_app_locale()` then `_load_options()`

## 4. Verification

- [x] 4.1 Add tests for locale persistence/reset (extend `tests/local_cache_settings_test.gd` or new test)
- [x] 4.2 Manually verify in Godot: switch en/de/zh_TW, restart persistence, revert, CJK glyph rendering, question language
