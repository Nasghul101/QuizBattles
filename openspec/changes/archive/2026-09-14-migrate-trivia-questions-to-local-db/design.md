## Context
`TriviaQuestionService` is an autoload singleton consumed by `gameplay_screen.gd` (real gameplay) and `trivia_service_test.gd` (manual test scene). It currently fetches from the Open Trivia Database API and falls back to `data/fallback_questions.json` on failure. The project already builds a much larger local database per language via `tools/fetch_opentdb_questions.py` → `data/questions_en.json`, organized by the same 12 top-level category names the service already exposes via `get_available_categories()`. The user wants questions to be read exclusively from these local, per-language files going forward, with language selected explicitly (defaulting to system locale) and unsupported languages silently falling back to English.

## Goals / Non-Goals
- Goals:
  - Replace OpenTDB as the question source with local per-language JSON files.
  - Resolve the active language from an explicit `LocalCache` setting, defaulting to the system locale.
  - Silently fall back to English when the resolved language has no local file yet.
  - Keep `fetch_questions()` async/signal-based (`questions_ready`) so existing call sites need minimal changes.
  - Make adding a new language a pure data change: drop `data/questions_<lang>.json` next to `questions_en.json`, no code changes required.
- Non-Goals:
  - No settings-screen UI to let players pick a language (out of scope; only the data-layer read/default behavior is implemented).
  - No translation of the fixed category names themselves (e.g. "History" stays "History" regardless of language file).
  - No change to the question dictionary shape consumed by quiz screens.

## Decisions
- **Language resolution**: `_get_user_language()` calls `LocalCache.get_setting("language", OS.get_locale_language())`. `LocalCache` requires no changes — its existing generic `get_setting`/`set_setting` API already supports an unset `"language"` key (see its spec's `"Reading an unknown setting key returns the provided default"` scenario). This keeps the change scoped to `trivia_question_service.gd` only.
- **File naming convention**: `res://data/questions_<ISO 639-1 code>.json`, matching the existing `questions_en.json`. Adding a language later is just adding a new file with this name.
- **Missing language file → English fallback**: if `res://data/questions_<lang>.json` does not exist, resolve to `res://data/questions_en.json` instead, silently (no error signal). This keeps the game playable in unsupported locales without needing translated content for every language immediately.
- **Remove OpenTDB integration entirely**: `HTTPRequest`, `API_BASE_URL`, `CATEGORY_MAPPING` (with OpenTDB numeric IDs), `_get_category_id()`, `_on_request_completed()`, `_load_fallback_questions()` (pointed at `data/fallback_questions.json`), and the `connection_error`/`api_failed` signals are all removed. There is no network call left that can fail in those specific ways, and keeping the signals around unused would be misleading dead API surface.
- **Category list becomes a plain constant**: since local files already key questions by the 12 consolidated category names directly (verified: `data/questions_en.json` top-level keys are `General Knowledge`, `Entertainment`, `Science`, `History`, `Geography`, `Sports`, `Art`, `Animals`, `Mythology`, `Politics`, `Celebrities`, `Vehicles`), the OpenTDB subcategory-ID mapping is replaced by a fixed `CATEGORIES: Array[String]` constant used for both validation and `get_available_categories()`.
- **In-memory caching model changes from a "consumed API response queue" to a "loaded language database"**: on first request for a language, the service parses the whole JSON file once into `_loaded_databases[language] = {category: Array[Dictionary]}` and keeps it resident for the app session (no eviction). This is a deliberate simplification over the old 50-question eviction cache, which existed to bound memory from trickling API responses — that concern doesn't apply to a single, already-bounded local JSON parse held once per language actually used (typically just one language per session).
- **No cross-call consume/dedupe queue**: each `fetch_questions(category, amount)` call takes a random sample of `amount` questions from that category's in-memory array (shuffled copy, no repeats *within* one call). Unlike the old API cache, results are not removed from the in-memory database, so the same question can be served again in a later, separate call within the same session. This trades perfect no-repeat guarantees for simplicity; the local databases are large enough (hundreds of questions per category) that immediate repeats are unlikely in a single match (6 rounds × 3 questions).
- **`has_cached_questions()` / `get_cached_questions()` are removed from the public API**: they were only ever called internally to implement the old consume-cache and are not used by any other script. `clear_cache()` and `get_available_categories()` are kept (both are used by `trivia_service_test.gd` / `gameplay_screen.gd`), with `clear_cache()` now clearing `_loaded_databases` instead.
- **`data/fallback_questions.json` is deleted**: it's fully superseded by `data/questions_en.json`, which already contains the same categories with far more questions.

## Risks / Trade-offs
- Holding a whole language's parsed JSON in memory for the app session uses more RAM than the old bounded 50-question cache, in exchange for avoiding repeated disk reads/parses. `data/questions_en.json` is a few MB of text; parsed into Godot Dictionaries this is acceptable on modern mobile devices but should be revisited if more languages are loaded simultaneously (only one language is expected to be loaded per session in practice, since language is a per-device setting).
- Removing `connection_error`/`api_failed` is a breaking signal-contract change for any other future callers; both current callers (`gameplay_screen.gd`, `trivia_service_test.gd`) are updated as part of this change's tasks.
- Silent fallback to English for unsupported languages means a player who sets an unsupported language will see English questions with no in-app indication that their language isn't available yet.

## Migration Plan
- No persisted user data migrates; `LocalCache.get_setting("language", ...)` simply returns the provided default (system locale) until a future settings screen calls `set_setting("language", ...)`.
- `data/fallback_questions.json` is deleted since `data/questions_en.json` is a strict superset of its categories with more content.
- Existing callers (`gameplay_screen.gd`, `trivia_service_test.gd`) drop their `connection_error`/`api_failed` connections and handlers.

## Open Questions
None — clarified with the user before drafting this proposal.
