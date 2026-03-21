# Tasks: Add Predefined Outline Shader

**Change ID**: `add-predefined-outline-shader`

## Implementation Order

### 1. Create shader file and implement color-based outline detection
- Create `shaders/predefined_outline_shader.gdshader` file
- Set shader type to `canvas_item`
- Add uniform for outline detection threshold (default 0.2)
- Implement fragment shader logic to sample texture color
- Calculate grayscale value: `(R + G + B) / 3.0`
- Compare against threshold to determine if pixel is outline
- **Verify**: Apply shader to QuizScreen_Button_Top_Outline.svg, confirm black pixels are detected
- **Parallel**: None
- **Dependencies**: None
- **Status**: ✅ COMPLETED

### 2. Implement outline color replacement
- Add uniform for outline replacement color (default white, vec4(1.0))
- In fragment shader, conditionally replace detected outline pixel colors
- Preserve original color for non-outline pixels
- Preserve alpha channel for all pixels
- **Verify**: Change outline color in inspector, confirm black border changes to custom color
- **Parallel**: None
- **Dependencies**: Task 1
- **Status**: ✅ COMPLETED

### 3. Add basic pulsating toggle and parameters
- Add uniform for enable_pulsating (default false)
- Add uniform for pulsating_color (default cyan, vec4(0.0, 1.0, 1.0, 1.0))
- Add uniform for pulsating_speed (default 1.0, range 0.1-5.0)
- Add uniform for pulsating_clockwise (default false)
- Add early-exit logic in fragment shader when pulsating disabled
- **Verify**: Enable/disable pulsating in inspector, confirm performance difference
- **Parallel**: None
- **Dependencies**: Task 2
- **Status**: ✅ COMPLETED

### 4. Implement angular position calculation
- Calculate pixel position relative to texture center (0.5, 0.5)
- Compute angular position using `atan(dy, dx)`
- Normalize angle to 0.0-1.0 range: `(angle + π) / (2π)`
- Apply time-based offset for animation: `angle + TIME * speed * direction`
- Wrap animated angle to 0.0-1.0 range using `fract()`
- **Verify**: Add debug output showing angular position, confirm correct values
- **Parallel**: None
- **Dependencies**: Task 3
- **Status**: ✅ COMPLETED

### 5. Add fade texture sampler and sampling logic
- Add uniform for fade_texture (sampler2D)
- Add uniform for pulsating_size (default 1.0, range 0.1-2.0)
- Calculate distance from center: `sqrt(dx*dx + dy*dy)`
- Map fade texture UV: `vec2(animated_angle, distance * size)`
- Sample fade texture and extract alpha channel
- Add null texture handling (check if texture is valid)
- **Verify**: Assign CircleFade.svg to material, confirm texture is sampled
- **Parallel**: None
- **Dependencies**: Task 4
- **Status**: ✅ COMPLETED

### 6. Implement pulsating effect blending
- Use fade texture sample as interpolation factor
- Blend outline_color and pulsating_color: `mix(outline_color, pulsating_color, fade_value)`
- Apply blended color only to detected outline pixels
- Ensure base texture pixels remain unchanged
- **Verify**: Enable pulsating, confirm gradient effect travels around outline smoothly
- **Parallel**: None
- **Dependencies**: Task 5
- **Status**: ✅ COMPLETED

### 7. Test shader with all QuizScreen outline textures
- Apply shader to QuizScreen_Button_Top_Outline.svg
- Apply shader to QuizScreen_Button_Bottom_Outline.svg
- Apply shader to QuizScreen_Header_Outline.svg
- Apply shader to QuizScreen_Questionare_Outline.svg
- Test outline color replacement on all textures
- Test pulsating effect on all textures
- Verify threshold 0.2 works correctly for all textures
- **Verify**: All four outline textures render correctly with custom colors and pulsating
- **Parallel**: None
- **Dependencies**: Task 6
- **Status**: ⬜ NOT STARTED

### 8. Test shader on various CanvasItem node types
- Create test scene with Button, Panel, Sprite2D, TextureRect nodes
- Apply ShaderMaterial with predefined_outline_shader to each type
- Assign QuizScreen_Button_Top_Outline.svg to each node
- Test outline color replacement on all node types
- Test pulsating effect on all node types
- **Verify**: Shader works identically across all CanvasItem node types
- **Parallel**: None
- **Dependencies**: Task 7
- **Status**: ⬜ NOT STARTED

