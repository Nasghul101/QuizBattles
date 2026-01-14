# trivia-question-service Specification

## Purpose
A singleton autoload service that fetches trivia questions from the Open Trivia Database API, caches them in memory, and provides fallback to local questions when the API is unavailable. Consolidates Open Trivia DB categories and returns questions in their native format for use by quiz screens.
## Requirements
### Requirement: API Integration
The service SHALL fetch questions from the Open Trivia Database API using Godot's HTTPRequest node.

#### Scenario: Fetch questions for a specific category
**Given** the service is initialized  
**When** `fetch_questions(category: String, amount: int)` is called with a valid category and amount  
**Then** the service makes an HTTP GET request to `https://opentdb.com/api.php?amount={amount}&category={category_id}`  
**And** waits for the response asynchronously  
**And** returns an array of question dictionaries on success

#### Scenario: Handle successful API response
**Given** an HTTP request is in progress  
**When** the API returns status code 200 with valid JSON  
**Then** the service parses the response body  
**And** extracts the `results` array from the JSON  
**And** validates each question has required fields (`question`, `correct_answer`, `incorrect_answers`)  
**And** caches the questions in memory  
**And** returns the questions array

#### Scenario: Handle failed API response
**Given** an HTTP request is in progress  
**When** the API returns a non-200 status code or invalid JSON  
**Then** the service logs a warning  
**And** falls back to loading questions from the local JSON file  
**And** returns questions from the fallback source

---

### Requirement: Category Mapping
The service SHALL map Open Trivia Database category names to consolidated internal categories.

#### Scenario: Map Entertainment subcategories
**Given** the service receives a request for category "Entertainment"  
**When** mapping to Open Trivia DB category ID  
**Then** the service randomly selects one of the Entertainment subcategory IDs (11: Film, 12: Music, 13: TV, 14: Video Games, 29: Comics, 31: Anime & Manga)  
**And** uses that ID in the API request

#### Scenario: Map Science subcategories
**Given** the service receives a request for category "Science"  
**When** mapping to Open Trivia DB category ID  
**Then** the service randomly selects one of the Science subcategory IDs (17: Science & Nature, 18: Computers, 19: Mathematics, 30: Gadgets)  
**And** uses that ID in the API request

#### Scenario: Map direct categories
**Given** the service receives a request for a non-consolidated category (e.g., "History", "Geography", "Sports")  
**When** mapping to Open Trivia DB category ID  
**Then** the service uses the direct ID mapping (e.g., History → 23, Geography → 22, Sports → 21)

---

### Requirement: Session-Based Caching
The service SHALL cache fetched questions in memory to reduce API calls and improve performance.

#### Scenario: Cache questions after successful fetch
**Given** questions are successfully fetched from the API  
**When** the response is processed  
**Then** the service stores the questions in a Dictionary keyed by category name  
**And** the cached data includes the questions array and a timestamp

#### Scenario: Return cached questions on subsequent requests
**Given** questions for category "History" are already cached  
**When** `fetch_questions("History", 3)` is called again  
**Then** the service checks the cache first  
**And** returns the cached questions immediately without making an API call  
**And** removes the returned questions from the cache (consume pattern)

#### Scenario: Cache persists across scene changes
**Given** questions are cached in the service  
**When** the current scene changes (e.g., from Category Selection to Question Screen)  
**Then** the cached questions remain available  
**Because** the service is an autoload and survives scene transitions

---

### Requirement: Fallback to Local Questions
The service SHALL provide offline support by loading questions from a local JSON file when the API is unavailable.

#### Scenario: Load fallback questions on API failure
**Given** an API request fails (timeout, 500 error, invalid response)  
**When** the service handles the failure  
**Then** it loads questions from `res://data/fallback_questions.json`  
**And** parses the JSON file  
**And** filters questions by the requested category  
**And** returns up to the requested amount of questions

#### Scenario: Handle missing fallback file
**Given** the API request fails  
**And** the fallback JSON file does not exist  
**When** the service attempts to load fallback questions  
**Then** it logs an error message  
**And** returns an empty array  
**And** emits an error signal

#### Scenario: Handle corrupt fallback JSON
**Given** the fallback JSON file exists but contains invalid JSON  
**When** the service attempts to parse it  
**Then** it logs an error message  
**And** returns an empty array  
**And** emits an error signal

---

### Requirement: Error State Management
The service SHALL distinguish between different failure scenarios and provide appropriate signals.

#### Scenario: Detect no internet connection
**Given** the user's device has no internet connection  
**When** an HTTP request is made  
**Then** Godot's HTTPRequest returns a connection error (e.g., `RESULT_CANT_CONNECT`)  
**And** the service emits a `connection_error` signal  
**And** does NOT fall back to local JSON (user must connect to internet)

#### Scenario: Handle API failure with fallback
**Given** the API request completes but returns an error (e.g., 500 status, timeout)  
**When** the service processes the response  
**Then** it emits an `api_failed` signal  
**And** automatically falls back to local JSON  
**And** the caller receives questions from the fallback source

---

### Requirement: Question Format Compatibility
The service SHALL return questions in the Open Trivia Database format expected by quiz screens.

#### Scenario: Return questions in correct format
**Given** questions are fetched from either API or fallback JSON  
**When** returned to the caller  
**Then** each question dictionary contains:
- `"question"` (String): The question text
- `"correct_answer"` (String): The correct answer
- `"incorrect_answers"` (Array of 3 Strings): The wrong answers
- `"category"` (String): The question category
- `"difficulty"` (String): The difficulty level (easy/medium/hard)

#### Scenario: No transformation of API data
**Given** the API returns question data (may include HTML entities like `&quot;`)  
**When** the service processes the response  
**Then** it returns the question text as-is without decoding or transformation  
**Because** the quiz screen handles display formatting

---

### Requirement: Public API
The service SHALL provide a simple, async-friendly API for fetching questions.

#### Scenario: Async question fetching
**Given** a caller wants to fetch questions  
**When** they call `fetch_questions(category: String, amount: int)`  
**Then** the service returns immediately (non-blocking)  
**And** emits a `questions_ready(questions: Array)` signal when complete  
**Or** emits an error signal if fetching fails

#### Scenario: Synchronous cache check
**Given** a caller wants to check if questions are cached  
**When** they call `has_cached_questions(category: String) -> bool`  
**Then** the service returns true if questions for that category are in cache  
**And** returns false otherwise (does not trigger a fetch)

---

### Requirement: Memory Management
The service SHALL manage cached questions efficiently to avoid excessive memory usage on mobile devices.

#### Scenario: Limit cache size
**Given** questions are being cached during gameplay  
**When** the total number of cached questions exceeds 50  
**Then** the service removes the oldest cached category  
**And** keeps the cache size under the limit

#### Scenario: Clear cache on demand
**Given** the service has cached questions  
**When** `clear_cache()` is called  
**Then** all cached questions are removed from memory  
**And** future requests will fetch fresh data

---

### Requirement: Initialization
The service SHALL initialize itself when loaded as an autoload.

#### Scenario: Autoload initialization
**Given** the game starts  
**When** the Godot engine loads autoload singletons  
**Then** the TriviaQuestionService initializes  
**And** creates an HTTPRequest node as a child  
**And** connects to the HTTPRequest's `request_completed` signal  
**And** is ready to handle fetch requests

