## Context
`predefined_outline_shader.gdshader` currently implements pulsating by sampling a radial gradient texture (`fade_texture`) at UV `(animated_angle, distance_from_center * pulsating_size)` and using its alpha to blend `outline_color` with `pulsating_color`. This must be replaced with a procedural rotating line confined to outline pixels, with configurable thickness, blur, speed, rotation direction, and color.

## Goals / Non-Goals
- Goals:
  - Render a single radial line from the texture center to the top edge, length equal to the texture's width, rotating continuously around the center.
  - Keep the line strictly masked to already-detected outline pixels.
  - Expose `pulsating_thickness` and `pulsating_blur` as new uniforms; keep `enable_pulsating`, `pulsating_color`, `pulsating_speed`, `pulsating_clockwise` uniform names unchanged.
  - Preserve the early-exit optimization when `enable_pulsating` is false.
- Non-Goals:
  - No change to outline detection/threshold logic or base outline color replacement.
  - No new GDScript API; `answer_button.gd` keeps using the same uniform names.
  - Not building a generic multi-line/multi-spoke system — exactly one rotating line.

## Decisions

### Geometry: aspect-corrected pixel space
Compute the pixel's position relative to the texture center in true pixel units (not raw UV) using `TEXTURE_PIXEL_SIZE`, so the line reads as a straight line of constant thickness regardless of the texture's aspect ratio:
```
vec2 center_px = vec2(0.5, 0.5) / TEXTURE_PIXEL_SIZE; // (width/2, height/2)
vec2 pixel_px  = UV / TEXTURE_PIXEL_SIZE;
vec2 d_px      = pixel_px - center_px; // signed offset in pixels
float r_px     = length(d_px);
```
- Decision: use pixel space (via `TEXTURE_PIXEL_SIZE`) instead of raw UV so `pulsating_thickness` is specified in approximate pixels and looks consistent on non-square textures.
- Alternative considered: keep raw UV distances (as the old shader did) — rejected because thickness would visibly distort on non-square button textures.

### Angle reference: zero at top, increasing clockwise
```
float angle_to_top = atan(d_px.x, -d_px.y); // 0 = straight up, +pi/2 = right, +/-pi = down
```
This makes `angle_to_top == 0` correspond to "pointing at the top", matching the requirement that the line initially points to the top and rotates clockwise as the angle increases.

### Rotation
```
float direction = pulsating_clockwise ? 1.0 : -1.0;
float line_angle = TIME * pulsating_speed * direction; // radians, unwrapped is fine (trig functions wrap)
```
Reuses the existing `pulsating_speed` and `pulsating_clockwise` uniforms so the "rotation direction" and "speed" configuration knobs the user asked for map onto already-existing, familiar uniforms rather than new ones.

### Line mask (thickness + blur, constant along the whole length)
```
float angle_diff = angle_to_top - line_angle;
float perp_px = r_px * sin(angle_diff);   // perpendicular distance to the infinite line through the center
float fwd_px  = r_px * cos(angle_diff);   // signed distance along the line's direction

float line_length_px = 1.0 / TEXTURE_PIXEL_SIZE.x; // texture width in pixels
float half_thickness = max(pulsating_thickness, 0.0001) * 0.5;
float feather = max(pulsating_blur, 0.0001) * half_thickness;

float width_mask  = 1.0 - smoothstep(half_thickness, half_thickness + feather, abs(perp_px));
float length_mask = step(0.0, fwd_px) * (1.0 - smoothstep(line_length_px, line_length_px + feather, fwd_px));
float line_mask = width_mask * length_mask;
```
- `perp_px` gives the true perpendicular distance from a point to the line through the center at `line_angle`, so `pulsating_thickness`/`pulsating_blur` produce a uniform-width band along the entire line length — the softness does not taper or intensify based on how far the pixel is from the center (matches the "regardless of distance" requirement).
- `fwd_px` restricts the effect to the forward half (from center outward to the top edge only, not the mirrored direction through the center), and clamps the length to the texture's width in pixels.
- Alternative considered: pure angular-difference threshold (no pixel-space conversion) — rejected because it produces a wedge that narrows to a point at the center instead of a constant-width line.

### Blending
```
if (enable_pulsating) {
    final_color.rgb = mix(final_color.rgb, pulsating_color.rgb, line_mask);
}
```
Only executed for pixels already classified as outline (existing `is_outline` branch), so base texture pixels are never affected, matching the outline-mask requirement.

### New uniforms
```
uniform float pulsating_thickness : hint_range(0.5, 64.0) = 6.0; // pixels
uniform float pulsating_blur : hint_range(0.0, 1.0) = 0.25;      // 0 = hard edge, 1 = fully soft
```

### Removed uniforms
`fade_texture` (sampler2D) and `pulsating_size` (float) are removed; they have no equivalent in the new design. Scenes with `shader_parameter/fade_texture` or `shader_parameter/pulsating_size` overrides will have those overrides become dead data in the `.tscn` (Godot ignores unknown shader parameters) — they should be cleaned up as part of this change for clarity, and `pulsating_thickness`/`pulsating_blur` overrides added where the effect is actually enabled (currently only `answer_button.tscn` and `outline_shader_test.tscn` enable pulsating).

## Risks / Trade-offs
- `answer_button.tscn` currently assigns `CircleFade.svg` to `fade_texture`; after this change that `ext_resource` reference becomes unused for this material and should be removed from the scene to avoid confusion (the texture itself may still be used elsewhere and should not be deleted from `assets/`).
- Visual difference: the previous effect could show a soft blob anywhere around the perimeter; the new effect is a single rotating spoke. This is the explicitly requested behavior change.

## Migration Plan
1. Update `shaders/predefined_outline_shader.gdshader` per the decisions above.
2. Update the affected `.tscn` files: remove `shader_parameter/fade_texture` and `shader_parameter/pulsating_size` lines; add `shader_parameter/pulsating_thickness` and `shader_parameter/pulsating_blur` only where `enable_pulsating = true` (others can rely on shader defaults since the effect is disabled).
3. Manually verify in the Godot editor that `answer_button.tscn`'s pulsating effect (used for correct/wrong answer highlighting) still animates correctly with the new line effect.

## Open Questions
None — clarified during proposal drafting (toggle stays, old uniforms removed, thickness in pixels, blur as a uniform feather factor applied regardless of radial position).
