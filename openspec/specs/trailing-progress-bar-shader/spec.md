# Spec Delta: trailing_progress_bar Shader

**Capability**: Progress Bar Trailing Shader  
**Scope**: Canvas Item Shader for Visual Effects  
**Status**: Implemented

---

## ADDED Requirements

### Requirement: Progress bars SHALL support smooth trailing effect on value decrease
The progress bar shader SHALL render a smooth gradient trail behind the current fill when the normalized progress value decreases, creating a "damage" or "drain" visual effect.

#### Scenario: Trail appears on value decrease
**Given** a ProgressBar with trailing_progress_bar shader applied  
**When** the bar's `value` property decreases from 80 to 60  
**Then** a soft gradient trail appears between the 80% and 60% fill positions  
**And** the trail fades smoothly over `trail_fade_duration` seconds  
**And** no trail is rendered if value increases

#### Scenario: Trail respects bar boundaries
**Given** a progress bar with trail effect active  
**When** rendering the trail gradient  
**Then** the trail is fully contained within the ProgressBar background bounds  
**And** no trail pixels extend beyond the background edge

#### Scenario: Trail renders with soft bloom
**Given** a progress bar with `glow_intensity > 0`  
**When** the trail is rendered  
**Then** a soft blur/bloom effect appears at trail edges  
**And** the bloom intensity is controlled by the `glow_intensity` uniform

---

### Requirement: Shader SHALL use normalized progress coordinates
The shader SHALL calculate progress using normalized UV coordinates (0.0 to 1.0) independent of the ProgressBar's `max_value` or pixel dimensions.

#### Scenario: Normalized progress calculation
**Given** a ProgressBar with max_value=100 and current value=75  
**When** the shader calculates normalized_progress  
**Then** normalized_progress = 75 / 100 = 0.75  
**And** the trail position is determined by this normalized value  
**And** shifting max_value does not affect trail position

#### Scenario: UV coordinates scale with bar size
**Given** a ProgressBar with normalized progress 0.5  
**When** the bar size is doubled  
**Then** the fill position remains at 0.5 (midway)  
**And** the trail scales proportionally with the bar  
**And** no visual artifacts occur due to resizing

---

### Requirement: Shader SHALL support configurable trail coloring
The shader SHALL provide independent `trail_color` and `fill_color` uniforms to control the visual appearance of the trail and current fill.

#### Scenario: Trail color customization
**Given** a ProgressBar with shader applied  
**When** the `trail_color` uniform is set to `vec4(0.5, 0.8, 1.0, 1.0)` (light blue)  
**Then** the trail gradient renders in the specified light blue color  
**And** the current fill color is independent (unaffected by trail_color)

#### Scenario: Fill color customization
**Given** a ProgressBar with shader applied  
**When** the `fill_color` uniform is set to `vec4(1.0, 0.0, 0.0, 1.0)` (red)  
**Then** the current fill renders in red  
**And** the trail remains in its configured color (independent)

---

### Requirement: Shader SHALL support gradient softness configuration
The shader SHALL provide a `softness` uniform that controls the gradient falloff between trail and filled regions, creating a smooth transition regardless of bar scale.

#### Scenario: Sharp gradient (softness=0.1)
**Given** a progress bar with `softness = 0.1`  
**When** the trail is rendered  
**Then** the gradient transition is sharp/accentuated  
**And** the edge between trail and current fill is visibly defined

#### Scenario: Soft gradient (softness=0.8)
**Given** a progress bar with `softness = 0.8`  
**When** the trail is rendered  
**Then** the gradient transition is smooth/blurred  
**And** the edge between trail and current fill is subtle  
**And** no harsh boundaries appear

#### Scenario: Softness scales with bar
**Given** a progress bar with softness=0.5, resized to 2x size  
**When** the trail is rendered  
**Then** the softness appearance remains visually consistent  
**And** the gradient does not appear "pixelated" or "over-softened" at any scale

---

### Requirement: Shader SHALL implement time-based fade decay
The shader SHALL automatically fade the trail to transparent over a configurable duration when the progress value stabilizes (no longer decreasing).

#### Scenario: Trail fades on stasis
**Given** a ProgressBar at value 50, initially at value 100  
**When** the value remains at 50 for `trail_fade_duration` seconds  
**Then** the trail alpha decreases linearly from 1.0 to 0.0  
**And** the trail is completely invisible after `trail_fade_duration` seconds

#### Scenario: Trail refresh on new decrease
**Given** a progress bar with a fading trail  
**When** the value decreases again before fade is complete  
**Then** the trail "resets" to full opacity  
**And** a new trail is rendered from the updated previous position

#### Scenario: Custom fade duration
**Given** a ProgressBar with `trail_fade_duration = 1.5`  
**When** the progress value decreases  
**And** the value stabilizes  
**Then** the trail takes approximately 1.5 seconds to fully fade  
(tolerance: ±0.1 seconds)

---

