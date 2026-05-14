# Implementation Tasks

## 1. Update UserDatabase Schema and Migration
- [x] 1.1 Add `total_games: int` field to user creation in `create_user()` (initialize to 0)
- [x] 1.2 Update `_migrate_user_data()` to add `total_games: 0` for existing users without the field
- [x] 1.3 Update `category_stats` structure from `{category: count}` to `{category: {"played": count, "wins": count}}`
- [x] 1.4 Write migration logic to convert existing `category_stats` format to new nested structure
- [x] 1.5 Ensure `get_user_data_for_display()` returns `total_games` in the dictionary

## 2. Update Match Statistics Logic
- [x] 2.1 In `update_player_statistics()`, increment `total_games` for both players after validation
- [x] 2.2 Track category information during match (extract from `rounds_data`)
- [x] 2.3 For each category played in the match, update `category_stats[category]["played"]` for both players
- [x] 2.4 For winner's categories, increment `category_stats[category]["wins"]`
- [x] 2.5 Handle case where category doesn't exist yet in user's `category_stats` (initialize with `{"played": 0, "wins": 0}`)
- [x] 2.6 Save database after updating category statistics

## 3. Implement Account Management Screen Data Population
- [x] 3.1 Implement `_ready()` function in `account_management_screen.gd`
- [x] 3.2 Call `UserDatabase.get_user_data_for_display(current_user.username)` to fetch user data
- [x] 3.3 Extract username and set to the player name label at top of screen
- [x] 3.4 Extract `wins`, `losses`, `total_games` from user data
- [x] 3.5 Calculate draws as `total_games - (wins + losses)`
- [x] 3.6 Populate total games label: `total_games_amount.text = str(total_games)`
- [x] 3.7 Populate wins label: `wins_amount.text = str(wins)`
- [x] 3.8 Populate draws label: `draws_amount.text = str(draws)`
- [x] 3.9 Populate losses label: `loss_amount.text = str(losses)`
- [x] 3.10 Call pie chart's `set_chart(wins, draws, total_games)` to populate chart

## 4. Populate Category Statistics
- [x] 4.1 Get reference to `CategoryStatisticsContainer` GridContainer node
- [x] 4.2 Iterate through all child nodes (category statistic display components)
- [x] 4.3 For each category component, get its `category` export variable
- [x] 4.4 Look up category data in user's `category_stats` dictionary
- [x] 4.5 If category exists, extract `played` and `wins` counts
- [x] 4.6 If category doesn't exist, use `played = 0` and `wins = 0`
- [x] 4.7 Call component's `set_win_amount(wins)` setter
- [x] 4.8 Call component's `set_played_amount(played)` setter
- [x] 4.9 Call component's `set_win_rate()` to calculate and display percentage

## 5. Implement Navigation Button Handlers
- [x] 5.1 Implement `_on_back_button_pressed()` to call `Utils.navigate_to_scene("main_lobby")`
- [x] 5.2 Implement `_on_log_off_button_pressed()` to call `UserDatabase.sign_out()`
- [x] 5.3 After sign out, navigate to main lobby with `Utils.navigate_to_scene("main_lobby")`
- [x] 5.4 Verify button signals are connected in `.tscn` file

## 6. Handle Empty State
- [x] 6.1 Test behavior when `total_games == 0` - pie chart should display inspector defaults
- [x] 6.2 Verify category statistics show "0", "0", "0%" when no category data exists
- [x] 6.3 Ensure no division-by-zero errors in win rate calculation (already handled in component)

## 7. Update Documentation
- [x] 7.1 Add GDScript doc comments to `_ready()` function explaining data population
- [x] 7.2 Update `user_database.gd` doc comments for `total_games` field
- [x] 7.3 Update `category_stats` field documentation to reflect new nested structure
- [x] 7.4 Document category statistics update logic in `update_player_statistics()`

## 8. Testing & Validation
- [ ] 8.1 Test with existing user that has played matches - verify correct stats display
- [ ] 8.2 Test with new user (0 games) - verify empty state displays correctly
- [ ] 8.3 Complete a match and verify stats update on account screen
- [ ] 8.4 Test back button returns to main lobby
- [ ] 8.5 Test log off button signs out and returns to main lobby
- [ ] 8.6 Test pie chart shows correct proportions for wins/draws/losses
- [ ] 8.7 Test category statistics show correct data for multiple categories
- [ ] 8.8 Run `openspec validate populate-account-management-stats --strict` and fix any issues
