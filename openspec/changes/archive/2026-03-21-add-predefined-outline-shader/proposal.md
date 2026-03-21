# Proposal: Add Predefined Outline Shader

**Change ID**: `add-predefined-outline-shader`  
**Status**: Draft  
**Created**: 2026-03-20

## Summary
Implement a specialized shader material (`predefined_outline_shader.gdshader`) for UI elements that already have outline borders baked into their textures. The shader will detect outline pixels based on color (black = outline, white = base), allow outline color customization, and provide a texture-based pulsating animation effect using CircleFade.svg as a radial gradient mask.

## Motivation
- **Texture-Based UI Elements**: Support the new QuizScreen_Button_*_Outline.svg textures that have pre-rendered black borders
- **Dynamic Color Control**: Allow designers to change outline colors without creating multiple texture variants
- **Enhanced Visual Effects**: Add sophisticated texture-based pulsating animations that use radial gradient masks for smooth, professional-looking effects
- **Reusability**: Create a shader applicable to any UI element with predefined outline textures
- **Mobile-First**: Simple color detection and texture sampling suitable for mobile rendering

## Scope

### In Scope
- Color-based outline pixel detection (black = outline, white = base)
- Dynamic outline color replacement via inspector property
- Texture-based pulsating animation using sampler2D uniform for fade texture
- CircleFade.svg integration as radial gradient mask for pulsating effect
- Configurable pulsating parameters: enable/disable, color, size, speed, direction
- Inspector-exposed properties for all shader parameters
- Compatibility with all CanvasItem nodes (Control, Sprite2D, TextureRect, etc.)

### Out of Scope
- Generating outlines from scratch (use existing `outline_shader.gdshader` for that)
- Support for non-outline textures (shader assumes texture has predefined outline)
- Dynamic shader switching based on game state
- Performance profiling and comparative benchmarking
- Integration with specific components (components will opt-in to use this shader)

## Dependencies
- CircleFade.svg texture asset (already exists at `assets/CircleFade.svg`)
- No spec modifications (new capability)

## Affected Specs
- **NEW**: `predefined-outline-shader` - Complete specification for the shader system

## Related Work
- Existing shader: `shaders/outline_shader.gdshader` (generates outlines around textures)
- Related assets:
  - `assets/ui/QuizScreen_Button_Top_Outline.svg` (white with black border)
  - `assets/ui/QuizScreen_Button_Bottom_Outline.svg` (white with black border)
  - `assets/ui/QuizScreen_Header_Outline.svg` (white with black border)
  - `assets/ui/QuizScreen_Questionare_Outline.svg` (white with black border)
  - `assets/CircleFade.svg` (radial gradient for pulsating effect)

## Implementation Notes
- Shader uses `shader_type canvas_item` for 2D UI compatibility
- Outline detection: Check if pixel color is close to black (adjustable threshold)
- Color replacement: Replace black pixels with user-defined outline color
- Pulsating effect: 
  - Sample CircleFade texture based on angular position around outline
  - Move sampling position based on TIME to create animation
  - Use fade texture as alpha mask over custom pulsating color
  - Constrain effect to detected outline pixels only
- All effects independently configurable via shader uniforms
- Default state: outline color replacement enabled, pulsating disabled

## Risks & Mitigations
- **Risk**: Color detection may incorrectly identify near-black pixels as outline  
  **Mitigation**: Expose threshold as inspector property with sensible default (e.g., 0.2)
  
- **Risk**: Texture sampling for pulsating effect may impact mobile performance  
  **Mitigation**: Only sample fade texture when pulsating is enabled, use efficient coordinate calculations
  
- **Risk**: CircleFade texture may not be assigned in materials  
  **Mitigation**: Make texture a visible uniform parameter, provide clear documentation and examples
  
- **Risk**: Pulsating effect may look incorrect with different outline sizes  
  **Mitigation**: Expose size parameter to adjust fade texture coverage area
