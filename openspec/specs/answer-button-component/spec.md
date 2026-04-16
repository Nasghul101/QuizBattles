# answer-button-component Specification

## Purpose
TBD - created by archiving change add-answer-button-component. Update Purpose after archive.
## Requirements
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

### Requirement: The component SHALL signal answer selection with index
The component SHALL notify when pressed and include which answer it represents.

#### Scenario: Button pressed
**Given** an answer button with index 2  
**When** the user presses the button  
**Then** the component emits `answer_selected(index: int)` signal with value 2

---

### Requirement: The component SHALL disable itself after press
The component SHALL prevent further interaction after being pressed.

#### Scenario: Disable on press
**Given** an answer button that has been pressed  
**When** the user attempts to press it again  
**Then** the button does not respond to input

---

### Requirement: The component SHALL show visual indication of selection
The component SHALL show a white outline when it has been pressed by the user.

#### Scenario: Show selection outline
**Given** an answer button is pressed  
**When** the button disables  
**Then** a white outline appears around the button

---

### Requirement: The component SHALL support revealing correct state
The component SHALL display green background when marked as correct answer.

#### Scenario: Show correct state
**Given** an answer button in any state  
**When** `reveal_correct()` is called  
**Then** the button background animates to green color (or exported correct_color)

#### Scenario: Correct state animation duration
**Given** an answer button revealing correct state  
**When** the color transition occurs  
**Then** the animation completes within a reasonable time (default ~0.3s)

---

### Requirement: The component SHALL support revealing wrong state
The component SHALL display red background when marked as wrong answer.

#### Scenario: Show wrong state
**Given** an answer button in any state  
**When** `reveal_wrong()` is called  
**Then** the button background animates to red color (or exported wrong_color)

#### Scenario: Wrong state animation duration
**Given** an answer button revealing wrong state  
**When** the color transition occurs  
**Then** the animation completes within a reasonable time (default ~0.3s)

---

### Requirement: The component SHALL expose customizable colors via inspector
The component SHALL expose color properties that can be configured in the Godot editor.

#### Scenario: Export neutral color
**Given** an answer button component in the editor  
**When** viewing the component's inspector properties  
**Then** `neutral_color` property is visible and editable

#### Scenario: Export correct color
**Given** an answer button component in the editor  
**When** viewing the component's inspector properties  
**Then** `correct_color` property is visible and editable

#### Scenario: Export wrong color
**Given** an answer button component in the editor  
**When** viewing the component's inspector properties  
**Then** `wrong_color` property is visible and editable

---

### Requirement: The component SHALL support flexible layout for different screen sizes
The component SHALL adapt its size and margins to accommodate different mobile screen dimensions.

#### Scenario: Responsive sizing
**Given** an answer button on different screen sizes  
**When** the parent container resizes  
**Then** the button maintains appropriate proportions and margins without overlapping

---

### Requirement: The component SHALL use scene-based architecture
The component SHALL be implemented as a reusable scene file.

#### Scenario: Scene file structure
**Given** the component implementation  
**When** checking the file structure  
**Then** both `answer_button.tscn` and `answer_button.gd` files exist in `scenes/ui/components/`

#### Scenario: Instantiation
**Given** a parent scene needs answer buttons  
**When** the parent scene loads  
**Then** 4 instances of answer_button.tscn can be added without conflicts

### Requirement: The component SHALL use TextureButton as base class
The component SHALL extend TextureButton instead of Button to support custom texture-based visuals.

#### Scenario: Base class implementation
**Given** the answer button component script  
**When** checking the class definition  
**Then** the script uses `extends TextureButton`  
**And** all TextureButton properties are available (texture_normal, texture_pressed, flip_h, etc.)

---

### Requirement: The component SHALL expose shader parameter control methods
The answer button component SHALL provide public methods to set shader uniform
parameters so that callers (e.g. the review screen) can adapt the button's
appearance without directly coupling to the ShaderMaterial type.

#### Scenario: set_pulsating_enabled disables animation
**Given** an answer button with the predefined outline shader material  
**When** `set_pulsating_enabled(false)` is called  
**Then** the `enable_pulsating` shader parameter is set to `false` and the
pulsating animation stops

#### Scenario: set_pulsating_enabled enables animation
**Given** an answer button with pulsating disabled  
**When** `set_pulsating_enabled(true)` is called  
**Then** the `enable_pulsating` shader parameter is set to `true` and the
pulsating animation resumes

#### Scenario: set_shader_outline_color changes outline
**Given** an answer button with the predefined outline shader material  
**When** `set_shader_outline_color(Color.WHITE)` is called  
**Then** the `outline_color` shader parameter equals `Color.WHITE` and the
button's border renders in white

#### Scenario: Null material guard
**Given** an answer button whose material is not a ShaderMaterial (e.g. during
tests or if the scene is misconfigured)  
**When** `set_pulsating_enabled()` or `set_shader_outline_color()` is called  
**Then** the call is a no-op and a `push_warning` is emitted rather than
crashing

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

---

### Requirement: The component SHALL expose shader parameter control methods
The answer button component SHALL provide public methods to set shader uniform
parameters so that callers (e.g. the review screen) can adapt the button's
appearance without directly coupling to the ShaderMaterial type.

#### Scenario: set_pulsating_enabled disables animation
**Given** an answer button with the predefined outline shader material  
**When** `set_pulsating_enabled(false)` is called  
**Then** the `enable_pulsating` shader parameter is set to `false` and the
pulsating animation stops

#### Scenario: set_pulsating_enabled enables animation
**Given** an answer button with pulsating disabled  
**When** `set_pulsating_enabled(true)` is called  
**Then** the `enable_pulsating` shader parameter is set to `true` and the
pulsating animation resumes

#### Scenario: set_shader_outline_color changes outline
**Given** an answer button with the predefined outline shader material  
**When** `set_shader_outline_color(Color.WHITE)` is called  
**Then** the `outline_color` shader parameter equals `Color.WHITE` and the
button's border renders in white

#### Scenario: Null material guard
**Given** an answer button whose material is not a ShaderMaterial (e.g. during
tests or if the scene is misconfigured)  
**When** `set_pulsating_enabled()` or `set_shader_outline_color()` is called  
**Then** the call is a no-op and a `push_warning` is emitted rather than
crashing

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

### Requirement: The component SHALL expose a method to set the pulsating shader color
The `AnswerButton` component SHALL provide a `set_pulsating_color(color: Color)` method that writes the given color to the `pulsating_color` shader parameter of the button's `ShaderMaterial`, following the same null-guard pattern used in `set_pulsating_enabled()` and `set_shader_outline_color()`.

#### Scenario: Set pulsating color on a valid ShaderMaterial
**Given** an `AnswerButton` instance with a `ShaderMaterial` applied  
**When** `set_pulsating_color(Color("#CFDD27"))` is called  
**Then** `material.get_shader_parameter("pulsating_color")` returns `Color("#CFDD27")`

#### Scenario: Graceful no-op when material is not a ShaderMaterial
**Given** an `AnswerButton` instance whose material is not a `ShaderMaterial`  
**When** `set_pulsating_color(Color.WHITE)` is called  
**Then** a warning is pushed via `push_warning()`  
**And** no crash or error occurs

---

