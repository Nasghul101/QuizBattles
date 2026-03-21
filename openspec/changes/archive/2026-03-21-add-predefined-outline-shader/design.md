# Design: Predefined Outline Shader

**Change ID**: `add-predefined-outline-shader`

## Technical Overview

This shader works with textures that already have baked-in outlines (e.g., white interior with black border). The shader's responsibilities are:
1. Detect which pixels are part of the outline vs the base texture
2. Allow dynamic color replacement for outline pixels
3. Apply a texture-based pulsating animation effect that travels around the outline

## Architecture

### Core Components

1. **Outline Detection**
   - **Algorithm**: Color threshold comparison
   - **Input**: Current pixel's RGB color from base texture
   - **Output**: Boolean (is outline pixel)
   - **Logic**: Check if color is "close to black" using configurable threshold

2. **Color Replacement**
   - **Algorithm**: Conditional color substitution
   - **Input**: Detected outline pixels, user-defined replacement color
   - **Output**: Final pixel color
   - **Logic**: If pixel is outline, replace with custom color; otherwise, keep original

3. **Texture-Based Pulsating**
   - **Algorithm**: Angular position-based texture sampling with time animation
   - **Input**: Pixel position, TIME, fade texture sampler, pulsating parameters
   - **Output**: Blended color for outline pixels
   - **Logic**: Calculate angular position → animate offset → sample fade texture → use as alpha mask

### Shader Uniforms (Inspector Properties)

```gdscript
// Outline color replacement
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0)  // White
uniform float outline_threshold : hint_range(0.0, 1.0) = 0.2  // Black detection sensitivity

// Pulsating animation
uniform bool enable_pulsating = false
uniform sampler2D fade_texture  // CircleFade.svg or other radial gradient
uniform vec4 pulsating_color : source_color = vec4(0.0, 1.0, 1.0, 1.0)  // Cyan
uniform float pulsating_size : hint_range(0.1, 2.0) = 1.0  // Coverage area multiplier
uniform float pulsating_speed : hint_range(0.1, 5.0) = 1.0  // Animation speed
uniform bool pulsating_clockwise = false  // Direction control
```

## Outline Detection Algorithm

### Color Threshold Approach

```
For each pixel:
  1. Sample texture color at UV coordinate
  2. Calculate grayscale value: (R + G + B) / 3
  3. If grayscale < outline_threshold:
       → Pixel is part of outline
     Else:
       → Pixel is part of base texture
```

**Why grayscale threshold?**
- Simple and fast calculation
- Works well for black outlines (R=0, G=0, B=0)
- Threshold allows tolerance for near-black pixels
- Mobile-friendly (no complex color distance calculations)

**Threshold Rationale:**
- `0.2` default handles pure black (0.0) and very dark grays (< 0.2)
- Adjustable for textures with slightly different outline colors
- Higher values = more aggressive outline detection
- Lower values = stricter black-only detection

## Texture-Based Pulsating Animation

### Conceptual Flow

```
1. Detect if pixel is outline (from color threshold)
2. Calculate pixel's angular position around center
3. Add time-based offset to create animation
4. Sample fade texture at rotated position
5. Use fade texture value as alpha mask for pulsating color
6. Blend with base outline color
```

### Angular Position Calculation

```
For outline pixel at UV coordinate (u, v):
  1. Center-relative position: 
     dx = u - 0.5
     dy = v - 0.5
  
  2. Angular position (radians):
     angle = atan(dy, dx)  // Range: -π to π
  
  3. Normalize to 0..1:
     normalized_angle = (angle + π) / (2π)
```

### Time-Based Animation

```
Animated offset:
  direction = pulsating_clockwise ? 1.0 : -1.0
  offset = TIME * pulsating_speed * direction
  
Animated angle:
  animated_angle = normalized_angle + offset
  wrapped_angle = fract(animated_angle)  // Keep in 0..1 range
```

### Fade Texture Sampling

```
Fade texture coordinate:
  1. Use animated_angle as primary coordinate (circumferential)
  2. Use distance from center for radial gradient
  3. Scale by pulsating_size parameter
  
Sample calculation:
  distance_from_center = sqrt(dx² + dy²)
  fade_uv = vec2(wrapped_angle, distance_from_center * pulsating_size)
  fade_value = texture(fade_texture, fade_uv).a  // Use alpha channel
```

