## MODIFIED Requirements

### Requirement: Update Category Statistics After Match Completion
The system SHALL update category answer statistics for both players when a match completes, counting each stored answer result under the category of its round.

**Rationale:** Provide category-level answer accuracy based on what players actually answered rather than the overall match winner.

**Implementation:** Category answer counts are applied once with the existing atomic match-statistics update.

#### Scenario: Increment category played count for both players
- **GIVEN** a completed match has one History round
- **AND** Player1 has two correct results and one incorrect result in that round
- **AND** Player2 has one correct result and two incorrect results in that round
- **WHEN** match statistics are processed
- **THEN** each player's History `total_answers` SHALL increase by 3
- **AND** Player1's History `correct_answers` SHALL increase by 2
- **AND** Player2's History `correct_answers` SHALL increase by 1

#### Scenario: Increment category win count for winner only
- **GIVEN** a completed match has a winner and a loser who both answered questions in History
- **WHEN** category answer statistics are processed
- **THEN** the former category win count SHALL NOT be awarded based on the overall match winner
- **AND** each player's History `correct_answers` SHALL increase only by that player's correct results
- **AND** each player's History `total_answers` SHALL increase by that player's stored result count

#### Scenario: Initialize new category with both played and wins
- **GIVEN** a player's `category_stats` is empty
- **WHEN** that player has stored answers in the History category in a completed match
- **THEN** the History entry SHALL contain integer `correct_answers` and `total_answers` values
- **AND** those values SHALL equal the correct and total stored results for that category

#### Scenario: Track multiple categories in single match
- **GIVEN** a completed match has two History rounds and one Science round
- **AND** a player has two results in each History round, one correct in the first and two correct in the second
- **AND** the player has three results in Science, two of them correct
- **WHEN** category answer statistics are processed
- **THEN** History `total_answers` SHALL increase by 4 and `correct_answers` SHALL increase by 3
- **AND** Science `total_answers` SHALL increase by 3 and `correct_answers` SHALL increase by 2

#### Scenario: Count recorded timeout results
- **GIVEN** a timed-out question is stored as an incorrect result in a player's round
- **WHEN** category answer statistics are processed
- **THEN** that result SHALL increase the category's `total_answers` by 1
- **AND** it SHALL NOT increase `correct_answers`

#### Scenario: Handle draw with category updates
- **GIVEN** a completed match is a draw and has stored answer results in History and Science
- **WHEN** match statistics are processed
- **THEN** both players' category answer counts SHALL reflect their stored results
- **AND** the draw SHALL NOT prevent those category counts from being updated

#### Scenario: Extract categories from match rounds_data
- **GIVEN** a completed match contains rounds with categories and per-player stored result arrays
- **WHEN** category answer statistics are processed
- **THEN** each stored result SHALL be associated with the category of its containing round
- **AND** empty or missing round categories SHALL NOT create category statistic entries

#### Scenario: Save database after category updates
- **GIVEN** category answer statistics have been updated for both players
- **WHEN** the match-statistics transaction completes successfully
- **THEN** both profiles and the match's finished and processed state SHALL be persisted atomically

#### Scenario: Process answer statistics only once
- **GIVEN** a match has already been processed
- **WHEN** its statistics are processed again
- **THEN** no category answer counts SHALL change

#### Scenario: Surface backend failure
- **GIVEN** Firebase cannot atomically persist the match and profile statistics
- **WHEN** statistics processing is attempted
- **THEN** the operation SHALL report failure
- **AND** the match SHALL NOT be treated as successfully processed

### Requirement: Restructure Category Stats to Track Wins and Played
The system SHALL store each category statistic in the profile as `{"correct_answers": int, "total_answers": int}` and preserve that structure in returned display data.

**Rationale:** Provide per-category correct-answer and total-answer counts for calculating answer accuracy.

#### Scenario: New profile has empty category stats
- **GIVEN** a new Firebase profile is created
- **WHEN** its statistics are initialized
- **THEN** `category_stats` SHALL be an empty dictionary

#### Scenario: New user receives empty category stats with new structure
- **GIVEN** a new Firebase profile is created
- **WHEN** its category statistics are initialized
- **THEN** `category_stats` SHALL be an empty dictionary

