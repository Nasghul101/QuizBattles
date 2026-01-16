# gameplay-round-orchestration Specification Delta

## Purpose
Central coordinator for managing round-based gameplay flow including state tracking, question distribution, result collection, and round progression.

## ADDED Requirements

### Requirement: The system SHALL track current round state
The gameplay screen SHALL maintain current round number and question index to coordinate flow across multiple rounds.

#### Scenario: Initialize to idle state
**Given** the gameplay screen loads  
**When** `_ready()` completes  
**Then** `current_round` is 0 (idle)  
**And** `current_question_index` is 0

#### Scenario: Increment round on question start
**Given** `current_round` is 0 or N  
**When** questions are ready and first question loads  
**Then** `current_round` is incremented to 1 or N+1

#### Scenario: Track question progression
**Given** a round has 3 questions  
**When** the player requests the next question  
**Then** `current_question_index` increments from 0 to 1 to 2

---

### Requirement: The system SHALL store fetched questions for reuse
The gameplay screen SHALL store questions fetched for the current round to enable identical question distribution for both players.

#### Scenario: Store questions on fetch
**Given** TriviaQuestionService emits `questions_ready` with 3 questions  
**When** the signal handler receives the questions  
**Then** `fetched_questions` array contains all 3 question dictionaries

#### Scenario: Reuse questions for both players
**Given** player 1 has completed questions from `fetched_questions`  
**When** player 2's turn begins (future multiplayer)  
**Then** the same `fetched_questions` array is available for player 2

---

### Requirement: The system SHALL collect answers for result display
The gameplay screen SHALL track player answers and correctness for each question to populate result components after round completion.

#### Scenario: Record answer after each question
**Given** a player answers question 1 correctly  
**When** `question_answered(true)` signal is received  
**Then** `current_round_results` contains one entry with `was_correct: true` and question data

#### Scenario: Accumulate results for full round
**Given** a round has 3 questions  
**When** the player answers all 3 questions  
**Then** `current_round_results` contains 3 entries with complete question data and correctness

---

### Requirement: The system SHALL initiate category selection on PlayButton press
The gameplay screen SHALL show the category popup with 3 random categories when the player presses the PlayButton.

#### Scenario: Show category popup
**Given** the PlayButton is visible and enabled  
**When** the player presses the PlayButton  
**Then** the category popup becomes visible with 3 random categories  
**And** the PlayButton is hidden

#### Scenario: Select 3 random categories
**Given** TriviaQuestionService has 12 available categories  
**When** the PlayButton is pressed  
**Then** 3 unique random categories are selected and displayed in the popup

---

### Requirement: The system SHALL fetch questions after category selection
The gameplay screen SHALL request questions from TriviaQuestionService when a category is selected.

#### Scenario: Trigger question fetch
**Given** the category popup displays 3 categories  
**When** the player selects "History"  
**Then** the popup shows loading state  
**And** `TriviaQuestionService.fetch_questions("History", num_questions)` is called

#### Scenario: Store selected category
**Given** the player selects "Science" category  
**When** the category is selected  
**Then** `selected_category` is set to "Science" for result display

---

### Requirement: The system SHALL display questions sequentially after fetch
The gameplay screen SHALL show the quiz screen with questions one at a time when questions are ready.

#### Scenario: Display first question
**Given** TriviaQuestionService emits `questions_ready` with questions  
**When** the handler receives the questions  
**Then** the category popup is hidden  
**And** the quiz screen becomes visible  
**And** the first question is loaded into quiz screen

#### Scenario: Progress to next question
**Given** the quiz screen shows question 1 of 3  
**When** the player answers and presses NextQuestion button  
**Then** question 2 loads into quiz screen  
**And** the quiz screen remains visible

---

### Requirement: The system SHALL complete round after all questions answered
The gameplay screen SHALL update result components and return to idle state after the player answers all questions in a round.

#### Scenario: Update result components
**Given** a round with 3 questions is complete  
**When** `_complete_round()` is called  
**Then** the next available result component in ResultContainerL receives the round results  
**And** the corresponding result component in ResultContainerR receives identical results

#### Scenario: Determine next available result component
**Given** `current_round` is 2  
**When** the round completes  
**Then** the result component at index 1 (second component) in each container is updated

#### Scenario: Return to idle after round
**Given** the round is complete  
**When** result components are updated  
**Then** the quiz screen is hidden  
**And** the PlayButton is shown again (if more rounds remain)

---

### Requirement: The system SHALL handle API failures gracefully
The gameplay screen SHALL continue normal flow using fallback questions when API fails, with console logging only.

#### Scenario: Continue with fallback questions
**Given** TriviaQuestionService fetches questions and API fails  
**When** `api_failed` signal is emitted  
**Then** a console message is printed  
**And** the normal flow continues when `questions_ready` emits fallback questions

#### Scenario: No user-facing error
**Given** the API fails during question fetch  
**When** fallback questions are used  
**Then** no error popup or message is shown to the player  
**And** the loading state transitions smoothly to question display

---

### Requirement: The system SHALL prevent interaction during active states
The gameplay screen SHALL disable appropriate controls to prevent invalid state transitions.

#### Scenario: Disable PlayButton during category selection
**Given** the category popup is visible  
**When** the player attempts interaction  
**Then** the PlayButton is hidden and cannot be pressed

#### Scenario: Prevent gameplay_screen interaction during quiz
**Given** the quiz screen is visible and answering questions  
**When** the player attempts to interact with gameplay_screen elements  
**Then** gameplay_screen interaction is blocked or ignored

---

### Requirement: The system SHALL complete game after all rounds finished
The gameplay screen SHALL recognize when all configured rounds are complete and prevent further round starts.

#### Scenario: Hide PlayButton after final round
**Given** `num_rounds` is 3 and `current_round` is 3  
**When** the final round completes  
**Then** the PlayButton remains hidden  
**And** all result components are filled with results

#### Scenario: Identify game completion
**Given** all rounds are complete  
**When** `_complete_round()` checks `current_round >= num_rounds`  
**Then** the check returns true  
**And** no more rounds can be started
