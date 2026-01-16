# gameplay-screen-initialization Specification Delta

## Purpose
Configuration and initialization of gameplay screen with game parameters.

## MODIFIED Requirements

### Requirement: Gameplay screen MUST initialize result component containers dynamically
Previously, result components were static in the tscn. Now the screen SHALL create result components dynamically based on num_rounds.

#### Scenario: Remove existing result components
**Given** ResultContainerL and ResultContainerR have child nodes from the tscn  
**When** `_ready()` executes  
**Then** all existing children in both containers are removed via `queue_free()`

#### Scenario: Create result components based on configuration
**Given** `num_rounds` is set to 3  
**When** `_ready()` executes after initialization  
**Then** 3 result component instances are created and added to ResultContainerL  
**And** 3 result component instances are created and added to ResultContainerR  
**And** each component is initialized with `initialize_empty(num_questions)`

#### Scenario: Handle variable round counts
**Given** `num_rounds` is set to 5  
**When** `_ready()` executes  
**Then** 5 result components are created in each container  
**Given** `num_rounds` is set to 1  
**When** `_ready()` executes  
**Then** 1 result component is created in each container

---

## ADDED Requirements

### Requirement: Gameplay screen MUST instantiate child components on ready
The gameplay screen SHALL create and configure category popup and quiz screen as children during initialization.

#### Scenario: Instantiate category popup
**Given** the gameplay screen loads  
**When** `_ready()` executes  
**Then** a category_popup_component instance is created  
**And** added as a child of gameplay screen  
**And** set to invisible by default

#### Scenario: Instantiate quiz screen
**Given** the gameplay screen loads  
**When** `_ready()` executes  
**Then** a quiz_screen instance is created  
**And** added as a child of gameplay screen  
**And** set to invisible by default

---

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
**And** `api_failed` is connected to `_on_api_failed` handler

---

### Requirement: Gameplay screen MUST connect PlayButton signal
The gameplay screen SHALL respond to PlayButton presses to initiate round flow.

#### Scenario: Connect PlayButton
**Given** the gameplay screen has a PlayButton child node  
**When** `_ready()` executes  
**Then** the PlayButton `pressed` signal is connected to `_on_play_button_pressed` handler