#### Scenario: Record category results
- **GIVEN** a completed match includes category answer results
- **WHEN** statistics are processed
- **THEN** category entries SHALL use integer `correct_answers` and `total_answers` values

#### Scenario: Category stats stored in new nested format
- **GIVEN** category answers are processed for a user
- **WHEN** the Firebase profile is updated
- **THEN** each category entry SHALL contain integer `correct_answers` and `total_answers` values

#### Scenario: Return category stats for display
- **GIVEN** a profile contains category answer statistics
- **WHEN** profile display data is requested
- **THEN** the nested `correct_answers` and `total_answers` values SHALL be included unchanged

#### Scenario: Category stats included in display data with new structure
- **GIVEN** a Firestore profile has nested category answer statistics
- **WHEN** profile display data is requested
- **THEN** the nested category statistics SHALL be returned unchanged

#### Scenario: Keep category stats out of current-user summary
- **GIVEN** a user is signed in
- **WHEN** the current-user summary is requested
- **THEN** it SHALL exclude `category_stats`

#### Scenario: Category stats excluded from current user data
- **GIVEN** a user is signed in
- **WHEN** the current-user summary is requested
- **THEN** it SHALL exclude `category_stats`

#### Scenario: Initialize missing category stats
- **GIVEN** a Firestore profile has no `category_stats` field
- **WHEN** the profile is loaded
- **THEN** `category_stats` SHALL be initialized as an empty dictionary

#### Scenario: Migrate existing category stats to new format
- **GIVEN** a profile contains legacy `played` and `wins` category values
- **WHEN** the new category answer-statistics format is used
- **THEN** those legacy values SHALL NOT be treated as answer counts
- **AND** no historical backfill SHALL be performed

#### Scenario: Migrate user without category stats field
- **GIVEN** a Firestore profile has no `category_stats` field
- **WHEN** the profile is loaded
- **THEN** `category_stats` SHALL be initialized as an empty dictionary

#### Scenario: Empty category stats remain empty after migration
- **GIVEN** a profile has empty category statistics
- **WHEN** the profile is loaded
- **THEN** the field SHALL remain an empty dictionary
- **AND** placeholder categories SHALL NOT be persisted

### Requirement: Provide Placeholder Category Data Generation
The system SHALL provide a helper function to generate placeholder category statistics for testing and UI development before real category tracking is available.

**Rationale:** Allow social features to be developed and tested visually without waiting for real category tracking.

**Note:** This is temporary functionality marked with TODO comments for future replacement.

#### Scenario: Generate random placeholder category data
- **GIVEN** placeholder category statistics are requested
- **WHEN** `_generate_placeholder_category_stats()` is called
- **THEN** it SHALL return 3 random category names
- **AND** each category SHALL have a positive `total_answers` count no greater than 20
- **AND** each category SHALL have a `correct_answers` count between 0 and its `total_answers` count
- **AND** the helper SHALL remain display-only and SHALL NOT store the generated data

#### Scenario: Use placeholder data when category stats empty
- **GIVEN** a user has empty `category_stats`
- **WHEN** placeholder statistics are generated for UI development
- **THEN** they MAY be displayed temporarily
- **AND** they SHALL NOT be persisted to the database

### Requirement: Category Stats Data Type and Constraints
The `category_stats` field SHALL be a Dictionary where keys are category name Strings and values are nested Dictionaries with integer fields `"correct_answers"` and `"total_answers"`.

**Rationale:** Provide a consistent and valid data structure for per-category answer counts.

**Constraints:**
- Keys SHALL be Strings (category names from `TriviaQuestionService.CATEGORY_MAPPING`)
- Values SHALL be Dictionaries with non-negative integer `"correct_answers"` and `"total_answers"` fields
- `"correct_answers"` SHALL NOT exceed `"total_answers"`
- An empty dictionary SHALL be allowed for users with no recorded answers

#### Scenario: Valid category stats format
- **GIVEN** a user record is created or updated
- **WHEN** `category_stats` is set
- **THEN** it SHALL be a Dictionary with String category keys
- **AND** each category value SHALL contain non-negative integer `correct_answers` and `total_answers` fields
- **AND** each category's `correct_answers` SHALL be no greater than its `total_answers`
