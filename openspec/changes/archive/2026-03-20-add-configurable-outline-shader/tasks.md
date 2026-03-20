# Tasks: Add Configurable Outline Shader

**Change ID**: `add-configurable-outline-shader`

## Implementation Order

### 1. Implement basic outline detection algorithm
- Add texture sampling logic in fragment shader
- Implement alpha channel threshold detection (0.1)
- Create 8-directional sampling pattern for edge detection
- Sample both outward and slightly inward for clean edges
- **Verify**: Apply shader to test TextureRect, confirm outline appears around non-transparent pixels
- **Parallel**: None
- **Dependencies**: None
- **Status**: ✅ COMPLETED

### 2. Add outline inspector properties (thickness, color)
- Add `uniform float outline_thickness = 2.0` with hint range
- Add `uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0)`
- Wire uniforms into outline rendering logic
- **Verify**: Adjust properties in inspector, confirm immediate visual updates
- **Parallel**: None
- **Dependencies**: Task 1
- **Status**: ✅ COMPLETED

### 3. Implement pulsating animation logic
- Add time-based animation calculation using `TIME` built-in
- Calculate angular position around outline perimeter
- Implement counterclockwise movement pattern
- Blend pulsating color with base outline color
- **Verify**: Enable pulsating, confirm secondary color animates smoothly around outline
- **Parallel**: None
- **Dependencies**: Task 2
- **Status**: ✅ COMPLETED

### 4. Add pulsating inspector properties
- Add `uniform bool enable_pulsating = false`
- Add `uniform vec4 pulsating_color : source_color = vec4(0.0, 1.0, 1.0, 1.0)` (cyan)
- Add `uniform float pulsating_thickness = 1.0` with hint range
- Add `uniform float pulsating_speed = 1.0` with hint range
- Add `uniform bool pulsating_clockwise = false`
- Wire all properties into pulsating animation logic
- **Verify**: Test each property independently, confirm expected behavior
- **Parallel**: None
- **Dependencies**: Task 3
- **Status**: ✅ COMPLETED

### 5. Test shader on various CanvasItem types
- Create test scene with Button, Panel, Sprite2D, TextureRect, and ColorRect
- Apply ShaderMaterial with outline_shader to each node type
- Test with various texture shapes (rectangular, circular, complex shapes)
- Test with different texture alpha configurations
- **Verify**: All node types render correctly with all effects enabled
- **Parallel**: None
- **Dependencies**: Tasks 1-6 complete
- **Status**: ✅ COMPLETED (test scene created: scenes/ui/test_ui/outline_shader_test.tscn)

### 6. Optimize shader for mobile performance
- Review fragment shader for redundant calculations
- Minimize texture sampling operations where possible
- Use efficient conditional logic to skip disabled effects
- Profile on test device if available
- **Verify**: Shader maintains 60 FPS with multiple instances active
- **Parallel**: None
- **Dependencies**: Tasks 1-4 complete
- **Status**: ✅ COMPLETED (early exits, conditional pulsating check)

### 7. Add inline documentation to shader code
- Document each uniform parameter with comments
- Explain outline detection algorithm
- Document pulsating animation calculations
- Add usage example as header comment
- **Verify**: Code is self-documenting and easy to understand
- **Parallel**: None
- **Dependencies**: Tasks 1-6 complete
- **Status**: ✅ COMPLETED

## Validation Checklist

After all tasks complete:
- [x] All inspector properties are visible and functional
- [x] Outline follows texture alpha boundaries precisely
- [x] Pulsating animation is smooth and configurable
- [x] Effects can be independently toggled
- [x] Shader works on Control, Sprite2D, and TextureRect nodes
- [x] No visual artifacts or performance issues
- [x] Code is well-documented and maintainable

## Notes
- Keep shader simple - avoid nested loops and excessive branching
- Use built-in TEXTURE and UV for texture sampling
- Use TIME built-in for pulsating animation
- Test thoroughly on different texture types and sizes
