# answer-button-component Specification Delta
# Change: add-category-color-theming

## ADDED Requirements

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
