# Change: Rework predefined outline shader pulsating effect into a rotating radial line

## Why
The current pulsating effect on `predefined_outline_shader.gdshader` samples a radial gradient texture (`CircleFade.svg`) around the outline perimeter. The desired visual is different: a single line segment that starts at the texture's center, points to the top, spans the texture's width, rotates continuously around the center, and only renders on top of already-detected outline pixels. The texture-based gradient approach cannot express a rotating line with independently configurable thickness and edge softness, so the pulsating implementation needs to be replaced.

## What Changes
- Replace the texture-sampled radial gradient pulsating effect with a procedural rotating radial line effect.
- The line originates at the texture center, initially points toward the top, has a length equal to the texture's width, and rotates around the center over time.
- The line is masked so it is only visible on pixels already classified as outline pixels (base texture pixels are never affected).
- **BREAKING**: Remove the `fade_texture` (sampler2D) and `pulsating_size` uniforms; they are no longer used by the new line-based effect.
- Add new uniforms: `pulsating_thickness` (line width in pixels) and `pulsating_blur` (0-1 edge softness factor, applied uniformly along the whole line length, not tapering with radial distance).
- Reuse existing `enable_pulsating`, `pulsating_color`, `pulsating_speed`, and `pulsating_clockwise` uniforms for the new effect (no rename), so existing scenes that already toggle/color the effect keep working without script changes.
- Update scenes referencing the removed uniforms (`fade_texture`, `pulsating_size`) to drop those shader parameter overrides and set sensible defaults for the new `pulsating_thickness` / `pulsating_blur` uniforms.

## Impact
- Affected specs: `predefined-outline-shader`
- Affected code:
  - `shaders/predefined_outline_shader.gdshader`
  - `scenes/ui/components/answer_button.tscn` (currently assigns `fade_texture` and `pulsating_size`)
  - `scenes/ui/account_ui/account_registration_screen.tscn`
  - `scenes/ui/account_ui/register_login_screen.tscn`
  - `scenes/ui/components/answer_review_screen.tscn`
  - `scenes/ui/components/result_component.tscn`
  - `scenes/ui/gameplay_screen.tscn`
  - `scenes/ui/quiz_screen.tscn`
  - `scenes/ui/setup_screen.tscn`
  - `scenes/ui/test_ui/outline_shader_test.tscn`
- No GDScript API changes are required: `answer_button.gd`'s `set_pulsating_enabled()` / `set_pulsating_color()` continue to target the same uniform names.
