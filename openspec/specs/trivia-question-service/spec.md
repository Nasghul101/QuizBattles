# trivia-question-service Specification

## Purpose
A singleton autoload service that fetches trivia questions from the Open Trivia Database API, caches them in memory, and provides fallback to local questions when the API is unavailable. Consolidates Open Trivia DB categories and returns questions in their native format for use by quiz screens.

## Requirements

### Requirement: Question Format Compatibility
The service SHALL return questions in a consistent format expected by quiz screens, regardless of the source language file.

#### Scenario: Return questions in correct format
**Given** questions are read from a local language database
**When** returned to the caller
**Then** each question dictionary contains:
- `"question"` (String): The question text
- `"correct_answer"` (String): The correct answer
- `"incorrect_answers"` (Array of 3 Strings): The wrong answers
- `"category"` (String): The question category
- `"difficulty"` (String): The difficulty level (easy/medium/hard)

#### Scenario: No transformation of API data
**Given** questions are read from the local language database
**When** the service processes them
**Then** it returns the question text as-is without decoding or transformation
**Because** local database files are already stored as plain, decoded UTF-8 text (no HTML entities to unescape)

#### Scenario: Category field is normalized to the requested top-level category
**Given** a question is read from the local database under a top-level category key
**When** the service returns it
**Then** the `"category"` field on the returned dictionary is overwritten with that top-level category name

---

### Requirement: Initialization
The service SHALL initialize itself when loaded as an autoload, without establishing any network resources.

#### Scenario: Autoload initialization
**Given** the game starts
**When** the Godot engine loads autoload singletons
**Then** the TriviaQuestionService initializes with empty loaded-database state
**And** is ready to handle `fetch_questions()` calls, loading the relevant language file lazily on first use

---

### Requirement: Local Language Database Loading
The service SHALL load trivia questions from a local, per-language JSON file instead of a remote API.

#### Scenario: Load the database for the resolved language
**Given** the service resolves the player's language (e.g. `"en"`)
**When** `fetch_questions(category: String, amount: int)` is called for the first time in a session for that language
**Then** the service reads and parses `res://data/questions_<language>.json`
**And** caches the parsed contents in memory keyed by language
**And** subsequent calls for the same language reuse the cached parse without re-reading the file

#### Scenario: Return questions for a valid category
**Given** the language database is loaded
**When** `fetch_questions(category, amount)` is called with a category present in the database
**Then** the service selects up to `amount` questions from that category's array without repeating a question within the same call
**And** emits `questions_ready` with the resulting array

#### Scenario: Handle a category missing from the database
**Given** the language database is loaded
**When** `fetch_questions(category, amount)` is called with a category not present in the database
**Then** the service logs a warning
**And** emits `questions_ready` with an empty array

---

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

---

### Requirement: Category Validation
The service SHALL validate requested categories against a fixed list of supported category names, since local database files are already organized by these consolidated category names.

#### Scenario: List available categories
**Given** a caller wants to know which categories can be requested
**When** they call `get_available_categories() -> Array[String]`
**Then** the service returns the 12 supported category names (`General Knowledge`, `Entertainment`, `Science`, `History`, `Geography`, `Sports`, `Art`, `Animals`, `Mythology`, `Politics`, `Celebrities`, `Vehicles`)

---

### Requirement: Loaded Language Database Caching
The service SHALL keep each loaded language's question database resident in memory for the duration of the app session to avoid repeated disk reads and JSON parsing.

#### Scenario: Reuse a loaded database across requests
**Given** questions for language `"en"` have already been loaded once
**When** `fetch_questions()` is called again for any category in that language
**Then** the service reuses the in-memory parsed database
**And** does not re-read or re-parse `res://data/questions_en.json`

#### Scenario: Cache persists across scene changes
**Given** a language database is loaded in the service
**When** the current scene changes (e.g. from Category Selection to Question Screen)
**Then** the loaded database remains available
**Because** the service is an autoload and survives scene transitions

#### Scenario: Clear loaded databases on demand
**Given** the service has one or more loaded language databases in memory
**When** `clear_cache()` is called
**Then** all loaded databases are removed from memory
**And** the next `fetch_questions()` call reloads the relevant language file from disk

---

### Requirement: Local Question Fetching API
The service SHALL provide a simple, async-friendly API for fetching questions from the local language database.

#### Scenario: Async question fetching
**Given** a caller wants to fetch questions
**When** they call `fetch_questions(category: String, amount: int)`
**Then** the service returns immediately (non-blocking)
**And** emits a `questions_ready(questions: Array)` signal once the questions have been read from the local database

#### Scenario: Clear all loaded databases
**Given** a caller wants to force a reload of language data
**When** they call `clear_cache()`
**Then** all in-memory loaded language databases are cleared

---
