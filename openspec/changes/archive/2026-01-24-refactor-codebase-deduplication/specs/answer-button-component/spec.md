# Answer Button Component - Deduplication Changes

## MODIFIED Requirements

### Requirement: Internal Code Organization
The answer button component SHALL extract duplicated StyleBoxFlat border configuration code into a private helper method to improve maintainability without changing external behavior.

#### Scenario: Configure border via helper method
**Given** the answer button needs to update its border styling  
**When** _on_button_pressed() or reset() is called  
**Then** the private _configure_style_box_border() method is used  
**And** border configuration behavior remains identical to previous implementation  
**And** the code for border width/color setting is not duplicated

### Requirement: Button Press Visual Feedback
The answer button component SHALL continue to add white outline borders when pressed using the refactored helper method with identical visual results.

#### Scenario: Button pressed with border outline
**Given** a quiz question is displayed with answer buttons  
**When** the user presses an answer button  
**Then** the button calls _configure_style_box_border(3, Color.WHITE)  
**And** displays a 3-pixel white outline identically to previous behavior

### Requirement: Button Reset State
The answer button component SHALL continue to remove borders when reset using the refactored helper method with identical visual results.

#### Scenario: Button reset to neutral state
**Given** an answer button has been pressed and has a white outline  
**When** reset() is called for a new question  
**Then** the button calls _configure_style_box_border(0, Color.BLACK)  
**And** the border is removed identically to previous behavior
