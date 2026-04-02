# Design Document: Trailing Progress Bar Shader

**Change ID**: `add-trailing-progress-bar-shader`  
**Author**: AI Assistant  
**Date**: April 1, 2026

## Design Overview

This document explains the architectural decisions, trade-offs, and technical implementation strategy for the Trailing Progress Bar Shader.

## Architecture Decisions

### 1. Stateless Shader (Preferred) vs. Script-Driven Tracking

**Decision**: Implement as stateless shader with implicit frame-to-frame comparison.

**Rationale**:
- **No GDScript changes required** - isolated to shader only
- **Composable** - can be applied to any ProgressBar without script modification
- **Maintains separation of concerns** - rendering logic stays in shader, game logic untouched
- **Mobile-friendly** - avoids additional CPU overhead from script callbacks

**Alternative considered**: Track previous value via GDScript callback
- Would require modifying quiz_screen.gd or creating a wrapper component
- Adds complexity and coupling between UI and shader logic
- More difficult to reuse on other bars

**Trade-off**: 
- Cannot access exact previous frame value (uses TIME-based estimation)
- Mitigated by soft fade (user perceives smooth decay, not 1-frame jumps)

### 2. Normalized UV Coordinates (0-1 Independent of Max Value)

**Decision**: Use normalized UV space (0-1) rather than absolute pixel positions.

**Rationale**:
- **Scale-agnostic** - works at any resolution/bar size
- **Value-agnostic** - works with any max_value setting
- **Responsive** - scales proportionally when bar is resized
- **Follows Godot conventions** - standard UV mapping pattern

**Implementation**:
```
normalized_progress = value / max_value  // Convert to 0-1 range
```

**Impact**: Shader doesn't need to know actual `max_value` or pixel dimensions.

### 3. Adaptive Movement Direction (Right-to-Left vs. Left-to-Right)

**Decision**: The fade treatment follows the direction of fill movement (adaptive).

**Rationale**:
- **Intuitive** - players see trail where movement originated
- **Flexible** - shader supports both bar directions without config
- **Future-proof** - supports horizontal/vertical bars without changes

**Implementation**:
```gdshader
// Detect if value decreased (left movement)
if (normalized_current < normalized_previous) {
    // Apply fade treatment on receding edge region (right to left)
}
```

### 4. Soft Bloom vs. Hard Edge

**Decision**: Implement soft blur/bloom at the fade edge using smoothstep() falloff.

**Rationale**:
- **Visual polish** - smooth gradients look more refined than hard edges
- **Performance** - smoothstep() is faster than blur filter
- **Mobile-friendly** - no multi-pass rendering required
- **Customizable** - `softness` uniform controls gradient shape

**Code approach**:
```gdshader
float fade_gradient = smoothstep(fade_end, fade_start, uv_position);
fade_alpha *= 1.0 - smoothstep(0.0, softness, distance_from_edge);
```

### 5. Time-Based Fade Decay

**Decision**: The receding-edge fade decays over `trail_fade_duration` seconds using TIME uniform.

**Rationale**:
- **Stateless** - no need to track previous frame's fade state
- **Smooth** - TIME provides continuous decay curve
- **Predictable** - linear fade is easy to tune and understand

**Implementation**:
```gdshader
float time_since_change = TIME - last_movement_time;
float fade_alpha = 1.0 - (time_since_change / trail_fade_duration);
```

**Note**: Pseudo-code; actual implementation tracks movement via value changes.

### 6. Color Inheritance from StyleBoxFlat

**Decision**: Provide override-able uniforms but default to inheriting existing colors.

**Rationale**:
- **Consistency** - fade treatment matches bar colors automatically
- **User control** - can tune fade behavior independently if desired
- **Less configuration** - reduces setup steps

**Implementation**:
- Document default values matching current StyleBoxFlat
- Provide inspector hints (color picker, sliders) for easy tweaking

### 7. ProgressBar Node Direct Application (vs. Custom Component)

**Decision**: Apply ShaderMaterial directly to ProgressBar node.

**Rationale**:
- **Simplicity** - no wrapper component needed
- **No breaking changes** - quiz_screen.tscn structure unchanged
- **Minimal setup** - single material assignment in inspector
- **Reusable** - can be copied to other bars as-is

