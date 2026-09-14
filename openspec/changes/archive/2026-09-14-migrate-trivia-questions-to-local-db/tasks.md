## 1. Language resolution
- [x] 1.1 Add `DEFAULT_LANGUAGE := "en"` and `LANGUAGE_FILE_PATH_TEMPLATE := "res://data/questions_%s.json"` constants to `trivia_question_service.gd`
- [x] 1.2 Implement `_get_user_language() -> String` reading `LocalCache.get_setting("language", OS.get_locale_language())`
- [x] 1.3 Implement `_resolve_language_file_path(language: String) -> String` that returns the language-specific path if `FileAccess.file_exists()`, otherwise falls back to the English path

## 2. Local database loading
- [x] 2.1 Replace `CATEGORY_MAPPING` (OpenTDB IDs) with a `CATEGORIES: Array[String]` constant listing the 12 supported category names
- [x] 2.2 Implement `_load_language_database(language: String) -> Dictionary` that resolves the file path, reads + parses the JSON once, validates it's a Dictionary, and caches the result in `_loaded_databases[language]`
- [x] 2.3 Reuse an already-loaded database from `_loaded_databases` on subsequent calls for the same language instead of re-reading the file

## 3. Rework `fetch_questions()`
- [x] 3.1 Update `fetch_questions(category: String, amount: int)` to: resolve language → load/reuse database → validate category exists → take a random, non-repeating-within-call sample of up to `amount` questions from that category
- [x] 3.2 Keep emitting `questions_ready(questions: Array)` (normalized via existing `_normalize_categories`) so call sites are unaffected
- [x] 3.3 Log a warning and emit `questions_ready` with an empty array if the category is missing from the loaded database or the file fails to parse (mirrors current empty-array handling already present in `gameplay_screen._on_questions_ready`)

## 4. Remove OpenTDB integration
- [x] 4.1 Remove `_http_request`, `API_BASE_URL`, `_get_category_id()`, `_on_request_completed()`, and the `HTTPRequest` child node creation in `_ready()`
- [x] 4.2 Remove `_load_fallback_questions()` and delete `data/fallback_questions.json`
- [x] 4.3 Remove the `connection_error` and `api_failed` signals

## 5. Update public API surface
- [x] 5.1 Remove `has_cached_questions()` and `get_cached_questions()` (unused externally, tied to the old consume-cache model)
- [x] 5.2 Update `clear_cache()` to clear `_loaded_databases` (and reset any related counters) instead of the old API-response cache
- [x] 5.3 Update `get_available_categories()` to return the new `CATEGORIES` constant

## 6. Update callers
- [x] 6.1 In `scenes/ui/gameplay_screen.gd`, remove the `TriviaQuestionService.api_failed.connect(_on_api_failed)` connection and the now-unused `_on_api_failed()` handler
- [x] 6.2 In `scenes/ui/test_ui/trivia_service_test.gd`, remove the `connection_error`/`api_failed` connections and their handlers

## 7. Validation
- [x] 7.1 Manually run the `trivia_service_test.gd` test scene to confirm questions load per category with no network calls
- [x] 7.2 Verify `clear_cache()` followed by a new `fetch_questions()` call still returns valid questions
- [x] 7.3 Temporarily rename/remove `data/questions_en.json` in a local test to confirm an unsupported/missing language falls back to English without errors (restore the file afterward)
