# quiz-screen-component Specification Delta

**Change ID:** `add-quiz-screen-component`  
**Capability:** `quiz-screen-component` (new)

## ADDED Requirements

### Requirement: The component SHALL display question text in a styled panel
The quiz screen SHALL display the question text in a prominent panel container at the top of the screen.

#### Scenario: Question panel structure
**Given** the quiz screen component is instantiated  
**When** the scene loads  
**Then** a Panel node with a Label child is present at the top of the screen

#### Scenario: Display question text
**Given** a quiz screen with loaded question data  
**When** `load_question(data)` is called with `{"question": "What is 2+2?"}`  
**Then** the question label displays "What is 2+2?"

---

### Requirement: The component SHALL arrange answer buttons in a 2x2 grid
The quiz screen SHALL display exactly 4 answer button instances arranged in a 2-column grid.

#### Scenario: Grid layout structure
**Given** the quiz screen component is instantiated  
**When** the scene loads  
**Then** a GridContainer with 2 columns contains 4 answer_button instances

#### Scenario: All buttons are initially visible
**Given** a quiz screen before loading question data  
**When** the scene is ready  
**Then** all 4 answer buttons are visible and enabled

---

### Requirement: The component SHALL load question data from dictionary
The quiz screen SHALL accept question data in Open Trivia DB format via a public method.

#### Scenario: Load question with correct format
**Given** a quiz screen instance  
**When** `load_question(data)` is called with valid data containing "question", "correct_answer", and "incorrect_answers" keys  
**Then** the question displays and all 4 buttons show answer text

#### Scenario: Expected data format
**Given** question data from Open Trivia DB  
**When** the data contains "question" (String), "correct_answer" (String), and "incorrect_answers" (Array of 3 Strings)  
**Then** the quiz screen can parse and display this data correctly

---

### Requirement: The component SHALL shuffle answers randomly
The quiz screen SHALL randomize the position of the correct answer among the 4 answer buttons.

#### Scenario: Shuffle answers on load
**Given** a quiz screen loading question data  
**When** `load_question()` is called with correct answer "Paris" and incorrect answers ["London", "Berlin", "Madrid"]  
**Then** the 4 answers are distributed randomly across the answer buttons

#### Scenario: Track correct answer after shuffle
**Given** answers have been shuffled among buttons  
**When** the correct answer is assigned to a specific button  
**Then** the quiz screen internally tracks which button index holds the correct answer

---

### Requirement: The component SHALL validate answer selection
The quiz screen SHALL determine if the selected answer is correct or incorrect.

#### Scenario: Correct answer selected
**Given** a quiz screen with answer "Paris" at button index 2  
**When** the user presses button index 2  
**Then** the quiz screen identifies this as a correct answer

#### Scenario: Incorrect answer selected
**Given** a quiz screen with answer "Paris" at button index 2  
**When** the user presses button index 0  
**Then** the quiz screen identifies this as an incorrect answer

---

### Requirement: The component SHALL reveal all button states after selection
The quiz screen SHALL show correct/wrong visual states on all answer buttons immediately after any button is pressed.

#### Scenario: Reveal correct button state
**Given** an answer button containing the correct answer  
**When** any answer button is pressed  
**Then** the button with the correct answer displays green (via `reveal_correct()`)

#### Scenario: Reveal incorrect button states
**Given** answer buttons containing incorrect answers  
**When** any answer button is pressed  
**Then** all buttons with incorrect answers display red (via `reveal_wrong()`)

#### Scenario: Immediate reveal timing
**Given** a user presses an answer button  
**When** the button emits `answer_selected` signal  
**Then** all buttons reveal their states within the same frame or immediately after

---

### Requirement: The component SHALL emit signal on correct answer
The quiz screen SHALL emit a signal when the player selects the correct answer.

#### Scenario: Signal emitted for correct answer
**Given** a quiz screen with loaded question  
**When** the user selects the correct answer  
**Then** the `answer_correct` signal is emitted

#### Scenario: No signal for incorrect answer
**Given** a quiz screen with loaded question  
**When** the user selects an incorrect answer  
**Then** no `answer_correct` signal is emitted

---

### Requirement: The component SHALL connect to answer button signals
The quiz screen SHALL listen to each answer button's `answer_selected` signal to handle validation.

#### Scenario: Connect all button signals
**Given** a quiz screen with 4 answer buttons  
**When** the scene is ready  
**Then** all 4 buttons have their `answer_selected` signals connected to the quiz screen's handler

#### Scenario: Handle answer selection
**Given** an answer button emits `answer_selected(index)`  
**When** the quiz screen receives this signal  
**Then** the quiz screen validates the answer and reveals all button states

---

### Requirement: The component SHALL prevent interaction after answer selection
The quiz screen SHALL disable further answer selection once a button has been pressed.

#### Scenario: Disable remaining buttons
**Given** a user has pressed one answer button  
**When** the answer is being validated and revealed  
**Then** all other answer buttons are disabled or ignore input

#### Scenario: Single answer per question
**Given** a quiz screen with an already-selected answer  
**When** the user attempts to press another button  
**Then** the press has no effect

---

### Requirement: The component SHALL use composition-based architecture
The quiz screen SHALL follow Godot composition patterns by using answer_button component instances.

#### Scenario: Instance answer button scenes
**Given** the quiz screen scene file  
**When** loaded in the editor  
**Then** the 4 answer buttons are instances of the answer_button.tscn scene

#### Scenario: No hardcoded button logic
**Given** the quiz screen script  
**When** implementing answer display and reveal  
**Then** the script uses the answer button's public methods (`set_answer()`, `reveal_correct()`, `reveal_wrong()`)

---
