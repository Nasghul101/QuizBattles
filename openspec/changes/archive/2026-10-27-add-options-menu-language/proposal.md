## Why

The account management screen already contains an Options popup (button, `OptionsPopUp`, `LanguageOptions` dropdown, `RevertChangesButton`), but nothing is wired up. Players cannot choose their app language. `Utils.set_app_locale()` and the `LocalCache` `locale` setting already exist, so the missing piece is the screen logic, plus Traditional Chinese support, which the dropdown lists but the app does not yet support.

## What Changes

- Implement the options logic in `account_management_screen.gd`:
  - Populate `LanguageOptions` selection from the active locale when the screen loads.
  - Selecting a language applies it immediately via `Utils.set_app_locale()` (persisted in `LocalCache`, device-local only, never in Firebase).
  - `RevertChangesButton` resets all UI options to defaults (locale back to OS-based detection, i.e. the stored `locale` is cleared) and refreshes the dropdown.
  - Structure the code so further options can be added later.
- Add Traditional Chinese (`zh_TW`) as a supported UI locale: new `zh_TW` column in `ui_translations.csv`, project translation/locale-filter settings.
- Add missing translation keys used by the popup (`COMMON_OPTIONS_BUTTON`, `OPTIONS_POPUP_SELECT_LANGUAGE`, `OPTIONS_POPUP_REVERT_CHANGES`).
- Make quiz question language follow the chosen app language: `TriviaQuestionService` resolves its language from the `locale` setting (`zh_TW` -> `questions_zt.json`) instead of the never-written `language` setting.
- Fix the unconnected `OptionsButton`/`OptionsPopUp` signal wiring in the scene if required, and remove the stub `_on_options_button_pressed`.

## Capabilities

### New Capabilities
- `account-options-menu`: Options popup on the account management screen, language selection and revert-to-defaults behavior.

### Modified Capabilities
- `ui-localization`: supported locales gain `zh_TW`; CSV gains a `zh_TW` column; OS-locale fallback handles Chinese variants.
- `trivia-question-service`: language resolution uses the persisted app `locale` and maps locales to question file codes.

## Impact

- `scenes/ui/account_ui/account_management_screen.gd` / `.tscn`
- `autoload/utils.gd` (supported locales, helper for OS locale mapping), `autoload/trivia_question_service.gd`
- `localization/ui_translations.csv` (+ re-import) and `project.godot` (`locale/translations`, `locale/locale_filter`)
- `tests/` (cache/locale tests)
- No Firebase/database changes.
