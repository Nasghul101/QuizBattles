# Change: Migrate Trivia Questions to a Local, Per-Language Database

## Why
`TriviaQuestionService` currently fetches questions from the Open Trivia Database API over HTTP, with `data/fallback_questions.json` used only when the API is unreachable. The game already ships a much larger, curated local question bank (`data/questions_en.json`) built by `tools/fetch_opentdb_questions.py`. Fetching from OpenTDB at runtime is unnecessary, adds network dependency/latency, and has no path to supporting languages other than English. Switching to the local database as the sole question source, organized per language, removes the network dependency and lays the groundwork for adding more languages later.

## What Changes
- **BREAKING**: `TriviaQuestionService` no longer calls the Open Trivia Database API. All OpenTDB integration (HTTPRequest usage, category-ID mapping, `data/fallback_questions.json` fallback) is removed.
- `fetch_questions(category, amount)` now loads questions from a local JSON file selected by the player's language setting, e.g. `data/questions_en.json`, `data/questions_de.json`.
- The user's language is read from `LocalCache.get_setting("language", <system locale>)`, defaulting to the device's system locale (via `OS.get_locale_language()`) when no explicit preference has been saved yet.
- If the resolved language has no local database file yet, the service silently falls back to `data/questions_en.json`.
- **BREAKING**: The `connection_error` and `api_failed` signals are removed, since there is no network call left that can fail in those ways. Callers only need `questions_ready`.
- The per-language database is parsed once and kept in memory for the app session; `clear_cache()` now clears these loaded databases instead of an API response cache.
- The Open Trivia DB category ID mapping is replaced by a fixed list of the 12 supported category names, since local database files are already keyed by consolidated category name.

## Impact
- Affected specs: `trivia-question-service`, `gameplay-screen-initialization`
- Affected code:
  - [autoload/trivia_question_service.gd](autoload/trivia_question_service.gd) - core rework
  - [scenes/ui/gameplay_screen.gd](scenes/ui/gameplay_screen.gd) - remove `api_failed` connection/handler
  - [scenes/ui/test_ui/trivia_service_test.gd](scenes/ui/test_ui/trivia_service_test.gd) - remove `connection_error`/`api_failed` handlers
  - `data/fallback_questions.json` - removed, no longer used
