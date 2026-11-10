## MODIFIED Requirements

### Requirement: Populate User Statistics on Screen Load
The account management screen SHALL fetch and display the current logged-in user's statistics when the screen becomes ready, including total games, wins, losses, draws (calculated), pie chart visualization, and per-category answer statistics.

**Rationale:** Users need to view their performance data when accessing the account management screen.

**Cross-reference:** Uses `local-user-database.get_user_data_for_display()` and its `category_stats` answer-count structure.

#### Scenario: Display statistics for user with game history
- **GIVEN** user "Player123" is logged in with `total_games: 50`, `wins: 30`, and `losses: 15`
- **AND** the user has `category_stats: {"History": {"total_answers": 20, "correct_answers": 12}, "Science": {"total_answers": 15, "correct_answers": 8}}`
- **WHEN** the account management screen loads
- **THEN** the player name label SHALL display "Player123"
- **AND** total games, wins, draws, and losses SHALL display 50, 30, 5, and 15 respectively
- **AND** the pie chart SHALL display 30 wins, 5 draws, and 15 losses
- **AND** the History category SHALL display 12 answered correctly out of 20 total answers and 60% accuracy
- **AND** the Science category SHALL display 8 answered correctly out of 15 total answers and 53% accuracy
- **AND** categories without data SHALL display 0 answered correctly, 0 total answers, and 0% accuracy

#### Scenario: Display empty state for new user
- **GIVEN** user "NewPlayer" is logged in with zero total games, wins, and losses
- **AND** the user's `category_stats` is empty
- **WHEN** the account management screen loads
- **THEN** the player name and all overall statistics SHALL display their zero or user-name values
- **AND** every category SHALL display 0 answered correctly, 0 total answers, and 0% accuracy

#### Scenario: Calculate draws correctly
- **GIVEN** a user has `total_games: 100`, `wins: 60`, and `losses: 30`
- **WHEN** the account management screen calculates draws
- **THEN** draws SHALL equal 10
- **AND** the draws label SHALL display "10"

### Requirement: Populate Category Statistics from User Data
The account management screen SHALL iterate through all category statistic display components and populate each with the corresponding answer counts from the user's `category_stats` dictionary.

**Rationale:** Users need to see their answer accuracy and total answers by category.

**Cross-reference:** Uses nested `{"correct_answers": int, "total_answers": int}` category statistics from `local-user-database`.

#### Scenario: Populate multiple categories with data
- **GIVEN** the user has History `{"total_answers": 25, "correct_answers": 18}`, Geography `{"total_answers": 10, "correct_answers": 4}`, and Sports `{"total_answers": 8, "correct_answers": 8}`
- **WHEN** category statistics are displayed
- **THEN** History SHALL show "Answered Correctly" 18, "Total Answers" 25, and 72% accuracy
- **AND** Geography SHALL show "Answered Correctly" 4, "Total Answers" 10, and 40% accuracy
- **AND** Sports SHALL show "Answered Correctly" 8, "Total Answers" 8, and 100% accuracy

#### Scenario: Handle missing category data gracefully
- **GIVEN** the user has answer statistics for History but no entry for the other displayed categories
- **WHEN** category statistics are displayed
- **THEN** History SHALL show its correct and total answer counts and calculated accuracy
- **AND** categories without data SHALL show 0 answered correctly, 0 total answers, and 0% accuracy
- **AND** no error SHALL occur because category data is missing

#### Scenario: Iterate through all category components
- **GIVEN** the category statistics container has 12 category components
- **WHEN** the account management screen populates category statistics
- **THEN** all 12 components SHALL display their matching answer counts or zero values when no data exists
- **AND** each component's accuracy SHALL be calculated as integer percentage `correct_answers / total_answers`
- **AND** a category with zero total answers SHALL display 0% accuracy

#### Scenario: Use answer-accuracy labels
- **GIVEN** a category statistic component is displayed
- **WHEN** its labels are rendered
- **THEN** the correct-answer count SHALL be labeled "Answered Correctly"
- **AND** the denominator SHALL be labeled "Total Answers"
- **AND** the percentage SHALL be labeled "Accuracy"
