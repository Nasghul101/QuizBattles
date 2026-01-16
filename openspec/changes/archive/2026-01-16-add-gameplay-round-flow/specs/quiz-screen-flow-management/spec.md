# quiz-screen-flow-management Specification Delta

## Purpose
Enhance quiz screen with signal-based communication and NextQuestion button control to enable orchestrated question flow.

## ADDED Requirements

### Requirement: The component SHALL emit signal when question is answered
The quiz screen SHALL notify the orchestrator when a player selects an answer, including correctness information.

#### Scenario: Emit answer signal on selection
**Given** the quiz screen displays a question  
**When** the player selects an answer  
**Then** the `question_answered(was_correct)` signal is emitted with true or false

#### Scenario: Include correctness in signal
**Given** the quiz screen has "Paris" as the correct answer  
**When** the player selects "Paris"  
**Then** `question_answered(true)` is emitted  
**When** the player selects "London"  
**Then** `question_answered(false)` is emitted

---

### Requirement: The component SHALL emit signal when next question is requested
The quiz screen SHALL notify the orchestrator when the player presses the NextQuestion button.

#### Scenario: Emit next question signal
**Given** the quiz screen has revealed answer states  
**And** the NextQuestion button is visible  
**When** the player presses the NextQuestion button  
**Then** the `next_question_requested()` signal is emitted

---

### Requirement: The component SHALL control NextQuestion button visibility
The quiz screen SHALL show the NextQuestion button only after an answer is selected and hide it when loading a new question.

#### Scenario: Hide button initially
**Given** a quiz screen instance loads  
**When** `_ready()` completes  
**Then** the NextQuestion button is hidden

#### Scenario: Hide button on question load
**Given** the NextQuestion button is visible from a previous question  
**When** `load_question(data)` is called with new question data  
**Then** the NextQuestion button is hidden  
**And** answer buttons are reset to unselected state

#### Scenario: Show button after answer selection
**Given** the quiz screen displays a question  
**When** the player selects an answer  
**And** answer states are revealed  
**Then** the NextQuestion button becomes visible

---

### Requirement: The component SHALL maintain existing answer selection logic
The quiz screen SHALL continue to prevent multiple answer selections and reveal correct/wrong states.

#### Scenario: Prevent multiple selections
**Given** the quiz screen has `has_answered = true`  
**When** the player attempts to select another answer  
**Then** no action occurs and no signal is emitted

#### Scenario: Reveal all button states on answer
**Given** the player selects any answer  
**When** the selection is processed  
**Then** all answer buttons reveal their correct/wrong states  
**And** the `answer_correct` signal is emitted if the answer was correct (existing behavior)

---

## MODIFIED Requirements

### Requirement: The component SHALL support signal-based orchestration
Previously, the quiz screen was self-contained. Now it SHALL emit signals for external orchestration.

#### Scenario: Coordinate with external flow controller
**Given** the gameplay screen manages question flow  
**When** quiz screen emits `question_answered(was_correct)` signal  
**Then** the gameplay screen handler receives the signal  
**And** can record the result before showing NextQuestion button

#### Scenario: Delegate navigation control
**Given** the quiz screen emits `next_question_requested()` signal  
**When** the gameplay screen receives the signal  
**Then** the gameplay screen decides whether to load another question or complete the round
