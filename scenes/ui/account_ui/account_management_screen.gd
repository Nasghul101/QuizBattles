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


## Initialize the screen with current user's statistics.
##
## Fetches user data from UserDatabase, populates all labels, pie chart,
## and category statistics. Calculates draws from total_games - (wins + losses).
func _ready() -> void:
    # Get current user
    var current_user: Dictionary = UserDatabase.get_current_user()
    if current_user.is_empty():
        push_error("Account management screen opened without signed-in user")
        return
    
    # Fetch user data for display
    var user_data: Dictionary = UserDatabase.get_user_data_for_display(current_user.username)
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
## played and wins counts for each category, and updates the component.
## Shows 0/0/0% for categories with no data.
##
## @param category_stats: Dictionary mapping category names to {played, wins}
func _populate_category_statistics(category_stats: Dictionary) -> void:
    for child in category_statistics_container.get_children():
        # Get the category from the component's export variable
        var category: String = child.category
        
        # Look up category data
        var played: int = 0
        var wins: int = 0
        
        if category_stats.has(category):
            var stats: Dictionary = category_stats[category]
            played = stats.get("played", 0)
            wins = stats.get("wins", 0)
        
        # Update component
        child.set_win_amount(wins)
        child.set_played_amount(played)
        child.set_win_rate()


## Navigate back to main lobby screen.
func _on_back_button_pressed() -> void:
    Utils.navigate_to_scene("main_lobby")


## Sign out current user and navigate to main lobby.
func _on_log_off_button_pressed() -> void:
    UserDatabase.sign_out()
    Utils.navigate_to_scene("main_lobby")
