# Proposal: Add Trailing Progress Bar Shader

**Change ID**: `add-trailing-progress-bar-shader`  
**Status**: Proposal  
**Date**: April 1, 2026

## Summary
Introduce a custom Godot 4 canvas_item shader for the TimeLimitBar that adds a smooth trailing fade to the existing fill. The fill itself is not duplicated or replaced; only a fade treatment is applied when the bar value decreases, enhancing visual feedback without affecting gameplay logic.

## Scope
- **What's included**: Custom shader asset, ShaderMaterial configuration, fade uniforms documentation
- **What's excluded**: Changes to quiz_screen.gd or gameplay logic, ProgressBar script modifications
- **Dependencies**: Godot 4.5+ canvas rendering

## Goals
1. Add visual polish to TimeLimitBar by providing a soft trailing fade on the existing fill
2. Improve player feedback when health/time decreases
3. Create a reusable shader pattern for other bars (health bars, mana bars, etc.)
4. Maintain animation smoothness on mobile devices
5. Support bar resizing/scaling without visual artifacts

## Problem Statement
Currently, the TimeLimitBar uses flat StyleBoxFlat styling. When the fill decreases (e.g., timer counting down), it immediately disappears with no visual transition. A trailing effect would:
- Provide clearer visual feedback of rapid changes
- Add polish to the quiz experience
- Improve readability on fast-moving bars

Constraint for this change:
- Do not draw an additional fill layer; preserve the regular fill rendering and only add a fade effect to it.

## Proposed Solution

### Architecture Overview
1. **New Shader Asset**: `shaders/trailing_progress_bar.gdshader`
   - Canvas item shader compatible with ProgressBar nodes
   - Automatically tracks value changes by comparing frame-to-frame
   - Applies a trailing fade on the existing fill near the receding edge
   - Supports proportional scaling

2. **Shader Parameters** (uniforms)
   - `fade_strength`: Intensity of the trailing fade treatment (0.0-1.0, default 0.5)
   - `fade_softness`: Controls fade falloff smoothness (0.1-1.0, default 0.5)
   - `softness`: Controls gradient falloff (0.1-1.0, default 0.5)
   - `glow_intensity`: Controls blur/bloom effect (0.0-1.0, default 0.3)
   - `trail_fade_duration`: Seconds before trail disappears (0.2-2.0, default 0.5)

3. **Application**
   - Applied as ShaderMaterial to TimeLimitBar in quiz_screen.tscn
   - No GDScript changes required (shader is stateless)
   - Trail automatically animates based on normalized ProgressBar value

### Technical Details

#### How It Works
- Shader samples the ProgressBar texture (the regular fill region)
- Compares current normalized value (`progress` based on `value/max_value`)
- Maintains implicit previous value state via TIME uniform
- Renders:
   - **Regular fill**: Original fill remains the base rendering
   - **Trailing fade**: Alpha/intensity fade applied to receding edge region only
   - **Bloom**: Optional soft glow blended with the fade region

#### Rendering Order
1. Background (from original ProgressBar)
2. Regular fill (original)
3. Trailing fade treatment (if previous > current)
4. Optional glow/bloom (softly blended)

#### Behavior Rules
- **Fill increases**: No trailing fade treatment
- **Fill decreases**: Fade treatment appears at the receding edge of the regular fill
- **No movement**: Fade treatment decays over `trail_fade_duration` seconds
- **Scale-agnostic**: Uses normalized UV coordinates (0-1), scales with bar size automatically

### Uniforms Specification

| Uniform | Type | Default | Range | Purpose |
|---------|------|---------|-------|---------|
| `fade_strength` | `float` | 0.5 | 0.0-1.0 | Intensity of trailing fade effect |
| `fade_softness` | `float` | 0.5 | 0.1-1.0 | Fade edge smoothness |
| `softness` | `float` | 0.5 | 0.1-1.0 | Gradient falloff smoothness |
| `glow_intensity` | `float` | 0.3 | 0.0-1.0 | Bloom/blur effect strength |
| `trail_fade_duration` | `float` | 0.5 | 0.2-2.0 | Seconds before trail disappears |

## Compatibility
- **Godot Version**: 4.5+
- **Platforms**: Mobile (Android/iOS) ✓, Desktop ✓
- **Performance**: Minimal (single texture sample, basic math, no loops)
- **Accessibility**: No impact (purely visual enhancement)
- **Existing Code**: No breaking changes (non-invasive addition)

## Risk Assessment

### Low Risk
- Isolated shader (no impact on gameplay logic)
- No script modifications
- Optional visual enhancement
- Easy to disable by removing ShaderMaterial

### Mitigation
- Test on target mobile devices (Android/iOS)
- Profile performance with multiple bars
- Provide fallback (disable shader if FPS < 30)

## Approval Checklist
- [ ] Requirements reviewed and understood
- [ ] Design approach approved
- [ ] Performance implications accepted
- [ ] Mobile testing planned
- [ ] Tasks prioritized and sequenced

---

## Next Steps
1. Review this proposal and clarify any gaps
2. Approve design approach from `design.md`
3. Validate tasks in `tasks.md`
4. Proceed to implementation phase

**Proposal Version**: 1.0  
**Last Updated**: April 1, 2026