### Requirement: Shader SHALL provide glow/bloom visual effect
The shader SHALL apply a soft glow/bloom effect to the trail edges, with intensity controllable via the `glow_intensity` uniform.

#### Scenario: No glow (glow_intensity=0.0)
**Given** a progress bar with `glow_intensity = 0.0`  
**When** the trail is rendered  
**Then** no bloom/glow effect is applied  
**And** the trail has clean, crisp edges

#### Scenario: Moderate glow (glow_intensity=0.5)
**Given** a progress bar with `glow_intensity = 0.5`  
**When** the trail is rendered  
**Then** a noticeable soft glow appears at trail edges  
**And** the glow blends naturally with the background

#### Scenario: Maximum glow (glow_intensity=1.0)
**Given** a progress bar with `glow_intensity = 1.0`  
**When** the trail is rendered  
**Then** a bright bloom effect is prominently visible  
**And** the glow extends noticeably beyond the trail edges

---

### Requirement: Shader SHALL apply to ProgressBar CanvasItem nodes
The shader SHALL be compatible with Godot ProgressBar nodes via ShaderMaterial assignment, without requiring script modifications or wrapper components.

#### Scenario: Apply via Inspector
**Given** a ProgressBar node in a scene  
**When** the Inspector's `material_override` property is set to ShaderMaterial using this shader  
**Then** the trailing effect is immediately active  
**And** no GDScript changes are required

#### Scenario: Shader material persistence
**Given** a ProgressBar with ShaderMaterial assigned  
**When** the scene is saved and reloaded  
**Then** the ShaderMaterial is preserved  
**And** all uniform values persist

---

### Requirement: Shader performance SHALL be mobile-optimized
The shader implementation SHALL have minimal computational overhead, suitable for target mobile platforms (Android/iOS) at 60 FPS.

#### Scenario: Fragment shader efficiency
**Given** the trailing_progress_bar shader  
**When** profiled on target mobile hardware  
**Then** the shader contributes < 2% to overall frame time  
**And** no frame skips are induced by shader computation

#### Scenario: Scalable performance
**Given** a scene with multiple progress bars (health, mana, cooldown) with trailing shader  
**When** all bars are active and animating simultaneously  
**Then** FPS remains >= 55 on mid-range Android/iOS devices  
**And** battery consumption increase is negligible

---

### Requirement: Shader SHALL be agnostic to ProgressBar direction
The shader SHALL support both left-to-right and right-to-left fill directions without configuration changes.

#### Scenario: Left-to-right fill direction
**Given** a ProgressBar with fill direction left→right  
**When** the value decreases  
**Then** the trail appears to the left of the current fill  
**And** the movement direction is correctly detected

#### Scenario: Right-to-left fill direction
**Given** a ProgressBar with fill direction right→left  
**When** the value decreases  
**Then** the trail appears to the right of the current fill  
**And** the movement direction is correctly detected

---

## MODIFIED Requirements

None at this time. All existing ProgressBar behavior (value setting, max_value, fill rendering) remains unchanged.

---

## REMOVED Requirements

None at this time. No existing shader or ProgressBar capabilities are removed.

---

## Uniform Parameters Specification

| Parameter | Type | Default | Valid Range | Purpose |
|-----------|------|---------|-------------|---------|
| `trail_color` | `source_color` | `vec4(0.306, 1.0, 0, 1)` | Any RGBA | Color of trail gradient |
| `fill_color` | `source_color` | `vec4(0.306, 1.0, 0, 1)` | Any RGBA | Color of current fill |
| `softness` | `float` | `0.5` | `0.1` to `1.0` | Gradient falloff smoothness |
| `glow_intensity` | `float` | `0.3` | `0.0` to `1.0` | Bloom effect intensity |
| `trail_fade_duration` | `float` | `0.5` | `0.2` to `2.0` | Fade-out time in seconds |

---

## Asset Location
- **Shader**: `res://shaders/trailing_progress_bar.gdshader`
- **Expected Scene**: Applied in `res://scenes/ui/quiz_screen.tscn` to `TimeLimitBar` node

---

## Compatibility Matrix

| Godot Version | Support | Notes |
|---------------|---------|-------|
| 4.1 | ❌ | TIME uniform may behave differently |
| 4.2 - 4.4 | ⚠️ | Supported but not tested |
| 4.5+ | ✓ | Fully supported and tested |
| 3.x | ❌ | Canvas item shader syntax incompatible |

---

## Testing Coverage

- [x] Shader compiles without errors
- [x] All uniforms editable and functional
- [x] Visual appearance matches design (trail, bloom, fade)
- [x] Scaling behavior correct at multiple resolutions
- [x] Performance overhead < 2% frame time
- [x] Fade duration accuracy (±0.1s tolerance)
- [x] Applies cleanly to ProgressBar nodes
- [x] Reusable across multiple bars

---

**Spec Version**: 1.0  
**Last Updated**: April 1, 2026  
**Related Capabilities**: ProgressBar component styling, visual effects system
