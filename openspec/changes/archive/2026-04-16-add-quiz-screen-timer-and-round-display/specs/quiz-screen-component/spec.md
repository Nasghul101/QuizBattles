# Spec Delta: quiz-screen-component (timer and round display)

**Capability**: quiz-screen-component  
**Change**: add-quiz-screen-timer-and-round-display  
**Scope**: quiz_screen.gd, quiz_screen.tscn (no structural changes), gameplay_screen.gd

---

## MODIFIED Requirements

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

## ADDED Requirements

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
The `TimeLimitBar.value` SHALL decrease from 1.0 to 0.0 proportionally over `time_limit` seconds while the timer is running.

#### Scenario: Bar at half time
**Given** time_limit = 20.0 and 10.0 seconds have elapsed  
**When** the _process callback runs  
**Then** `time_limit_bar.value` is approximately 0.5

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
