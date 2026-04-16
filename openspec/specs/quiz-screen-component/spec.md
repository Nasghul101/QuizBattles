# quiz-screen-component Specification

## Purpose
TBD - created by archiving change add-quiz-screen-component. Update Purpose after archive.
## Requirements
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
The quiz screen SHALL determine if the selected answer is correct or incorrect using the answer button's text property.

#### Scenario: Correct answer selected
**Given** a quiz screen with answer "Paris" at button index 2  
**When** the user presses button index 2  
**Then** the quiz screen reads `answer_buttons[2].answer_text`  
**And** compares it with `correct_answer_text`  
**And** identifies this as a correct answer

#### Scenario: Incorrect answer selected
**Given** a quiz screen with answer "Paris" at button index 2  
**When** the user presses button index 0  
**Then** the quiz screen reads `answer_buttons[0].answer_text`  
**And** compares it with `correct_answer_text`  
**And** identifies this as an incorrect answer

---

### Requirement: The component SHALL reveal all button states after selection
The quiz screen SHALL show correct/wrong visual states on all answer buttons by comparing each button's answer text property.

#### Scenario: Reveal correct button state
**Given** an answer button containing the correct answer  
**When** any answer button is pressed  
**Then** the quiz screen compares `button.answer_text == correct_answer_text`  
**And** calls `reveal_correct()` on the button with matching text

#### Scenario: Reveal incorrect button states
**Given** answer buttons containing incorrect answers  
**When** any answer button is pressed  
**Then** the quiz screen compares each `button.answer_text != correct_answer_text`  
**And** calls `reveal_wrong()` on all buttons with non-matching text

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

### Requirement: The component SHALL display category information
The quiz screen SHALL display the question's category in a dedicated label above the question panel.

#### Scenario: Display category from question data
**Given** a quiz screen with CategoryLabel node  
**When** `load_question(data)` is called with data containing `"category": "Entertainment"`  
**Then** the CategoryLabel displays "Entertainment"

#### Scenario: Category updates per question
**Given** a quiz screen showing a Science category question  
**When** a new question with category "History" is loaded  
**Then** the CategoryLabel updates to display "History"  
**And** the previous category text is replaced

#### Scenario: Category from trivia service format
**Given** question data from TriviaQuestionService  
**When** the data includes the simplified category name (e.g., "Entertainment" instead of "Entertainment: Film")  
**Then** the category label displays the simplified format directly  
**And** no additional parsing or formatting is needed

---

### Requirement: The component SHALL use TextureRect for visual panels
The quiz screen SHALL use TextureRect nodes for the question panel and category header instead of standard Panel nodes.

#### Scenario: Question panel structure
**Given** the quiz screen scene file  
**When** loaded in the editor  
**Then** the question panel is a TextureRect node  
**And** the QuestionLabel is a child of the TextureRect

#### Scenario: Category panel structure
**Given** the quiz screen scene file  
**When** loaded in the editor  
**Then** the category section is a TextureRect node  
**And** the CategoryLabel is a child of the TextureRect

---

### Requirement: The component SHALL display the current round number
The `RoundNumber` label SHALL show the active round as a human-readable string when `set_round_number(round: int)` is called.

#### Scenario: Round number displayed correctly
**Given** the quiz screen component is instantiated  
**When** `set_round_number(1)` is called  
**Then** the `RoundNumber` label displays exactly `"1"`

#### Scenario: Round number updates between rounds
**Given** the quiz screen has previously shown round 2  
**When** `set_round_number(3)` is called  
**Then** the label displays exactly `"3"`

---

### Requirement: The component SHALL expose a configurable time limit
The quiz screen SHALL export a `time_limit` property (float, seconds) so that designers can edit it in the Godot Inspector without code changes.

#### Scenario: Default time limit in Inspector
**Given** a quiz screen scene is opened in the editor  
**When** the root node is selected  
**Then** a `time_limit` float property is visible in the Inspector with a default value greater than 0

#### Scenario: Time limit supports sub-second precision
**Given** the `time_limit` export  
**When** the designer sets it to 15.5  
**Then** the timer runs for exactly 15.5 seconds before expiring

---

### Requirement: The component SHALL start a countdown timer when a question loads
Each call to `load_question()` SHALL reset and start the countdown from `time_limit` seconds.

#### Scenario: Timer resets on new question
**Given** a quiz screen with time_limit = 20.0  
**When** `load_question(data)` is called for the first question  
**Then** the countdown starts at 20.0 seconds  
**And** the TimeLimitBar renders at full value (1.0 normalized)

