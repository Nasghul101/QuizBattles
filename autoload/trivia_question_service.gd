# uid://kujmpu5hosxm
extends Node
## Trivia Question Service
##
## Singleton autoload service that loads trivia questions from the local
## per-language JSON database bundled with the game.
##
## Usage:
##   1. Call fetch_questions(category, amount) to request questions
##   2. Connect to questions_ready signal to receive results
##
## Example:
##   TriviaQuestionService.questions_ready.connect(_on_questions_ready)
##   TriviaQuestionService.fetch_questions("History", 3)

# Signals

## Emitted when questions are successfully fetched from the local database
signal questions_ready(questions: Array)


# Constants

const DEFAULT_LANGUAGE: String = "en"
const LANGUAGE_FILE_TEMPLATE: String = "res://data/questions_%s.json"
const CATEGORIES: Array[String] = [
    "General Knowledge",
    "Entertainment",
    "Science",
    "History",
    "Geography",
    "Sports",
    "Art",
    "Animals",
    "Mythology",
    "Politics",
    "Celebrities",
    "Vehicles"
]


# Instance variables

var _loaded_databases: Dictionary = {}


# Public API

## Fetch questions for a specific category from the active local language database.
func fetch_questions(category: String, amount: int) -> void:
    if amount <= 0:
        questions_ready.emit([])
        return

    if not CATEGORIES.has(category):
        push_warning("Invalid category: %s" % category)
        questions_ready.emit([])
        return

    var database: Dictionary = _load_language_database(_get_user_language())
    if not database.has(category):
        push_warning("No database entries found for category: %s" % category)
        questions_ready.emit([])
        return

    var category_questions: Array = database[category]
    if category_questions.is_empty():
        questions_ready.emit([])
        return

    var available: Array = category_questions.duplicate()
    available.shuffle()

    var result: Array = []
    var count: int = min(amount, available.size())
    for i in range(count):
        result.append(available[i])

    questions_ready.emit(_normalize_categories(result, category))


## Clear all loaded language databases from memory.
func clear_cache() -> void:
    _loaded_databases.clear()


## Get list of available categories.
func get_available_categories() -> Array[String]:
    return CATEGORIES.duplicate()


# Private helper methods

func _get_user_language() -> String:
    var stored_language: String = LocalCache.get_setting("language", "")
    var locale_language: String = OS.get_locale_language()

    if stored_language.strip_edges() != "":
        return stored_language.strip_edges().to_lower()

    if locale_language.strip_edges() != "":
        return locale_language.strip_edges().to_lower()

    return DEFAULT_LANGUAGE


func _resolve_language_file_path(language: String) -> String:
    var normalized_language: String = language.strip_edges().to_lower()
    if normalized_language == "":
        normalized_language = DEFAULT_LANGUAGE

    var candidate_path: String = LANGUAGE_FILE_TEMPLATE % normalized_language
    if FileAccess.file_exists(candidate_path):
        return candidate_path

    if normalized_language != DEFAULT_LANGUAGE:
        return LANGUAGE_FILE_TEMPLATE % DEFAULT_LANGUAGE

    return candidate_path


func _load_language_database(language: String) -> Dictionary:
    var normalized_language: String = language.strip_edges().to_lower()
    if normalized_language == "":
        normalized_language = DEFAULT_LANGUAGE

    if _loaded_databases.has(normalized_language):
        return _loaded_databases[normalized_language]

    var file_path: String = _resolve_language_file_path(normalized_language)
    if not FileAccess.file_exists(file_path):
        push_warning("Question database not found for language: %s" % normalized_language)
        return {}

    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        push_warning("Failed to open question database: %s" % file_path)
        return {}

    var json_string: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()
    var parse_result: Error = json.parse(json_string)
    if parse_result != OK:
        push_warning("Failed to parse question database %s: %s" % [file_path, json.get_error_message()])
        return {}

    var data = json.get_data()
    if not data is Dictionary:
        push_warning("Invalid question database structure: %s" % file_path)
        return {}

    _loaded_databases[normalized_language] = data
    return data


## Overwrite the "category" field on each question with the top-level category name.
## This prevents subcategory strings from leaking into the UI.
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
func _html_unescape(text: String) -> String:
    var result: String = text
    var regex: RegEx = RegEx.new()
    regex.compile("&#(\\d+);")
    for m in regex.search_all(result):
        var code: int = m.get_string(1).to_int()
        result = result.replace(m.get_string(), char(code))

    var entities: Dictionary = {
        "&amp;": "&",
        "&lt;": "<",
        "&gt;": ">",
        "&quot;": '"',
        "&apos;": "'",
        "&#039;": "'",
        "&auml;": "ä",
        "&Auml;": "Ä",
        "&ouml;": "ö",
        "&Ouml;": "Ö",
        "&uuml;": "ü",
        "&Uuml;": "Ü",
        "&szlig;": "ß",
        "&eacute;": "é",
        "&egrave;": "è",
        "&ecirc;": "ê",
        "&euml;": "ë",
        "&aacute;": "á",
        "&agrave;": "à",
        "&acirc;": "â",
        "&iacute;": "í",
        "&igrave;": "ì",
        "&icirc;": "î",
        "&oacute;": "ó",
        "&ograve;": "ò",
        "&ocirc;": "ô",
        "&uacute;": "ú",
        "&ugrave;": "ù",
        "&ucirc;": "û",
        "&ntilde;": "ñ",
        "&ccedil;": "ç",
        "&lsquo;": "\u2018",
        "&rsquo;": "\u2019",
        "&ldquo;": "\u201C",
        "&rdquo;": "\u201D",
        "&ndash;": "\u2013",
        "&mdash;": "\u2014",
        "&hellip;": "\u2026",
        "&nbsp;": " "
    }

    for entity: String in entities.keys():
        result = result.replace(entity, entities[entity])
    return result

