# answer-button-component Specification Delta

## MODIFIED Requirements

### Requirement: The component SHALL display answer text dynamically
The component SHALL display answer text that can be set at runtime via a child Label node.

#### Scenario: Setting answer text
**Given** an answer button component instance  
**When** `set_answer(text: String, index: int)` is called  
**Then** the AnswerLabel child node displays the provided text  
**And** the answer text is accessible via the `answer_text` property

#### Scenario: Reading answer text
**Given** an answer button with text "Paris"  
**When** external code reads `button.answer_text`  
**Then** the value "Paris" is returned

---

## REMOVED Requirements

### Requirement: The component SHALL start in neutral state by default
*Removed - No longer using StyleBox bg_color, neutral state is now controlled by modulate.*

---

## ADDED Requirements

### Requirement: The component SHALL use TextureButton as base class
The component SHALL extend TextureButton instead of Button to support custom texture-based visuals.

#### Scenario: Base class implementation
**Given** the answer button component script  
**When** checking the class definition  
**Then** the script uses `extends TextureButton`  
**And** all TextureButton properties are available (texture_normal, texture_pressed, flip_h, etc.)

---

### Requirement: The component SHALL use modulate for color feedback
The component SHALL use `self_modulate` to tint the button texture for correct/wrong states, preparing for future shader implementation.

#### Scenario: Show correct state with modulate
**Given** an answer button in any state  
**When** `reveal_correct()` is called  
**Then** `self_modulate` animates to green tint Color(0.2, 0.8, 0.2, 1.0)  
**And** the animation duration respects the exported `animation_duration` property

#### Scenario: Show wrong state with modulate
**Given** an answer button in any state  
**When** `reveal_wrong()` is called  
**Then** `self_modulate` animates to red tint Color(0.8, 0.2, 0.2, 1.0)  
**And** the animation duration respects the exported `animation_duration` property

#### Scenario: Reset modulate to neutral
**Given** an answer button showing correct or wrong state  
**When** `reset()` is called  
**Then** `self_modulate` is set to neutral color  
**And** the button returns to its neutral appearance

---

### Requirement: The component SHALL expose answer text as readable property
The component SHALL provide read-only access to the current answer text for validation purposes.

#### Scenario: Property exposure
**Given** an answer button component in the editor or code  
**When** accessing the `answer_text` property  
**Then** the current answer text is returned  
**And** the property cannot be set directly (read-only)

---

### Requirement: The component SHALL maintain compatibility for shader integration
The component SHALL use a color approach that can be easily replaced with shader-based effects in the future.

#### Scenario: Shader-ready implementation
**Given** future shader implementation for color effects  
**When** replacing `self_modulate` approach with shader material  
**Then** the change requires minimal code modification  
**Because** `self_modulate` and shader materials both affect visual appearance in compatible ways

---

## Unchanged Requirements
*The following requirements remain unchanged:*
- The component SHALL signal answer selection with index
- The component SHALL disable itself after press
- The component SHALL show visual indication of selection
- The component SHALL expose customizable colors via inspector
- The component SHALL support flexible layout for different screen sizes
- The component SHALL use scene-based architecture