#### Scenario: Timer resets between questions
**Given** a player answered question 1 with 8 seconds remaining  
**When** `load_question(data)` is called for question 2  
**Then** the countdown resets to 20.0 seconds again  
**And** the bar returns to full

---

### Requirement: The component SHALL decrease the TimeLimitBar as time elapses
The `TimeLimitBar.value` SHALL decrease proportionally over `time_limit` seconds while the timer is running.

#### Scenario: Bar at half time
**Given** time_limit = 20.0 and 10.0 seconds have elapsed  
**When** the _process callback runs  
**Then** `time_limit_bar.value` is approximately half of `time_limit`

#### Scenario: Bar reaches zero
**Given** time_limit = 20.0 and 20.0 seconds have elapsed  
**When** the _process callback runs  
**Then** `time_limit_bar.value` is 0.0  
**And** the timer is marked as no longer running

---

### Requirement: The component SHALL stop the timer when the player answers
The countdown SHALL stop immediately when the player presses any answer button.

#### Scenario: Timer stops on answer press
**Given** a running timer with 12 seconds remaining  
**When** the player presses any answer button  
**Then** `_timer_running` is set to false  
**And** the bar stops decreasing at its current value

---

### Requirement: The component SHALL auto-select a wrong answer on timeout
When the countdown reaches zero without player input, the quiz screen SHALL automatically select a random incorrect answer button, triggering the same answer-selected flow as a manual press.

#### Scenario: Auto-select wrong answer on timeout
**Given** a quiz screen with 4 answer buttons and no player input  
**When** the timer expires  
**Then** one of the buttons whose `answer_text` does NOT match `correct_answer_text` is selected  
**And** `question_answered` signal fires with `was_correct = false`  
**And** all button states are revealed (correct shown green, wrong shown red)  
**And** the NextQuestion button becomes visible immediately (same path as a manual press)

#### Scenario: Correct answer is never auto-selected
**Given** a quiz screen where the timer expires  
**When** the auto-selection logic runs  
**Then** only buttons containing incorrect answers are candidates  
**And** the correct answer button is never auto-selected

#### Scenario: Timeout treated same as manual wrong answer for scoring
**Given** a timeout auto-selection  
**When** `question_answered` fires  
**Then** `was_correct` is `false`  
**And** the `player_answer` string equals the auto-selected button's `answer_text`

---

### Requirement: The component SHALL apply a category accent color when loading a question
When `load_question(data)` is called, the quiz screen SHALL resolve the accent color for the question's category from `Utils.get_color_codes()["category_colors"]` and apply it to the `GradientLabel` category header and all four `AnswerButton` components.

#### Scenario: Known category with defined color
**Given** `color_codes.json` defines `"Science": "#00B8E8"`  
**When** `load_question({"category": "Science", ...})` is called  
**Then** `category_label.set_accent_color(Color("#00B8E8"))` is called  
**And** `set_pulsating_color(Color("#00B8E8"))` is called on all four answer buttons

#### Scenario: Known category with null color
**Given** `color_codes.json` defines `"General Knowledge": null`  
**When** `load_question({"category": "General Knowledge", ...})` is called  
**Then** `category_label.set_accent_color(Color.WHITE)` is called  
**And** `set_pulsating_color(Color.WHITE)` is called on all four answer buttons

#### Scenario: Category key absent from question data
**Given** question data that has no `"category"` key  
**When** `load_question(data)` is called  
**Then** `set_accent_color(Color.WHITE)` and `set_pulsating_color(Color.WHITE)` are called (white fallback)

#### Scenario: Category name not present in color_codes.json
**Given** question data with `"category": "UnknownCategory"`  
**When** `load_question(data)` is called  
**Then** `set_accent_color(Color.WHITE)` and `set_pulsating_color(Color.WHITE)` are called (white fallback)

---

### Requirement: The component SHALL use GradientLabel typed reference for the category label
The `%CategoryLabel` onready reference SHALL be typed as `GradientLabel` (not plain `Label`) so `set_accent_color()` is callable with static typing.

#### Scenario: Static type annotation
**Given** `gradient_label.gd` declares `class_name GradientLabel`  
**When** `quiz_screen.gd` declares `@onready var category_label: GradientLabel = %CategoryLabel`  
**Then** no type error occurs at scene load  
**And** `category_label.set_accent_color(color)` is statically valid

---

