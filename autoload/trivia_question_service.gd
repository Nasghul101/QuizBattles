extends Node
## Trivia Question Service
##
## Singleton autoload service that fetches trivia questions from the Open Trivia Database API,
## caches them in memory, and provides fallback to local questions when the API is unavailable.
## Consolidates Open Trivia DB categories and returns questions in their native format.
##
## Usage:
##   1. Call fetch_questions(category, amount) to request questions
##   2. Connect to questions_ready signal to receive results
##   3. Handle connection_error or api_failed signals for error cases
##
## Example:
##   TriviaQuestionService.questions_ready.connect(_on_questions_ready)
##   TriviaQuestionService.fetch_questions("History", 3)

# Signals

## Emitted when questions are successfully fetched (from API or cache)
signal questions_ready(questions: Array)

## Emitted when there is no internet connection
signal connection_error()

## Emitted when API fails but fallback is used
signal api_failed()


# Constants

## Maximum number of questions to cache before evicting oldest
const MAX_CACHED_QUESTIONS: int = 50

## Path to fallback questions JSON file
const FALLBACK_JSON_PATH: String = "res://data/fallback_questions.json"

## Open Trivia Database API base URL
const API_BASE_URL: String = "https://opentdb.com/api.php"

## Category mapping from internal names to Open Trivia DB IDs
const CATEGORY_MAPPING: Dictionary = {
    "General Knowledge": 9,
    "Entertainment": [11, 12, 13, 14, 29, 31],  # Film, Music, TV, Video Games, Comics, Anime
    "Science": [17, 18, 19, 30],  # Nature, Computers, Mathematics, Gadgets
    "History": 23,
    "Geography": 22,
    "Sports": 21,
    "Art": 25,
    "Animals": 27,
    "Mythology": 20,
    "Politics": 24,
    "Celebrities": 26,
    "Vehicles": 28
}


# Instance variables

## HTTPRequest node for API calls
var _http_request: HTTPRequest

## Cache structure: { "category_name": { "questions": Array, "timestamp": int } }
var _question_cache: Dictionary = {}

## Total number of cached questions across all categories
var _total_cached_questions: int = 0

## Metadata for current request (category and amount)
var _current_request_metadata: Dictionary = {}


# Lifecycle methods

func _ready() -> void:
    # Create and configure HTTPRequest node
    _http_request = HTTPRequest.new()
    add_child(_http_request)
    _http_request.request_completed.connect(_on_request_completed)


# Public API

## Fetch questions for a specific category (async)
## Emits questions_ready(questions: Array) on success
## Emits connection_error() if no internet
## Emits api_failed() if API fails (but returns fallback questions)
func fetch_questions(category: String, amount: int) -> void:
    # Check cache first
    if has_cached_questions(category):
        var cached: Array = get_cached_questions(category, amount)
        if cached.size() > 0:
            # Return cached questions immediately
            print("[TriviaService] Returning %d cached questions for category: %s (requested: %d)" % [cached.size(), category, amount])
            questions_ready.emit(_normalize_categories(cached, category))
            return
    
    # Get category ID for API request
    var category_id: int = _get_category_id(category)
    if category_id == -1:
        push_error("Invalid category: %s" % category)
        # Fall back to local questions
        var fallback: Array = _load_fallback_questions(category, amount)
        questions_ready.emit(_normalize_categories(fallback, category))
        return
    
    # Store metadata for response handler
    _current_request_metadata = {
        "category": category,
        "amount": amount
    }
    
    # Construct API URL - request only multiple choice questions (not true/false)
    var url: String = "%s?amount=%d&category=%d&type=multiple" % [API_BASE_URL, amount, category_id]
    
    print("[TriviaService] Fetching %d questions for category: %s (API category ID: %d)" % [amount, category, category_id])
    
    # Make HTTP request
    var error: Error = _http_request.request(url)
    if error != OK:
        push_error("Failed to make HTTP request: %d" % error)
        connection_error.emit()


## Check if questions for a category are cached
func has_cached_questions(category: String) -> bool:
    if not _question_cache.has(category):
        return false
    return _question_cache[category]["questions"].size() > 0


