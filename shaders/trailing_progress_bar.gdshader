/*
 * Trailing Progress Bar Shader
 * ============================
 *
 * Adds a soft trailing fade treatment to an existing ProgressBar fill.
 * The base fill is preserved as the primary rendering and this shader only
 * modulates a narrow trailing region when progress decreases.
 *
 * Usage:
 * 1. Assign this shader through a ShaderMaterial on a ProgressBar node.
 * 2. Update `progress` from your bar's normalized value (value / max_value).
 * 3. Set `previous_progress` and `last_change_time` when value changes.
 *
 * Pseudo-code:
 *   if previous_progress > progress:
 *     trail_width = previous_progress - progress
 *     fade = smoothstep(...) * time_decay
 *     COLOR = mix(base_fill, faded_fill, fade)
 *
 * Performance:
 * - Single texture sample
 * - Constant time math only (no loops)
 * - Suitable for mobile UI rendering
 */

shader_type canvas_item;

// Normalized current progress in 0..1 space.
uniform float progress : hint_range(0.0, 1.0) = 1.0;
// Normalized previous progress in 0..1 space.
uniform float previous_progress : hint_range(0.0, 1.0) = 1.0;
// Strength of the trailing fade treatment.
uniform float fade_strength : hint_range(0.0, 1.0) = 0.5;
// Smoothness of the fade transition at the trail boundaries.
uniform float fade_softness : hint_range(0.1, 1.0) = 0.5;
// Softness of the edge falloff.
uniform float softness : hint_range(0.1, 1.0) = 0.5;
// Optional glow amount applied near the trail edge.
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.3;
// Seconds before trail fully fades out.
uniform float trail_fade_duration : hint_range(0.2, 2.0) = 0.5;
// Timestamp captured when progress changed; use TIME in script when updating.
uniform float last_change_time = 0.0;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV) * COLOR;

	// No trailing treatment while filling up or when values are equal.
	if (previous_progress <= progress) {
		COLOR = base_color;
	} else {
		float trail_start = progress;
		float trail_end = previous_progress;

		// Build a soft mask for the receding range [progress, previous_progress].
		float left = smoothstep(trail_start - fade_softness, trail_start + fade_softness, UV.x);
		float right = 1.0 - smoothstep(trail_end - fade_softness, trail_end + fade_softness, UV.x);
		float trail_mask = clamp(left * right, 0.0, 1.0);

		float edge_distance = min(abs(UV.x - trail_start), abs(UV.x - trail_end));
		float edge_falloff = 1.0 - smoothstep(0.0, softness, edge_distance);

		float elapsed = max(TIME - last_change_time, 0.0);
		float time_decay = 1.0 - clamp(elapsed / max(trail_fade_duration, 0.0001), 0.0, 1.0);

		float fade_amount = trail_mask * edge_falloff * time_decay * fade_strength;
		vec3 glow = vec3(glow_intensity * trail_mask * time_decay);

		vec3 faded_rgb = mix(base_color.rgb, base_color.rgb * 0.65 + glow, fade_amount);
		float faded_alpha = max(base_color.a, base_color.a * fade_amount);

		COLOR = vec4(faded_rgb, faded_alpha);
	}
}
