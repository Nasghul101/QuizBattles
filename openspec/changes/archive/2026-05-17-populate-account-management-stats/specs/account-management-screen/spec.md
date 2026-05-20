# Account Management Screen - Spec Delta

## MODIFIED Requirements

### Requirement: Populate User Statistics on Screen Load
The account management screen SHALL fetch and display the current logged-in user's statistics when the screen becomes ready, including total games, wins, losses, draws (calculated), pie chart visualization, and per-category statistics.

**Rationale:** Users need to view their performance data when accessing the account management screen. All UI components are already in place with proper unique names, but lack data population logic.

**Cross-reference:** Uses `local-user-database.get_user_data_for_display()` and `local-user-database.total_games` field.

#### Scenario: Display statistics for user with game history
**Given** user "Player123" is logged in with `total_games: 50`, `wins: 30`, `losses: 15`  
**And** user has `category_stats: {"History": {"played": 20, "wins": 12}, "Science": {"played": 15, "wins": 8}}`  
**When** the account management screen `_ready()` function executes  
**Then** the player name label SHALL display "Player123"  
**And** total games label SHALL display "50"  
**And** wins label SHALL display "30"  
**And** draws label SHALL display "5" (calculated as 50 - 30 - 15)  
**And** losses label SHALL display "15"  
**And** the pie chart SHALL be populated by calling `set_chart(30, 5, 50)`  
**And** the History category component SHALL show 12 wins, 20 played, 60% win rate  
**And** the Science category component SHALL show 8 wins, 15 played, 53% win rate  
**And** categories not in `category_stats` SHALL show 0 wins, 0 played, 0% win rate

#### Scenario: Display empty state for new user
**Given** user "NewPlayer" is logged in with `total_games: 0`, `wins: 0`, `losses: 0`  
**And** user has `category_stats: {}`  
**When** the account management screen `_ready()` function executes  
**Then** the player name label SHALL display "NewPlayer"  
**And** total games label SHALL display "0"  
**And** wins label SHALL display "0"  
**And** draws label SHALL display "0"  
**And** losses label SHALL display "0"  
**And** the pie chart SHALL display inspector default values (not call `set_chart()` or call with zeros)  
**And** all category components SHALL show 0 wins, 0 played, 0% win rate

#### Scenario: Calculate draws correctly
**Given** user has `total_games: 100`, `wins: 60`, `losses: 30`  
**When** the account management screen calculates draws  
**Then** draws SHALL equal `100 - 60 - 30 = 10`  
**And** the draws label SHALL display "10"

---

### Requirement: Navigate Back to Main Lobby on Back Button Press
The account management screen SHALL navigate back to the main lobby screen when the BackButton is pressed.

**Rationale:** Users need to return to the main lobby after viewing their account information.

#### Scenario: Back button returns to main lobby
**Given** the account management screen is visible  
**And** user is on the account management screen  
**When** the user presses the BackButton  
**Then** the screen SHALL call `Utils.navigate_to_scene("main_lobby")`  
**And** the user SHALL be navigated to the main lobby screen

---

### Requirement: Log Off and Navigate to Main Lobby on Log Off Button Press
The account management screen SHALL sign out the current user and navigate to the main lobby screen when the LogOffButton is pressed.

**Rationale:** Users need to log out of their account from the account management screen.

**Cross-reference:** Uses `local-user-database.sign_out()`.

#### Scenario: Log off button signs out and returns to main lobby
**Given** user "Player123" is logged in  
**And** the account management screen is visible  
**When** the user presses the LogOffButton  
**Then** the screen SHALL call `UserDatabase.sign_out()`  
**And** the current user session SHALL be cleared  
**And** the screen SHALL call `Utils.navigate_to_scene("main_lobby")`  
**And** the user SHALL be navigated to the main lobby screen as a guest

#### Scenario: Main lobby shows login screen after log off
**Given** user was logged in and pressed LogOffButton  
**When** the user presses the AccountButton on the main lobby  
**Then** the user SHALL be navigated to the register/login screen (not account management)  
**And** this verifies the log off was successful

---

### Requirement: Populate Category Statistics from User Data
The account management screen SHALL iterate through all category statistic display components and populate each with the corresponding category data from the user's `category_stats` dictionary.

**Rationale:** Users need to see their performance breakdown by category to understand their strengths and weaknesses.

**Cross-reference:** Uses restructured `local-user-database.category_stats` with nested `{"played": int, "wins": int}` structure.

#### Scenario: Populate multiple categories with data
**Given** user has `category_stats: {"History": {"played": 25, "wins": 18}, "Geography": {"played": 10, "wins": 4}, "Sports": {"played": 8, "wins": 8}}`  
**When** the account management screen populates category statistics  
**Then** the History component SHALL call `set_win_amount(18)`, `set_played_amount(25)`, and `set_win_rate()` resulting in 72% display  
**And** the Geography component SHALL call `set_win_amount(4)`, `set_played_amount(10)`, and `set_win_rate()` resulting in 40% display  
**And** the Sports component SHALL call `set_win_amount(8)`, `set_played_amount(8)`, and `set_win_rate()` resulting in 100% display  
**And** all other category components SHALL show 0, 0, 0%

#### Scenario: Handle missing category data gracefully
**Given** user has `category_stats: {"History": {"played": 5, "wins": 3}}`  
**And** 11 other categories have no data  
**When** the account management screen populates category statistics  
**Then** the History component SHALL show 3 wins, 5 played, 60% win rate  
**And** all 11 other category components SHALL show 0 wins, 0 played, 0% win rate  
**And** no errors SHALL occur for missing categories

#### Scenario: Iterate through all category components
**Given** the CategoryStatisticsContainer has 12 child category components  
**When** the account management screen populates statistics  
**Then** the screen SHALL iterate through all 12 children  
**And** for each child, extract the `category` export variable  
**And** look up that category in user's `category_stats`  
**And** populate the component with the data (or zeros if not found)