**Alternative considered**: Create custom ProgressBar wrapper component
- Would allow more control but adds unnecessary complexity
- Quiz code doesn't need to know about trail logic

## Trade-offs & Compromises

| Issue | Trade-off | Justification |
|-------|-----------|---------------|
| **Exact previous value** | Use TIME-based estimation | Shader is stateless; TIME provides smooth curve |
| **Hardcoded fade duration** | Make it a uniform | Players can customize feel without shader recompile |
| **Performance vs. quality** | Single-sample fade modulation | Mobile devices can handle; smoothstep() is cheap |
| **Complex easing curves** | Linear fade | Simplicity; works well with time-decay pattern |
| **Per-axis scaling** | Use uniform scaling | Standard ProgressBar uniform scaling is sufficient |

## Performance Characteristics

### Computational Cost
- **Texture samples**: 1 (base ProgressBar texture)
- **Math operations**: ~10 (atan, smoothstep, distance calculations)
- **Conditionals**: 2 (value_decreasing, in_fade_region)
- **Complexity class**: O(1) per fragment

### Memory Impact
- **Shader asset**: ~2 KB (.gdshader file)
- **ShaderMaterial**: ~500 bytes per instance
- **No additional textures**: Uses ProgressBar's existing fill texture

### Mobile Performance
- **Target**: 60 FPS on mid-range Android/iOS devices
- **Expected**: <1ms fragment shader execution (negligible impact)
- **Fallback**: Can disable shader if FPS < 30

## Assumptions

1. **ProgressBar is used for linear fills** (not circular or diagonal)
2. **TimeLimitBar max_value remains constant** during gameplay
3. **Canvas layer remains opaque** (no complex layering)
4. **Godot 4.5+ feature set** is available (TIME uniform, smoothstep, etc.)
5. **GDScript will set ProgressBar.value**, not the shader

## Future Extensibility

### Potential Enhancements
1. **Circular progress bars** - add support for atan2-based radial fills
2. **Multi-trail effects** - render multiple decay stages
3. **Animation keyframes** - use AnimationPlayer to keyframe uniforms
4. **Particle integration** - emit particles at trail endpoints
5. **Audio sync** - pulse glow to sound frequencies

### How Design Supports Extensibility
- Modular uniform parameters (easy to add more)
- Shader structure allows additional features in fragment shader
- No hardcoded assumptions about bar geometry
- Canvas item shader pattern is standard (easy to fork/extend)

## Testing Strategy

### Unit-Level Testing
- [ ] Verify shader compiles without errors (all Godot versions)
- [ ] Confirm uniforms are editable in Inspector
- [ ] Test glow_intensity range (0.0-1.0)

### Integration Testing
- [ ] Apply to TimeLimitBar, verify visual correctness
- [ ] Modify StyleBoxFlat colors, verify shader inherits
- [ ] Resize window, confirm fade region scales proportionally
- [ ] Rapid value changes, verify fade remains smooth

### Performance Testing
- [ ] Profile frame time with shader enabled
- [ ] Compare frame time with/without shader
- [ ] Test on target mobile devices (Android, iOS)
- [ ] Verify battery impact (if applicable)

### Visual Testing
- [ ] Capture screenshots of fade effect on the regular fill
- [ ] Verify soft bloom appearance
- [ ] Test with different softness values
- [ ] Confirm fade treatment respects bar bounds
- [ ] Confirm no duplicate or separately drawn fill region appears

## Security & Accessibility

- **Security**: N/A (render-only shader, no user input processing)
- **Accessibility**: No functional impact; purely visual enhancement; can be disabled
- **Internationalization**: N/A (no text or locale-specific logic)

## Rollback Strategy

If issues arise:
1. **Quick disable**: Remove ShaderMaterial from TimeLimitBar in quiz_screen.tscn
2. **Full rollback**: Delete `shaders/trailing_progress_bar.gdshader` and revert tscn
3. **No data loss**: Changes are purely visual

## Success Criteria

✓ Shader compiles without errors  
✓ Fade appears visually smooth on the regular fill (no flickering)  
✓ Fade duration matches `trail_fade_duration` uniform  
✓ Fade region scales correctly when bar is resized  
✓ Performance impact < 2% on mobile devices  
✓ All uniforms are customizable via Inspector  
✓ Compatible with existing quiz_screen flow

---

**Document Version**: 1.0  
**Status**: Ready for review
