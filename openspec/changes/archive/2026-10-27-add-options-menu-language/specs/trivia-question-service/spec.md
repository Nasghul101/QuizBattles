## MODIFIED Requirements

### Requirement: Language Resolution and Fallback
The service SHALL determine which local language database to use from the active app locale (the `LocalCache` `locale` setting, as applied by `Utils`), defaulting to the system locale, and SHALL silently fall back to English when the resolved language has no local file. App locales map to question file codes: `en` -> `en`, `de` -> `de`, `zh_TW` -> `zt`.

#### Scenario: No explicit language preference set
- **GIVEN** no `locale` value has been saved via `LocalCache`
- **WHEN** the service resolves the active language
- **THEN** the device's system locale (mapped to a supported app locale) determines the question language

#### Scenario: Explicit language preference set
- **GIVEN** `LocalCache` has a `locale` setting saved (e.g. `de`)
- **WHEN** the service resolves the active language
- **THEN** `questions_de.json` is used

#### Scenario: Traditional Chinese selected
- **GIVEN** the active app locale is `zh_TW`
- **WHEN** the service loads the language database
- **THEN** `res://data/questions_zt.json` is used

#### Scenario: Language changed at runtime
- **GIVEN** questions for one language have been loaded
- **WHEN** the player changes the app language and new questions are fetched
- **THEN** the questions come from the newly selected language's file

#### Scenario: Resolved language has no local database file
- **GIVEN** the resolved language has no local file
- **WHEN** the service loads the language database
- **THEN** it falls back to `questions_en.json` without error
