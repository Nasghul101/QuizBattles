# quiz-screen-component Specification Delta

## ADDED Requirements

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

## MODIFIED Requirements

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

## Unchanged Requirements
*The following requirements remain unchanged:*
- The component SHALL arrange answer buttons in a 2x2 grid
- The component SHALL load question data from dictionary
- The component SHALL shuffle answers randomly
- The component SHALL emit signal on correct answer
- The component SHALL connect to answer button signals
- The component SHALL prevent interaction after answer selection
- The component SHALL use composition-based architecture
