## ADDED Requirements
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
The service SHALL determine which local language database to use, defaulting to the system locale, and SHALL silently fall back to English when the resolved language has no local file.

#### Scenario: No explicit language preference set
**Given** no `"language"` value has been saved via `LocalCache`
**When** the service resolves the active language
**Then** it uses `LocalCache.get_setting("language", OS.get_locale_language())`
**And** the device's system locale language code is used as the effective language

#### Scenario: Explicit language preference set
**Given** `LocalCache` has a `"language"` setting saved (e.g. `"de"`)
**When** the service resolves the active language
**Then** it uses that saved value instead of the system locale

#### Scenario: Resolved language has no local database file
**Given** the resolved language is `"fr"`
**And** `res://data/questions_fr.json` does not exist
**When** the service loads the language database
**Then** it silently loads `res://data/questions_en.json` instead
**And** does not emit any error signal

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

## MODIFIED Requirements
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

## REMOVED Requirements
### Requirement: API Integration
**Reason**: The service no longer calls the Open Trivia Database API; all questions come from local per-language JSON files bundled with the game.
**Migration**: See the new "Local Language Database Loading" requirement.

### Requirement: Category Mapping
**Reason**: Open Trivia Database subcategory IDs are no longer needed. Local database files already key questions directly by the 12 consolidated category names.
**Migration**: See the new "Category Validation" requirement.

### Requirement: Session-Based Caching
**Reason**: Replaced by a simpler "load once per language, keep resident for the session" model that doesn't need a consume/eviction pattern designed for trickling API responses.
**Migration**: See the "Loaded Language Database Caching" requirement.

### Requirement: Fallback to Local Questions
**Reason**: Local JSON is now the primary and only source; there is no remote API to fall back from. Missing-language handling is covered by the new "Language Resolution and Fallback" requirement.
**Migration**: See the new "Language Resolution and Fallback" requirement.

### Requirement: Error State Management
**Reason**: `connection_error` and `api_failed` signals no longer apply since there is no network request that can fail in those ways.
**Migration**: Callers only need to handle `questions_ready`, treating an empty array as a failure to obtain questions.

### Requirement: Memory Management
**Reason**: The 50-question eviction cap existed to bound memory from trickling, per-category API responses. It no longer applies now that a language database is parsed once and held resident for the session.
**Migration**: See the "Loaded Language Database Caching" requirement.

### Requirement: Public API
**Reason**: Replaced by "Local Question Fetching API". `has_cached_questions()` and `get_cached_questions()` are removed since they only supported the old consume-cache pattern and are not used by any other script.
**Migration**: See the new "Local Question Fetching API" requirement. Callers relying on `questions_ready` are unaffected.