## Get cached questions for a category (returns empty array if none cached)
## Uses consume pattern - removes returned questions from cache
func get_cached_questions(category: String, amount: int) -> Array:
    if not has_cached_questions(category):
        return []
    
    var cache_entry: Dictionary = _question_cache[category]
    var cached_questions: Array = cache_entry["questions"]
    
    # Get up to 'amount' questions
    var result: Array = []
    var count: int = min(amount, cached_questions.size())
    
    for i: int in range(count):
        result.append(cached_questions.pop_front())
    
    # Update total count
    _total_cached_questions -= count
    
    # Remove category from cache if empty
    if cached_questions.is_empty():
        _question_cache.erase(category)
    
    return result


## Clear all cached questions
func clear_cache() -> void:
    _question_cache.clear()
    _total_cached_questions = 0


## Get list of available categories
func get_available_categories() -> Array[String]:
    var categories: Array[String] = []
    for category: String in CATEGORY_MAPPING.keys():
        categories.append(category)
    return categories


# Private helper methods

## Get Open Trivia DB category ID for a given category name
## Returns -1 if category not found
func _get_category_id(category: String) -> int:
    if not CATEGORY_MAPPING.has(category):
        return -1
    
    var mapping = CATEGORY_MAPPING[category]
    
    # If mapping is an array, pick random subcategory
    if mapping is Array:
        return mapping.pick_random()
    
    # Otherwise return the single ID
    return mapping


## Load questions from fallback JSON file
func _load_fallback_questions(category: String, amount: int) -> Array:
    print("[TriviaService] Loading fallback questions for category: %s (requested: %d)" % [category, amount])
    
    # Check if file exists
    if not FileAccess.file_exists(FALLBACK_JSON_PATH):
        push_error("Fallback questions file not found: %s" % FALLBACK_JSON_PATH)
        return []
    
    # Load and parse JSON
    var file = FileAccess.open(FALLBACK_JSON_PATH, FileAccess.READ)
    if file == null:
        push_error("Failed to open fallback questions file: %s" % FALLBACK_JSON_PATH)
        return []
    
    var json_string: String = file.get_as_text()
    file.close()
    
    var json: JSON = JSON.new()
    var parse_result: Error = json.parse(json_string)
    
    if parse_result != OK:
        push_error("Failed to parse fallback questions JSON: %s" % json.get_error_message())
        return []
    
    var data = json.get_data()
    
    if not data is Dictionary:
        push_error("Invalid fallback questions JSON structure")
        return []
    
    # Get questions for category
    if not data.has(category):
        push_warning("No fallback questions found for category: %s" % category)
        return []
    
    var category_questions: Array = data[category]
    
    # Return up to 'amount' questions
    var result: Array = []
    for i: int in range(min(amount, category_questions.size())):
        result.append(category_questions[i])
    
    print("[TriviaService] Returning %d fallback questions (requested: %d)" % [result.size(), amount])
    return result


## Cache questions for a category
func _cache_questions(category: String, questions: Array) -> void:
    # Enforce cache size limit before adding
    while _total_cached_questions + questions.size() > MAX_CACHED_QUESTIONS:
        _evict_oldest_cache_entry()
    
    # Add to cache
    _question_cache[category] = {
        "questions": questions.duplicate(),
        "timestamp": Time.get_ticks_msec()
    }
    
    _total_cached_questions += questions.size()


## Overwrite the "category" field on each question with the top-level category name.
## This prevents API subcategory strings like "Entertainment: Film" from leaking into the UI.
## Also decodes HTML entities returned by the Open Trivia DB API.
func _normalize_categories(questions: Array, top_category: String) -> Array:
    var normalized: Array = []
    for q in questions:
        var copy: Dictionary = (q as Dictionary).duplicate()
        copy["category"] = top_category
        copy["question"] = _html_unescape(copy.get("question", ""))
        copy["correct_answer"] = _html_unescape(copy.get("correct_answer", ""))
        var decoded_incorrect: Array = []
        for ans in copy.get("incorrect_answers", []):
            decoded_incorrect.append(_html_unescape(ans))
        copy["incorrect_answers"] = decoded_incorrect
        normalized.append(copy)
    return normalized


