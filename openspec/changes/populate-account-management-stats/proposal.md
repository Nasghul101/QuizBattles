# Populate Account Management Screen with User Statistics

## Problem
When a logged-in user navigates to the account management screen via the profile button on the main lobby, the screen displays placeholder values instead of the user's actual statistics. The pie chart, total games, wins/losses/draws, and category statistics are not populated with real data, making the account management screen non-functional for viewing user performance.

## Solution
Implement data population logic in `account_management_screen.gd` to load and display the current user's statistics when the screen is ready. Update the user database schema to track `total_games` and restructure `category_stats` to store both played counts and win counts per category. Extend the `update_player_statistics()` function to update category-level statistics and total games after each match.

## Changes

### Files to Modify
- `scenes/ui/account_ui/account_management_screen.gd` - Add `_ready()` logic to populate UI with user data
- `autoload/user_database.gd` - Add `total_games` field, restructure `category_stats`, update match completion logic
- User database schema - Migrate existing users to new structure

### Key Behaviors
1. **Screen Population**: On `_ready()`, fetch current user data and populate all labels, pie chart, and category statistics
2. **Total Games Tracking**: Store `total_games` as a separate field, incremented after each match completion
3. **Draws Calculation**: Calculate draws as `total_games - (wins + losses)` for display purposes
4. **Category Stats Structure**: Change from `{"History": 12}` to `{"History": {"played": 12, "wins": 8}}`
5. **Back Button**: Navigate to main lobby screen using `Utils.navigate_to_scene("main_lobby")`
6. **Log Off Button**: Call `UserDatabase.sign_out()`, then navigate to main lobby screen
7. **Empty State**: When user has no games, show pie chart inspector defaults and category stats as "0 / 0 / 0%"

### Affected Capabilities
- **account-management-screen**: Add data population requirements
- **local-user-database**: Modify schema and match completion statistics update

## Dependencies
- Existing `UserDatabase.get_current_user()` and `UserDatabase.get_user_data_for_display()` methods
- Existing `piechart.gd` `set_chart()` method
- Existing `category_statistic_dissplay.gd` setter methods
- Existing `Utils.navigate_to_scene()` navigation helper
- Existing `update_player_statistics()` function for match completion

## Testing
- Verify logged-in user sees correct stats on account screen
- Verify new user with 0 games shows empty state correctly
- Verify pie chart displays correct percentages for wins/draws/losses
- Verify category statistics show correct played/wins/winrate per category
- Verify back button returns to main lobby
- Verify log off button logs out and returns to main lobby
- Verify stats update correctly after completing a match

## Notes
- The pie chart component already expects wins, draws, and total games as separate parameters
- Category statistic display components already have setters for win amount, played amount, and win rate
- The UI structure is already in place with proper unique names for all labels and components
- No migration of historical match data needed - category stats start fresh from this point forward
