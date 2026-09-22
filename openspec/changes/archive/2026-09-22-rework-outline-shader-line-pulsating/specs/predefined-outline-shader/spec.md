## REMOVED Requirements
### Requirement: The shader SHALL provide a texture-based pulsating animation effect
**Reason**: Replaced by a procedural rotating radial line effect (see ADDED "The shader SHALL provide a rotating radial line pulsating animation effect").
**Migration**: Remove any `fade_texture` shader parameter overrides; the effect no longer samples a gradient texture.

### Requirement: The shader SHALL expose fade texture sampler as an inspector property
**Reason**: The `fade_texture` uniform is removed along with the texture-based gradient approach it supported.
**Migration**: Remove `shader_parameter/fade_texture` overrides from scenes/materials. No replacement texture assignment is needed.

### Requirement: The shader SHALL expose pulsating size as an inspector property
**Reason**: The `pulsating_size` uniform (gradient coverage multiplier) has no equivalent in the line-based effect.
**Migration**: Remove `shader_parameter/pulsating_size` overrides. Use the new `pulsating_thickness` and `pulsating_blur` uniforms to control the line's visual size instead.

### Requirement: The shader SHALL sample fade texture based on angular position and radial distance
**Reason**: There is no longer a fade texture to sample; the line mask is computed procedurally from pixel-space geometry.
**Migration**: None required for consumers; this was an internal implementation detail.

### Requirement: The shader SHALL calculate angular position based on UV coordinates
**Reason**: Replaced by pixel-space angular calculation (see ADDED "The shader SHALL calculate angular position based on pixel-space coordinates") so the line reads correctly on non-square textures.
**Migration**: None required for consumers; this was an internal implementation detail.

## ADDED Requirements
### Requirement: The shader SHALL provide a rotating radial line pulsating animation effect
The shader SHALL render an animated single line segment that starts at the texture's center, initially points toward the top, has a length equal to the texture's width, and rotates continuously around the center, restricted to detected outline pixels.

#### Scenario: Line originates at center and points to the top
**Given** a UI element with predefined_outline_shader applied and pulsating enabled
**When** TIME is 0.0
**Then** the rendered line SHALL be centered on the texture's center point
**And** the line SHALL extend from the center toward the top edge of the texture
**And** the line's length SHALL equal the texture's width
**Because** this defines the effect's starting orientation and scale

#### Scenario: Line rotates around the center over time
**Given** a UI element with pulsating enabled
**When** TIME progresses
**Then** the line SHALL rotate continuously around the texture's center
**And** the rotation direction SHALL respect the `pulsating_clockwise` setting
**And** the rotation speed SHALL respect the `pulsating_speed` setting
**Because** a continuously rotating line draws attention without requiring a gradient texture

#### Scenario: Line renders only on outline pixels
**Given** a texture with a black outline and white interior processed by the outline detection step
**When** the pulsating line sweeps across the texture
**Then** the line SHALL only be visible where a pixel is already classified as an outline pixel
**And** base texture (non-outline) pixels SHALL NOT be affected by the line at any rotation angle
**Because** the effect must enhance the outline without altering the content area

#### Scenario: Line thickness and blur are constant along its whole length
**Given** a UI element with `pulsating_thickness` and `pulsating_blur` configured
**When** the line is rendered at any point along its length, near the center or near the outer edge
**Then** the perpendicular width of the line and the softness of its edges SHALL be the same regardless of distance from the center
**Because** the effect should read as a straight line of uniform width, not a wedge that narrows toward the center

#### Scenario: Pulsating effect can be toggled on/off
**Given** a ShaderMaterial using predefined_outline_shader
**When** the "Enable Pulsating" boolean property is set
**Then** the rotating line SHALL render when true
**And** SHALL be completely disabled when false (no performance cost)
**And** the default value SHALL be false (disabled)
**Because** not all UI elements need animated effects

### Requirement: The shader SHALL calculate angular position based on pixel-space coordinates
The shader SHALL determine each outline pixel's position relative to the texture center in pixel space (using `TEXTURE_PIXEL_SIZE`) and its angle relative to "pointing at the top" to drive the rotating line effect.

(Note: this requirement is functionally new but replaces the removed "The shader SHALL calculate angular position based on UV coordinates" requirement.)