## Decode common HTML entities into their plain-text equivalents.
## The Open Trivia DB API encodes special characters as HTML entities.
func _html_unescape(text: String) -> String:
    # Numeric decimal entities (e.g. &#039; &#8217;)
    var result: String = text
    var regex: RegEx = RegEx.new()
    regex.compile("&#(\\d+);")
    for m in regex.search_all(result):
        var code: int = m.get_string(1).to_int()
        result = result.replace(m.get_string(), char(code))
    # Named entities
    var entities: Dictionary = {
        "&amp;": "&", "&lt;": "<", "&gt;": ">",
        "&quot;": '"', "&apos;": "'", "&#039;": "'",
        "&auml;": "ä", "&Auml;": "Ä",
        "&ouml;": "ö", "&Ouml;": "Ö",
        "&uuml;": "ü", "&Uuml;": "Ü",
        "&szlig;": "ß",
        "&eacute;": "é", "&egrave;": "è", "&ecirc;": "ê", "&euml;": "ë",
        "&aacute;": "á", "&agrave;": "à", "&acirc;": "â",
        "&iacute;": "í", "&igrave;": "ì", "&icirc;": "î",
        "&oacute;": "ó", "&ograve;": "ò", "&ocirc;": "ô",
        "&uacute;": "ú", "&ugrave;": "ù", "&ucirc;": "û",
        "&ntilde;": "ñ", "&ccedil;": "ç",
        "&lsquo;": "\u2018", "&rsquo;": "\u2019",
        "&ldquo;": "\u201C", "&rdquo;": "\u201D",
        "&ndash;": "\u2013", "&mdash;": "\u2014",
        "&hellip;": "\u2026", "&nbsp;": " "
    }
    for entity: String in entities.keys():
        result = result.replace(entity, entities[entity])
    return result


## Evict the oldest cache entry (FIFO)
func _evict_oldest_cache_entry() -> void:
    if _question_cache.is_empty():
        return
    
    # Find oldest entry by timestamp
    var oldest_category: String = ""
    var oldest_timestamp: int = Time.get_ticks_msec()
    
    for category: String in _question_cache.keys():
        var timestamp: int = _question_cache[category]["timestamp"]
        if timestamp < oldest_timestamp:
            oldest_timestamp = timestamp
            oldest_category = category
    
    # Remove oldest entry
    if oldest_category != "":
        var removed_count: int = _question_cache[oldest_category]["questions"].size()
        _question_cache.erase(oldest_category)
        _total_cached_questions -= removed_count


## Handle HTTP request completion
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var category: String = _current_request_metadata.get("category", "")
    var amount: int = _current_request_metadata.get("amount", 0)
    
    # Check for connection errors
    if result != HTTPRequest.RESULT_SUCCESS:
        push_warning("HTTP request failed with result: %d" % result)
        connection_error.emit()
        return
    
    # Check for HTTP errors
    if response_code != 200:
        push_warning("API returned error code: %d" % response_code)
        api_failed.emit()
        var fallback = _load_fallback_questions(category, amount)
        questions_ready.emit(_normalize_categories(fallback, category))
        return
    
    # Parse JSON response
    var json_string: String = body.get_string_from_utf8()
    var json: JSON = JSON.new()
    var parse_result: Error = json.parse(json_string)
    
    if parse_result != OK:
        push_warning("Failed to parse API response: %s" % json.get_error_message())
        api_failed.emit()
        var fallback: Array = _load_fallback_questions(category, amount)
        questions_ready.emit(_normalize_categories(fallback, category))
        return
    
    var data = json.get_data()
    
    # Validate response structure
    if not data is Dictionary or not data.has("results"):
        push_warning("Invalid API response structure")
        api_failed.emit()
        var fallback: Array = _load_fallback_questions(category, amount)
        questions_ready.emit(_normalize_categories(fallback, category))
        return
    
    var results: Array = data["results"]
    
    # Validate each question has required fields
    var valid_questions: Array = []
    for question in results:
        if not question is Dictionary:
            continue
        
        if not question.has("question") or not question.has("correct_answer") or not question.has("incorrect_answers"):
            push_warning("Question missing required fields")
            continue
        
        if not question["incorrect_answers"] is Array or question["incorrect_answers"].size() != 3:
            push_warning("Question has invalid incorrect_answers")
            continue
        
        valid_questions.append(question)
    
    # If no valid questions, fall back
    if valid_questions.is_empty():
        push_warning("No valid questions in API response")
        api_failed.emit()
        var fallback: Array = _load_fallback_questions(category, amount)
        questions_ready.emit(_normalize_categories(fallback, category))
        return
    
    # Cache successful results
    _cache_questions(category, valid_questions)
    
    print("[TriviaService] API returned %d valid questions for category: %s (requested: %d)" % [valid_questions.size(), category, amount])
    
    # Emit success signal
    questions_ready.emit(_normalize_categories(valid_questions, category))
