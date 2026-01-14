# Tasks: Add Trivia Question Service

Implementation tasks for the `add-trivia-question-service` change.

## Task Breakdown

### Phase 1: Service Foundation (Data Layer)

1. **Create fallback questions JSON file**
   - Create `res://data/fallback_questions.json`
   - Structure with categories as keys and question arrays as values
   - Add 3-5 example questions per major category (Entertainment, Science, History, Geography, Sports)
   - Validate JSON syntax
   - **Validation**: File loads successfully with `JSON.parse_string()`
   - **Dependency**: None
   - **Estimated time**: 15 minutes

2. **Create TriviaQuestionService autoload script**
   - Create `res://autoload/trivia_question_service.gd`
   - Extend Node
   - Add class documentation comment
   - Define signal declarations (`questions_ready`, `connection_error`, `api_failed`)
   - Add empty method stubs for public API
   - **Validation**: Script has no syntax errors, can be loaded
   - **Dependency**: None
   - **Estimated time**: 10 minutes

3. **Register autoload in project.godot**
   - Add TriviaQuestionService to autoload list
   - Set path to `res://autoload/trivia_question_service.gd`
   - **Validation**: Service accessible via `TriviaQuestionService` in other scripts
   - **Dependency**: Task 2
   - **Estimated time**: 2 minutes

---

### Phase 2: Category Mapping

4. **Implement category to Open Trivia DB ID mapping**
   - Create constant dictionary `CATEGORY_MAPPING` with all mappings
   - Map consolidated categories (Entertainment, Science) to array of IDs
   - Map direct categories (History, Geography, Sports, etc.) to single IDs
   - Create helper function `_get_category_id(category: String) -> int`
   - Handle random selection for consolidated categories
   - **Validation**: Test mapping returns correct IDs for all categories
   - **Dependency**: Task 2
   - **Estimated time**: 20 minutes

5. **Implement get_available_categories() method**
   - Return array of category name strings
   - Include only top-level categories (Entertainment, Science, History, etc.)
   - **Validation**: Returns expected list of ~10 categories
   - **Dependency**: Task 4
   - **Estimated time**: 5 minutes

---

### Phase 3: Caching System

6. **Implement session-based cache**
   - Create instance variable `_question_cache: Dictionary`
   - Cache structure: `{ "category_name": { "questions": Array, "timestamp": int } }`
   - Implement `has_cached_questions(category: String) -> bool`
   - Implement `get_cached_questions(category: String, amount: int) -> Array`
   - Implement consume pattern (remove questions from cache when retrieved)
   - **Validation**: Cache stores and retrieves questions correctly
   - **Dependency**: Task 2
   - **Estimated time**: 25 minutes

7. **Implement cache size limiting**
   - Add constant `MAX_CACHED_QUESTIONS = 50`
   - Track total cached question count
   - Implement FIFO eviction when limit exceeded
   - **Validation**: Cache never exceeds 50 questions
   - **Dependency**: Task 6
   - **Estimated time**: 15 minutes

8. **Implement clear_cache() method**
   - Clear `_question_cache` dictionary
   - Reset any tracking variables
   - **Validation**: Cache is empty after calling clear_cache()
   - **Dependency**: Task 6
   - **Estimated time**: 5 minutes

---

### Phase 4: Fallback JSON Loading

9. **Implement fallback JSON loader**
   - Create helper function `_load_fallback_questions(category: String, amount: int) -> Array`
   - Load file at `res://data/fallback_questions.json`
   - Parse JSON with error handling
   - Filter questions by category
   - Return up to `amount` questions
   - Log error if file missing or corrupt
   - Emit error signal on failure
   - **Validation**: Returns questions from JSON when called
   - **Dependency**: Tasks 1, 2
   - **Estimated time**: 20 minutes

---

### Phase 5: API Integration

10. **Set up HTTPRequest node**
    - Create HTTPRequest node in `_ready()`
    - Add as child of service
    - Connect to `request_completed` signal
    - Store reference in instance variable
    - **Validation**: HTTPRequest node exists and signal is connected
    - **Dependency**: Task 2
    - **Estimated time**: 10 minutes

