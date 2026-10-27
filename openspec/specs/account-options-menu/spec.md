# account-options-menu Specification

## Purpose
Defines the Options popup on the account management screen, where players adjust device-local UI options such as the app language.

## Requirements

### Requirement: Options Popup Opens and Closes
The account management screen SHALL open the `OptionsPopUp` when `OptionsButton` is pressed and close it via `ClosePopUpButton`.

#### Scenario: Open options popup
- **WHEN** the player presses `OptionsButton`
- **THEN** `OptionsPopUp` is shown

#### Scenario: Close options popup
- **WHEN** the player presses `ClosePopUpButton`
- **THEN** `OptionsPopUp` is hidden

### Requirement: Language Dropdown Reflects Active Locale
The `LanguageOptions` dropdown SHALL offer English (`en`), Deutsch (`de`) and 繁體中文 (`zh_TW`), and SHALL show the currently active app locale as selected when the screen loads.

#### Scenario: Dropdown shows active language
- **WHEN** the account management screen loads while the active locale is `de`
- **THEN** `LanguageOptions` has "Deutsch" selected

### Requirement: Language Selection Applies Immediately
Selecting an entry in `LanguageOptions` SHALL immediately apply that locale through `Utils.set_app_locale()`, updating visible UI text and persisting the choice in `LocalCache` settings. Options SHALL NOT be written to the Firebase/user database.

#### Scenario: Select a language
- **WHEN** the player selects "Deutsch"
- **THEN** visible translated UI switches to German immediately
- **AND** `LocalCache` setting `locale` equals `de`
- **AND** no user database write occurs

#### Scenario: Selection persists across restarts
- **WHEN** the player selects "繁體中文" and relaunches the app
- **THEN** the app starts in `zh_TW` and the dropdown shows "繁體中文"

### Requirement: Revert Options to Defaults
`RevertChangesButton` SHALL reset all UI options to their defaults. For language, the stored `locale` is cleared and the active locale is re-resolved from the device OS locale (falling back to `en`); the dropdown SHALL update to match.

#### Scenario: Revert language to system language
- **WHEN** the player has chosen `de`, the device language is `en`, and the player presses `RevertChangesButton`
- **THEN** the stored `locale` setting is empty
- **AND** the active locale is `en` and UI text updates immediately
- **AND** `LanguageOptions` shows "English"

#### Scenario: Unsupported system language
- **WHEN** the device language is not supported and the player presses `RevertChangesButton`
- **THEN** the active locale is `en`

### Requirement: Extensible Option List
Option handling in `account_management_screen.gd` SHALL be organized so additional options can be added by extending a single load/apply/reset path.

#### Scenario: Revert covers all options
- **WHEN** `RevertChangesButton` is pressed
- **THEN** every option handled by the options popup is reset to its default
