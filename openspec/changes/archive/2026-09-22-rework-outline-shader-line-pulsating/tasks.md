## 1. Shader implementation
- [x] 1.1 In `shaders/predefined_outline_shader.gdshader`, remove `fade_texture` and `pulsating_size` uniforms.
- [x] 1.2 Add `pulsating_thickness` (hint_range 0.5-64.0, default 6.0) and `pulsating_blur` (hint_range 0.0-1.0, default 0.25) uniforms.
- [x] 1.3 Replace the angular-position/fade-texture sampling code with the pixel-space rotating line calculation (center offset via `TEXTURE_PIXEL_SIZE`, angle-to-top, perpendicular/forward distance, width/length masks) as described in `design.md`.
- [x] 1.4 Blend `pulsating_color` into the outline pixel using the new line mask, keeping the effect scoped to `is_outline` pixels only and behind the existing `enable_pulsating` early-exit.
- [x] 1.5 Update the shader's header doc comment block to describe the new line-based pulsating behavior and uniforms instead of the texture-based gradient.

## 2. Scene updates
- [x] 2.1 Remove `shader_parameter/fade_texture` and `shader_parameter/pulsating_size` overrides from `answer_button.tscn`, `account_registration_screen.tscn`, `register_login_screen.tscn`, `answer_review_screen.tscn`, `result_component.tscn`, `gameplay_screen.tscn`, `quiz_screen.tscn`, and `setup_screen.tscn`. (`outline_shader_test.tscn` uses the unrelated `outline_shader.gdshader` and already has its own `pulsating_thickness` uniform — no change needed there.)
- [x] 2.2 Remove the now-unused `CircleFade.svg` `ext_resource` entry from `answer_button.tscn` (nothing else in the scene referenced it).
- [x] 2.3 Add `shader_parameter/pulsating_thickness` and `shader_parameter/pulsating_blur` overrides to `answer_button.tscn` (the only scene using `predefined_outline_shader` with pulsating enabled); default-valued overrides also added to the disabled instances for consistency.

## 3. Validation
- [x] 3.1 Open the quiz/answer flow (`answer_button.tscn` in `quiz_screen.tscn`) in the Godot editor and visually confirm the line starts pointing up, rotates in the configured direction, respects thickness/blur, and stays confined to the outline.
- [x] 3.2 Confirm the correct/wrong pulsating highlight in `answer_button.tscn` still animates correctly with the new effect.
- [x] 3.3 Run `openspec validate rework-outline-shader-line-pulsating --strict` and resolve any issues.
