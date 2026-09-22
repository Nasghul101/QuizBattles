# predefined-outline-shader Specification

## Purpose
Defines the configurable predefined outline shader used to highlight UI textures.

## Requirements

### Requirement: The shader SHALL detect outline pixels based on color threshold comparison
The shader SHALL identify which pixels are part of the outline by comparing their color values against a configurable threshold, treating dark pixels as outline and light pixels as base texture.

#### Scenario: Pure black pixels are detected as outline
**Given** a texture with a pure black border (#000000) and white interior (#FFFFFF)  
**When** the shader is applied to the texture  
**Then** all black pixels SHALL be identified as outline pixels  
**And** all white pixels SHALL be identified as base texture  
**Because** the shader needs to distinguish between outline and content areas

#### Scenario: Near-black pixels are detected with threshold tolerance
**Given** a texture with anti-aliased edges containing near-black pixels (#101010)  
**When** the outline detection threshold is set to 0.2  
**Then** pixels with grayscale value < 0.2 SHALL be identified as outline  
**And** pixels with grayscale value >= 0.2 SHALL be identified as base texture  
**Because** real textures may have slight color variations due to anti-aliasing

#### Scenario: Threshold adjustment controls detection sensitivity
**Given** a shader material with predefined_outline_shader applied  
**When** the designer adjusts the "Outline Threshold" property from 0.1 to 0.5  
**Then** the range of detected outline pixels SHALL expand  
**And** more near-black pixels SHALL be classified as outline  
**Because** different textures may have different outline darkness levels

---

### Requirement: The shader SHALL replace outline pixel colors with a custom color
The shader SHALL render detected outline pixels using a user-defined color instead of the original black color, while preserving the base texture colors unchanged.

#### Scenario: Outline color is replaced with custom color
**Given** a texture with black outline pixels  
**When** the shader's "Outline Color" is set to red (#FF0000)  
**Then** all detected outline pixels SHALL render as red  
**And** the base texture pixels SHALL retain their original colors  
**And** alpha channel SHALL be preserved  
**Because** designers need to customize outline colors without creating new texture variants

#### Scenario: Outline color supports full RGBA control
**Given** a shader material with predefined_outline_shader  
**When** the designer sets "Outline Color" with RGB and alpha values  
**Then** detected outline pixels SHALL use the specified RGBA color  
**And** alpha channel SHALL control outline transparency  
**And** semi-transparent outlines SHALL blend correctly with background  
**Because** visual effects may require translucent outlines

---

### Requirement: The shader SHALL expose outline detection threshold as an inspector property
The shader SHALL provide a configurable uniform for the color detection threshold that determines which pixels are classified as outline.

#### Scenario: Designer adjusts outline detection threshold
**Given** a ShaderMaterial using predefined_outline_shader applied to a UI element  
**When** the designer opens the material in the inspector  
**Then** an "Outline Threshold" property SHALL be visible with range 0.0 to 1.0  
**And** adjusting the value SHALL immediately update which pixels are detected as outline  
**And** the default value SHALL be 0.2  
**Because** different textures require different detection sensitivities

---

### Requirement: The shader SHALL expose outline replacement color as an inspector property
The shader SHALL provide a configurable uniform for the outline color that replaces detected black pixels.

#### Scenario: Designer customizes outline replacement color
**Given** a ShaderMaterial using predefined_outline_shader  
**When** the designer opens the material in the inspector  
**Then** an "Outline Color" property SHALL be visible as a color picker  
**And** adjusting the color SHALL immediately update the rendered outline  
**And** alpha channel SHALL be editable and functional  
**And** the default color SHALL be white (#FFFFFF) with full opacity  
**Because** UI themes require coordinated color schemes across elements

---

### Requirement: The shader SHALL expose pulsating color as an inspector property
The shader SHALL provide a configurable uniform for the pulsating animation color that is modulated by the fade texture.

#### Scenario: Designer sets pulsating color
**Given** a ShaderMaterial with pulsating enabled  
**When** the designer adjusts the "Pulsating Color" property  
**Then** the animated effect color SHALL change accordingly  
**And** the color SHALL be modulated by the fade texture gradient  
**And** the default color SHALL be cyan (#00FFFF) with full opacity  
**Because** pulsating effects need to contrast with the base outline color

---

### Requirement: The shader SHALL expose pulsating speed as an inspector property
The shader SHALL provide a configurable uniform that controls the animation speed of the pulsating effect.

#### Scenario: Designer adjusts pulsating speed
**Given** a ShaderMaterial with pulsating enabled  
**When** the "Pulsating Speed" property is adjusted  
**Then** higher values SHALL make the animation move faster around the outline  
**And** lower values SHALL slow down the animation  
**And** the default speed SHALL be 1.0  
**Because** different UI contexts require different animation intensities

---

### Requirement: The shader SHALL expose pulsating direction as an inspector property
The shader SHALL provide a configurable uniform that controls whether the pulsating animation travels clockwise or counterclockwise around the outline.

#### Scenario: Designer controls pulsating direction
**Given** a ShaderMaterial with pulsating enabled  
**When** the "Pulsating Clockwise" boolean is toggled  
**Then** the animation SHALL move clockwise when true  
**And** SHALL move counterclockwise when false  
**And** the default SHALL be false (counterclockwise)  
**Because** design flexibility allows matching different visual themes and movement patterns

---

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

### Requirement: The shader SHALL be compatible with all CanvasItem node types
The shader SHALL function correctly when applied to any Godot node that uses canvas_item rendering.

#### Scenario: Shader works on Control nodes
**Given** a Control node (Button, Panel, TextureRect, etc.) with a predefined outline texture  
**When** a ShaderMaterial using predefined_outline_shader is applied  
**Then** all shader effects SHALL render correctly  
**And** outline color replacement and pulsating SHALL function as expected  
**Because** UI controls are primary use cases for this shader

#### Scenario: Shader works on Sprite2D nodes
**Given** a Sprite2D node with a predefined outline texture  
**When** a ShaderMaterial using predefined_outline_shader is applied  
**Then** all shader effects SHALL render correctly  
**And** outline pixels SHALL be properly detected and colored  
**Because** sprite-based UI elements are common in 2D games

---

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
