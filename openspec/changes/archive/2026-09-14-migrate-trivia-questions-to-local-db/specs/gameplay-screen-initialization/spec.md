## MODIFIED Requirements
### Requirement: Gameplay screen MUST connect to child component signals
The gameplay screen SHALL establish signal connections during initialization to coordinate flow.

#### Scenario: Connect category popup signals
**Given** the category popup is instantiated
**When** `_ready()` completes
**Then** the `category_selected` signal is connected to `_on_category_selected` handler

#### Scenario: Connect quiz screen signals
**Given** the quiz screen is instantiated
**When** `_ready()` completes
**Then** the `question_answered` signal is connected to `_on_question_answered` handler
**And** the `next_question_requested` signal is connected to `_on_next_question_requested` handler

#### Scenario: Connect service signals
**Given** the gameplay screen is ready
**When** TriviaQuestionService signals are connected
**Then** `questions_ready` is connected to `_on_questions_ready` handler