**Why this approach?**
- CircleFade.svg is a radial gradient (bright center, dark edges)
- Mapping angle to U coordinate creates rotational movement
- Mapping distance to V coordinate applies radial gradient
- Size parameter adjusts how much of the outline the gradient covers

### Blending Strategy

```
Final outline pixel color:
  1. Base: outline_color (user-defined replacement color)
  2. Pulsating: pulsating_color * fade_value
  3. Blend: mix(outline_color, pulsating_color, fade_value)
  
Result:
  - Where fade_value = 1.0 (bright center): mostly pulsating_color
  - Where fade_value = 0.0 (dark edges): mostly outline_color
  - Creates smooth gradient transition as effect travels around outline
```

## Boundary Constraints

### Outline-Only Effect
- Pulsating effect ONLY applied to pixels identified as outline
- Base texture pixels (white interior) remain unaffected
- Ensures visual effect stays within border area

### Size Parameter Bounds
- Controls how concentrated/spread the fade effect appears
- Smaller values (0.1-0.5): Tight spotlight effect
- Default value (1.0): Natural gradient coverage
- Larger values (1.5-2.0): Wide, diffuse glow

## Performance Considerations

### Mobile Optimization
1. **Early Exit**: Skip pulsating calculations if `enable_pulsating == false`
2. **Efficient Sampling**: Only one additional texture sample (fade_texture) per pixel
3. **Simple Math**: Basic trigonometry and vector math (suitable for mobile GPUs)
4. **No Loops**: All calculations are per-pixel, no iterative sampling

### Memory Footprint
- One additional texture (CircleFade.svg) shared across all materials
- Minimal uniform storage (8 parameters)
- No render targets or framebuffer overhead

## Comparison with Solid-Color Pulsating

### Existing `outline_shader.gdshader` Approach
- Generates outline by sampling surrounding pixels
- Pulsating uses solid color band that rotates
- No texture sampling for animation

### New `predefined_outline_shader.gdshader` Approach
- Assumes outline exists in texture already
- Pulsating uses texture-based gradient for smooth effects
- Single additional texture sample per frame

**Trade-offs:**
- ✅ More sophisticated visual effect (gradient vs solid)
- ✅ No multi-pixel sampling for outline detection (faster for simple detection)
- ⚠️ Requires texture asset (CircleFade.svg)
- ⚠️ Additional texture sample (minimal performance cost)

## Alternative Approaches Considered

### 1. Alpha-Based Outline Detection
**Rejected**: Outline textures have full opacity for both outline and base (alpha = 1.0 everywhere)

### 2. UV Distance-Based Pulsating
**Rejected**: Would require knowing exact outline shape, which varies per texture

### 3. Procedural Gradient Generation
**Rejected**: More complex shader code, less designer control, harder to preview

### 4. Multi-Texture Mask Approach
**Rejected**: Would require separate mask textures for each UI element

## Implementation Risks

### Risk 1: Color Detection Edge Cases
**Problem**: Textures with anti-aliased edges may have gray pixels at outline boundary  
**Mitigation**: Adjustable threshold parameter allows fine-tuning per texture

### Risk 2: Fade Texture Coordinate Mapping
**Problem**: Incorrect UV mapping could cause distortion or incorrect animation  
**Mitigation**: Use well-tested atan2 and distance calculations, validate with circular test textures

### Risk 3: Different Outline Widths
**Problem**: Some textures may have thicker/thinner outlines  
**Mitigation**: Size parameter adjusts coverage; threshold parameter adjusts detection range

## Testing Strategy

### Unit Tests (Visual Validation)
1. **Color Detection**: Test with pure black (#000000), near-black (#101010), and gray (#808080) outlines
2. **Threshold Tuning**: Verify threshold values 0.1, 0.2, 0.3, 0.5 detect appropriate pixels
3. **Animation Direction**: Confirm clockwise/counterclockwise movement is correct
4. **Size Scaling**: Test size values 0.5, 1.0, 1.5, 2.0 for visual coverage
5. **Texture Compatibility**: Test with all QuizScreen_*_Outline.svg textures

### Integration Tests
1. Apply shader to TextureRect, Sprite2D, and Button nodes
2. Verify pulsating effect respects outline boundaries
3. Confirm no visual artifacts on non-outline pixels
4. Test with different CircleFade texture variations

### Performance Tests
1. Apply shader to 10+ UI elements simultaneously
2. Monitor frame rate on target mobile device
3. Verify early-exit optimization (pulsating disabled vs enabled)