#### Scenario: Pixel position is converted to pixel space
**Given** an outline pixel at UV coordinates (0.75, 0.5) on a non-square texture
**When** the shader calculates the pixel's offset from center
**Then** the offset SHALL be computed in pixel units using `TEXTURE_PIXEL_SIZE` rather than raw UV units
**Because** pixel-space calculation keeps the line's thickness visually consistent regardless of the texture's aspect ratio

#### Scenario: Angle is measured relative to the top, increasing clockwise
**Given** an outline pixel directly above the texture center
**When** the shader calculates its angle
**Then** the angle SHALL be 0 (pointing at the top)
**And** an outline pixel directly to the right of center SHALL have an angle of +pi/2
**Because** the line must start pointing at the top and rotate clockwise as time and angle increase

#### Scenario: Time-based rotation updates the line's angle
**Given** the line's base angle of 0 (pointing at the top)
**When** TIME progresses with a given `pulsating_speed` and `pulsating_clockwise` setting
**Then** the line's current angle SHALL advance continuously in the configured direction at the configured speed
**Because** continuous rotation creates the animated sweeping effect

## MODIFIED Requirements
### Requirement: The shader SHALL blend pulsating effect with base outline color
The shader SHALL combine the color-replaced outline with the rotating line effect using a smooth width/length mask, constrained to outline pixels.

#### Scenario: Pulsating effect blends smoothly with outline color
**Given** an outline pixel with replacement color red and pulsating color cyan
**When** the pixel is at the exact center of the line (mask value 1.0)
**Then** final color SHALL be fully cyan (pulsating color)
**When** the pixel is outside the line's thickness plus blur range (mask value 0.0)
**Then** final color SHALL be fully red (outline color)
**When** the pixel is within the blur feather region
**Then** final color SHALL be a smooth interpolation between red and cyan
**Because** smooth blending avoids a harsh, aliased edge on the line

### Requirement: The shader SHALL maintain visual quality with minimal performance cost
The shader SHALL be optimized for mobile rendering while providing all visual features.

#### Scenario: Shader runs efficiently on mobile devices
**Given** the shader applied to multiple UI elements
**When** rendering on a mobile device
**Then** frame rate SHALL remain stable (60 FPS target)
**And** pulsating effect SHALL have minimal performance impact
**Because** mobile performance is a project priority

#### Scenario: Shader uses early-exit optimization
**Given** the shader fragment function
**When** enable_pulsating is false
**Then** pulsating calculations SHALL be skipped entirely
**And** only outline color replacement SHALL execute
**Because** disabled effects should have zero performance cost

#### Scenario: Shader performs minimal texture sampling
**Given** the shader with pulsating enabled
**When** rendering a pixel
**Then** the base texture SHALL be sampled once
**And** no additional texture samples SHALL be performed for the rotating line effect (it is computed procedurally)
**Because** avoiding extra texture samples keeps the effect cheap on mobile devices

## ADDED Requirements
### Requirement: The shader SHALL expose pulsating line thickness as an inspector property
The shader SHALL provide a configurable uniform, in approximate pixels, controlling the width of the rotating line.

#### Scenario: Designer adjusts line thickness
**Given** a ShaderMaterial using predefined_outline_shader with pulsating enabled
**When** the designer adjusts the "Pulsating Thickness" property
**Then** the rendered line's width SHALL change accordingly, measured in approximate pixels
**And** the default thickness SHALL be 6.0 pixels
**Because** different outline widths and texture sizes require different line thicknesses

### Requirement: The shader SHALL expose pulsating line blur as an inspector property
The shader SHALL provide a configurable uniform, in the 0.0-1.0 range, controlling the softness of the rotating line's edges, applied uniformly along the entire length of the line regardless of distance from the center.

#### Scenario: Designer adjusts line blur
**Given** a ShaderMaterial using predefined_outline_shader with pulsating enabled
**When** the designer sets "Pulsating Blur" to 0.0
**Then** the line SHALL have a hard, unfeathered edge
**When** the designer increases "Pulsating Blur" toward 1.0
**Then** the line's edges SHALL become progressively softer
**And** the softness SHALL be consistent along the whole length of the line, not just near the center or the outer tip
**And** the default blur SHALL be 0.25
**Because** designers need control over how crisp or soft the animated line appears
