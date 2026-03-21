# Predefined Outline Shader

**Type**: Component Capability  
**Related Systems**: UI rendering, visual effects, texture processing  
**Implementation**: `shaders/predefined_outline_shader.gdshader`

## Overview
A specialized canvas_item shader for UI elements with pre-rendered outline borders in their textures. The shader detects outline pixels based on color (black = outline, white = base), allows dynamic outline color replacement, and provides a texture-based pulsating animation effect using radial gradient masks (e.g., CircleFade.svg) for smooth, professional visual effects.

## ADDED Requirements

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

### Requirement: The shader SHALL provide a texture-based pulsating animation effect
The shader SHALL render an animated effect that travels around the outline using a texture sampler (e.g., CircleFade.svg) as a radial gradient mask, creating smooth transitions as it moves.

#### Scenario: Pulsating effect uses texture as gradient mask
**Given** a UI element with predefined_outline_shader applied  
**When** pulsating is enabled and a fade texture is assigned  
**Then** the fade texture SHALL be sampled based on angular position around the outline  
**And** the texture's values SHALL modulate the pulsating color intensity  
**And** the effect SHALL create a smooth gradient as it travels  
**Because** texture-based gradients produce more sophisticated visual effects than solid colors

#### Scenario: Pulsating effect animates around outline perimeter
**Given** a UI element with pulsating enabled  
**When** time progresses  
**Then** the texture-based gradient effect SHALL move around the outline  
**And** the movement SHALL be smooth and continuous  
**And** the direction SHALL respect the clockwise/counterclockwise setting  
**Because** animated effects draw attention to important UI elements

#### Scenario: Pulsating effect stays within outline boundaries
**Given** a texture with a black outline and white interior  
**When** the pulsating animation is active  
**Then** the animated effect SHALL only appear on detected outline pixels  
**And** base texture pixels SHALL NOT show pulsating effect  
**Because** the effect should enhance the outline without affecting the content area

#### Scenario: Pulsating effect can be toggled on/off
**Given** a ShaderMaterial using predefined_outline_shader  
**When** the "Enable Pulsating" boolean property is set  
**Then** pulsating animation SHALL activate when true  
**And** SHALL be completely disabled when false (no performance cost)  
**And** the default value SHALL be false (disabled)  
**Because** not all UI elements need animated effects

---

### Requirement: The shader SHALL expose fade texture sampler as an inspector property
The shader SHALL provide a configurable texture sampler uniform that allows designers to assign radial gradient textures for the pulsating effect.

#### Scenario: Designer assigns CircleFade texture to material
**Given** a ShaderMaterial using predefined_outline_shader  
**When** the designer opens the material in the inspector  
**Then** a "Fade Texture" property SHALL be visible accepting Texture2D  
**And** assigning CircleFade.svg SHALL use it for pulsating gradient  
**And** different gradient textures can be assigned for variation  
**Because** designers need flexibility to use different gradient patterns

#### Scenario: Shader handles missing fade texture gracefully
**Given** a ShaderMaterial with pulsating enabled but no fade texture assigned  
**When** the shader renders  
**Then** the shader SHALL NOT crash or produce errors  
**And** pulsating effect SHALL fall back to a default behavior (solid color or disabled)  
**Because** shader must be robust to incomplete configuration

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

### Requirement: The shader SHALL expose pulsating size as an inspector property
The shader SHALL provide a configurable uniform that controls how much of the outline area the fade gradient covers (spread/concentration of the effect).

#### Scenario: Pulsating size controls gradient spread
**Given** a ShaderMaterial with pulsating enabled and size set to 0.5  
**When** the pulsating animation is active  
**Then** the fade gradient SHALL cover a smaller area (concentrated spotlight effect)  
**And** increasing size to 2.0 SHALL spread the gradient over a wider area  
**And** the gradient SHALL remain within detected outline pixels  
**And** the default size SHALL be 1.0  
**Because** different UI elements and outline widths require different effect intensities

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

### Requirement: The shader SHALL calculate angular position based on UV coordinates
The shader SHALL determine each outline pixel's angular position relative to the texture center to enable circumferential animation effects.

#### Scenario: Angular position is calculated from texture center
**Given** an outline pixel at UV coordinates (0.75, 0.5)  
**When** the shader calculates angular position  
**Then** position SHALL be relative to center (0.5, 0.5)  
**And** angle SHALL be calculated using atan(dy, dx)  
**And** angle SHALL be normalized to 0.0-1.0 range  
**Because** animation needs consistent rotational mapping regardless of texture shape

#### Scenario: Time-based offset animates angular position
**Given** an outline pixel with angular position 0.25  
**When** time progresses with speed 1.0 and counterclockwise direction  
**Then** animated position SHALL be (0.25 - TIME) wrapped to 0.0-1.0 range  
**And** the wrapping SHALL create continuous rotation  
**Because** animation must loop seamlessly around the outline

---

### Requirement: The shader SHALL sample fade texture based on angular position and radial distance
The shader SHALL map the fade texture using angular position as the primary coordinate and distance from center for radial gradient application.

#### Scenario: Fade texture sampling creates rotational effect
**Given** an outline pixel with animated angular position 0.5  
**When** the shader samples the fade texture  
**Then** the U coordinate SHALL be the animated angular position  
**And** the V coordinate SHALL be based on distance from center scaled by size parameter  
**And** the sampled value SHALL modulate pulsating color intensity  
**Because** this mapping creates a gradient that travels around the outline

---

### Requirement: The shader SHALL blend pulsating effect with base outline color
The shader SHALL combine the color-replaced outline with the texture-based pulsating effect using smooth interpolation.

#### Scenario: Pulsating effect blends smoothly with outline color
**Given** an outline pixel with replacement color red and pulsating color cyan  
**When** fade texture value is 0.0 at that position  
**Then** final color SHALL be mostly red (outline color)  
**When** fade texture value is 1.0  
**Then** final color SHALL be mostly cyan (pulsating color)  
**When** fade texture value is 0.5  
**Then** final color SHALL be a 50/50 blend of red and cyan  
**Because** smooth blending creates professional gradient transitions

---

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
**Then** base texture SHALL be sampled once  
**And** fade texture SHALL be sampled once (only for outline pixels)  
**And** no additional sampling loops SHALL be executed  
**Because** excessive texture samples degrade mobile performance