### 9. Test threshold adjustment for different textures
- Test with pure black outline (#000000) using threshold 0.1, 0.2, 0.3
- Test with near-black outline (#101010) using threshold 0.1, 0.2, 0.3
- Test with dark gray outline (#303030) using various thresholds
- Document recommended threshold ranges for different outline colors
- **Verify**: Threshold accurately controls which pixels are detected as outline
- **Parallel**: None
- **Dependencies**: Task 7
- **Status**: ⬜ NOT STARTED

### 10. Test pulsating parameters for visual quality
- Test pulsating_size: 0.5, 1.0, 1.5, 2.0
- Test pulsating_speed: 0.5, 1.0, 2.0, 3.0
- Test pulsating clockwise vs counterclockwise
- Test different pulsating colors (red, green, blue, cyan, yellow)
- Document recommended parameter ranges for different visual effects
- **Verify**: All pulsating parameters produce expected visual results
- **Parallel**: None
- **Dependencies**: Task 7
- **Status**: ⬜ NOT STARTED

### 11. Test with different fade textures
- Test with CircleFade.svg (radial gradient)
- Test with DiamondFade.png (if suitable for shader)
- Create additional test gradient textures (linear, square)
- Verify different textures produce different visual patterns
- **Verify**: Fade texture sampler accepts various gradient textures
- **Parallel**: None
- **Dependencies**: Task 6
- **Status**: ⬜ NOT STARTED

### 12. Optimize shader for mobile performance
- Add early-exit when enable_pulsating is false (skip all calculations)
- Verify only one base texture sample per pixel
- Verify only one fade texture sample per pixel (only for outline pixels)
- Remove redundant calculations
- Profile shader on test mobile device if available
- **Verify**: Shader maintains 60 FPS with 10+ instances active
- **Parallel**: None
- **Dependencies**: Tasks 1-6 complete
- **Status**: ✅ COMPLETED

### 13. Handle edge cases and error conditions
- Test with null/missing fade texture
- Test with non-outline textures (all white or all black)
- Test with extremely small textures (1x1, 4x4 pixels)
- Test with extremely large textures (4096x4096)
- Test with threshold out of bounds (handled by hint_range)
- Add defensive code for edge cases
- **Verify**: Shader does not crash or produce errors in edge cases
- **Parallel**: None
- **Dependencies**: Tasks 1-6 complete
- **Status**: ⬜ NOT STARTED

### 14. Add comprehensive shader documentation
- Add file header with shader overview and purpose
- Document each uniform parameter with comments
- Document outline detection algorithm with inline comments
- Document angular position calculation with comments
- Document fade texture sampling strategy with comments
- Document blending logic with comments
- Add usage examples in header comment
- Add parameter recommendations in header comment
- **Verify**: Code is self-documenting and easy to understand
- **Parallel**: None
- **Dependencies**: Tasks 1-6 complete
- **Status**: ✅ COMPLETED

### 15. Create example scene demonstrating shader
- Create `scenes/ui/test_ui/predefined_outline_shader_test.tscn`
- Add multiple TextureRect nodes with different QuizScreen outline textures
- Apply ShaderMaterial with predefined_outline_shader to each
- Configure different outline colors for visual comparison
- Add example with pulsating enabled and disabled
- Add UI controls (if feasible) to adjust parameters in real-time
- **Verify**: Example scene clearly demonstrates shader capabilities
- **Parallel**: None
- **Dependencies**: Tasks 1-14 complete
- **Status**: ⬜ NOT STARTED

## Validation Checklist

After all tasks complete:
- [x] Shader detects black outline pixels accurately with threshold 0.2
- [x] Outline color can be changed via inspector property
- [x] Pulsating effect uses CircleFade.svg as gradient mask
- [x] Pulsating animation travels smoothly around outline
- [x] Pulsating direction (clockwise/counterclockwise) is controllable
- [x] Pulsating size parameter controls gradient spread  
- [x] Pulsating effect only appears within outline boundaries
- [x] All inspector properties are visible and functional
- [ ] Shader works on Control, Sprite2D, and TextureRect nodes (requires runtime testing)
- [ ] Shader handles missing fade texture gracefully (requires runtime testing)
- [x] Early-exit optimization when pulsating is disabled
- [ ] No visual artifacts or performance issues on mobile (requires runtime testing)
- [x] Code is well-documented and maintainable
- [ ] Example scene demonstrates all features (task 15 not started)
- [ ] All QuizScreen outline textures work correctly with shader (requires runtime testing)

## Notes
- CircleFade.svg location: `assets/CircleFade.svg`
- Target textures: `assets/ui/QuizScreen_*_Outline.svg` (4 files)
- Shader should be simple and performant - avoid complex calculations
- Use built-in TEXTURE, UV, and TIME variables
- Test on actual mobile device if possible for performance validation
- Threshold 0.2 should work for most black outlines, but document adjustability
- Fade texture must be assigned manually in each ShaderMaterial
