# answer-review-screen-component Specification Delta

## MODIFIED Requirements

### Requirement: The component SHALL display answer visual states using answer_button API
The component SHALL use the `answer_button` component's public methods exclusively
to set visual states — no direct StyleBox manipulation is permitted. All four
buttons must be set to a static (non-pulsating) state when loaded.

Replaces the old requirement: "Player's choice has white outline — StyleBox border_width = 3"

#### Scenario: Correct answer is green
**Given** a loaded review screen  
**When** an answer button holds the correct answer  
**Then** `reveal_correct()` is called on that button (green self_modulate)

#### Scenario: Incorrect answers are red
**Given** a loaded review screen  
**When** an answer button holds an incorrect answer  
**Then** `reveal_wrong()` is called on that button (red self_modulate)

#### Scenario: Player's choice has white shader outline
**Given** a loaded review screen  
**When** an answer button text matches `question_data["player_answer"]`  
**Then** `set_shader_outline_color(Color.WHITE)` is called on that button,
producing a white border from the predefined outline shader

#### Scenario: Pulsating is disabled on all buttons
**Given** a loaded review screen  
**When** `load_review_data()` runs  
**Then** `set_pulsating_enabled(false)` is called on every answer button before
any colour state is applied

#### Scenario: Answer buttons are non-interactable
**Given** a loaded review screen  
**When** displaying the review  
**Then** all answer buttons have `disabled = true`

#### Scenario: populate uses set_answer API
**Given** question data with correct_answer and incorrect_answers  
**When** `load_review_data(question_data)` is called  
**Then** each answer button is populated via `button.set_answer(answer_text, i)`,
not via a `.text` property assignment
