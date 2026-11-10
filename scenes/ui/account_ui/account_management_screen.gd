# uid://crr12b7mb5suu
extends Control
## Account Management Screen
##
## Displays user account information and statistics including wins, losses, draws,
## total games, pie chart visualization, and category-level performance data.
## Provides navigation back to main lobby and sign-out functionality.

@onready var player_name_label : Label = $MarginContainer/VBoxContainer/Label
@onready var piechart : Control = $MarginContainer/VBoxContainer/HBoxContainer/PieChartContainer/Piechart
@onready var total_games_amount : Label = %TotalGamesAmount
@onready var wins_amount : Label = %WinsAmount
@onready var draws_amount : Label = %DrawsAmount
@onready var loss_amount : Label = %LossAmount
@onready var category_statistics_container : GridContainer = %CategoryStatisticsContainer
@onready var language_options : OptionButton = %LanguageOptions

## Locale for each LanguageOptions entry, in dropdown order
const LANGUAGE_LOCALES: PackedStringArray = ["en", "de", "zh_TW"]
## Dropdown indices that are separators (non-selectable)
const SEPARATOR_INDICES: PackedInt32Array = [1, 3]


## Initialize the screen with current user's statistics.
##
## Fetches user data from UserDatabase, populates all labels, pie chart,
## and category statistics. Calculates draws from total_games - (wins + losses).
func _ready() -> void:
    _load_options()

    # Get current user
    var current_user: Dictionary = UserDatabase.get_current_user()
    if current_user.is_empty():
        push_error("Account management screen opened without signed-in user")
        return
    
    # Fetch user data for display
    var user_data: Dictionary = await UserDatabase.get_user_data_for_display(current_user.username)
    if user_data.is_empty():
        push_error("Failed to fetch user data for %s" % current_user.username)
        return
    
    # Populate player name
    player_name_label.text = user_data.username
    
    # Extract statistics
    var wins: int = user_data.get("wins", 0)
    var losses: int = user_data.get("losses", 0)
    var total_games: int = user_data.get("total_games", 0)
    var draws: int = total_games - (wins + losses)
    
    # Populate statistics labels
    total_games_amount.text = str(total_games)
    wins_amount.text = str(wins)
    draws_amount.text = str(draws)
    loss_amount.text = str(losses)
    
    # Populate pie chart
    piechart.set_chart(wins, draws, total_games)
    
    # Populate category statistics
    var category_stats: Dictionary = user_data.get("category_stats", {})
    _populate_category_statistics(category_stats)



## Populate category statistics components with user data.
##
## Iterates through all category display components, looks up user's
## correct and total answer counts for each category, and updates the component.
## Shows 0/0/0% for categories with no data.
##
## @param category_stats: Dictionary mapping category names to {correct_answers, total_answers}
func _populate_category_statistics(category_stats: Dictionary) -> void:
    for child in category_statistics_container.get_children():
        # Get the category from the component's export variable
        var category: String = child.category
        
        # Look up category data
        var total_answers: int = 0
        var correct_answers: int = 0
        
        if category_stats.has(category):
            var stats: Dictionary = category_stats[category]
            total_answers = stats.get("total_answers", 0)
            correct_answers = stats.get("correct_answers", 0)
        
        # Update component
        child.set_correct_answers_amount(correct_answers)
        child.set_total_answers_amount(total_answers)
        child.set_accuracy()


## Navigate back to main lobby screen.
func _on_back_button_pressed() -> void:
    Utils.navigate_to_scene("main_lobby")


## Sign out current user and navigate to main lobby.
func _on_log_off_button_pressed() -> void:
    UserDatabase.sign_out()
    LocalCache.forget_session()
    Utils.navigate_to_scene("main_lobby")


## Sync the options popup controls with the currently active settings.
##
## Add further options here so they reflect their state when the screen opens
## and after a revert.
func _load_options() -> void:
    var language_index: int = LANGUAGE_LOCALES.find(TranslationServer.get_locale())
    # Convert language index to dropdown index (accounting for separators)
    var dropdown_index: int = _language_index_to_dropdown_index(maxi(language_index, 0))
    language_options.select(dropdown_index)


## Convert a language array index to dropdown index by skipping separators.
func _language_index_to_dropdown_index(language_index: int) -> int:
    var dropdown_index: int = language_index
    for separator in SEPARATOR_INDICES:
        if separator <= dropdown_index:
            dropdown_index += 1
    return dropdown_index


## Convert a dropdown index to language array index by skipping separators.
func _dropdown_index_to_language_index(dropdown_index: int) -> int:
    var language_index: int = dropdown_index
    for separator in SEPARATOR_INDICES:
        if separator <= language_index:
            language_index -= 1
    return language_index


## Apply the selected language immediately; Utils persists it in LocalCache.
##
## @param index: Selected entry index in LanguageOptions dropdown
func _on_language_options_item_selected(index: int) -> void:
    var language_index: int = _dropdown_index_to_language_index(index)
    Utils.set_app_locale(LANGUAGE_LOCALES[language_index])


## Reset all options to their defaults (language follows the system language).
func _on_revert_changes_button_pressed() -> void:
    Utils.reset_app_locale()
    _load_options()
