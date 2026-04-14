# answer-button-component Specification Delta

## MODIFIED Requirements

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