11. **Implement fetch_questions() core logic**
    - Check cache first using `has_cached_questions()`
    - If cached, call `get_cached_questions()` and emit `questions_ready`
    - If not cached, construct API URL with category ID and amount
    - Make HTTP GET request using HTTPRequest
    - Store request metadata (category, amount) for response handler
    - **Validation**: Makes HTTP request with correct URL
    - **Dependency**: Tasks 4, 6, 10
    - **Estimated time**: 25 minutes

12. **Implement request completion handler**
    - Create `_on_request_completed(result, response_code, headers, body)` callback
    - Check for connection errors (emit `connection_error` signal)
    - Check for HTTP errors (emit `api_failed`, fall back to JSON)
    - Parse JSON response body
    - Validate response structure (has "results" array)
    - Validate each question has required fields
    - Cache successful results
    - Emit `questions_ready` signal with questions
    - Fall back to JSON on any parsing/validation failure
    - **Validation**: Handles success and failure scenarios correctly
    - **Dependency**: Tasks 6, 9, 11
    - **Estimated time**: 35 minutes

---

### Phase 6: Testing & Validation

13. **Manual integration test with quiz screen**
    - Create test scene that calls `TriviaQuestionService.fetch_questions()`
    - Connect to `questions_ready` signal
    - Pass questions to quiz_screen.load_question()
    - Verify questions display correctly
    - **Validation**: End-to-end flow works from service to UI
    - **Dependency**: Task 12
    - **Estimated time**: 15 minutes

14. **Test error scenarios**
    - Test with no internet (should emit `connection_error`)
    - Test with invalid category (should fall back to JSON)
    - Test with missing JSON file (should return empty array and log error)
    - Test cache hit scenario (should not make HTTP request)
    - **Validation**: All error paths work as expected
    - **Dependency**: Tasks 9, 12
    - **Estimated time**: 20 minutes

15. **Test category consolidation**
    - Call `fetch_questions("Entertainment", 3)` multiple times
    - Verify different Entertainment subcategories are used
    - Call `fetch_questions("Science", 3)` multiple times
    - Verify different Science subcategories are used
    - **Validation**: Random selection works correctly
    - **Dependency**: Tasks 4, 12
    - **Estimated time**: 10 minutes

---

## Task Summary

**Total tasks**: 15  
**Estimated total time**: 4-5 hours  
**Can be parallelized**: Tasks 1 and 2 (JSON file and script creation)  
**Critical path**: Tasks 2 → 10 → 11 → 12

## Dependencies Graph

```
1 (JSON file)  ─┐
                ├─→ 9 (Fallback loader) ─┐
2 (Script)  ────┼─→ 3 (Autoload)         ├─→ 12 (Request handler) ─┐
                ├─→ 4 (Mapping) ─→ 5     │                           ├─→ 13, 14, 15 (Tests)
                ├─→ 6 (Cache) ──────────┤                           │
                │   └─→ 7 (Limit)        │                           │
                │   └─→ 8 (Clear)        │                           │
                └─→ 10 (HTTPRequest) ────┘                           │
                    └─→ 11 (fetch_questions) ─────────────────────────┘
```

## Validation Checklist

After completing all tasks:

- [x] Service fetches questions from API for valid categories
- [x] Questions are returned in Open Trivia DB format
- [x] Cache prevents duplicate API calls for same category
- [x] Entertainment/Science categories use random subcategories
- [x] API failure falls back to local JSON automatically
- [x] Connection error emits correct signal without fallback
- [x] Fallback JSON loads successfully
- [x] Cache size limit is enforced
- [x] clear_cache() removes all cached questions
- [x] Quiz screen can consume service questions successfully

## Notes

- API key is not required for Open Trivia DB (free, public API)
- Test with real API during development to verify endpoint structure
- Consider adding debug logging for easier troubleshooting
- The service is stateless except for cache - no save/load needed
