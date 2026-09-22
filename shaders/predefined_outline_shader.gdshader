/*
 * Predefined Outline Shader
 * ========================
 * 
 * A specialized shader for UI elements with pre-rendered outline borders.
 * Detects outline pixels based on color threshold, allows dynamic color
 * replacement, and provides a rotating line pulsating animation effect.
 * 
 * USAGE:
 * 1. Create a ShaderMaterial using this shader
 * 2. Assign it to a CanvasItem node (Control, Sprite2D, TextureRect, etc.)
 * 3. Use textures with predefined black borders (e.g., QuizScreen_Button_Top_Outline.svg)
 * 4. Customize outline color via the "Outline Color" property
 * 5. For animation, enable "Enable Pulsating" and tune thickness/blur/speed/color
 * 
 * OUTLINE DETECTION:
 * - Pixels are classified as outline if their grayscale value < outline_threshold
 * - Default threshold (0.2) detects pure black and near-black pixels
 * - Adjust threshold for textures with different outline darkness
 * 
 * PULSATING ANIMATION:
 * - Draws a single line through the texture's center, initially pointing to
 *   the top and bottom edges, with a total length equal to the texture's width
 * - The line rotates continuously around the center
 * - Effect is only applied to detected outline pixels; base texture is untouched
 * - Thickness and blur are computed in pixel space, so they stay constant
 *   along the whole length of the line regardless of texture aspect ratio
 * 
 * PARAMETERS:
 * - outline_color: Custom color for outline pixels (default: white)
 * - outline_threshold: Detection sensitivity, 0.0-1.0 (default: 0.2)
 * - enable_pulsating: Toggle animation on/off (default: false)
 * - pulsating_color: Line color (default: cyan)
 * - pulsating_thickness: Line width in approximate pixels (default: 6.0)
 * - pulsating_blur: Edge softness, 0.0-1.0 (default: 0.25)
 * - pulsating_speed: Rotation speed (default: 1.0)
 * - pulsating_clockwise: Rotation direction control (default: false, counterclockwise)
 * 
 * PERFORMANCE:
 * - Early-exit optimization when pulsating is disabled
 * - Rotating line is computed procedurally (no extra texture sampling)
 * - Mobile-friendly calculations using simple trigonometry
 */

shader_type canvas_item;

// Outline color replacement
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // White
uniform float outline_threshold : hint_range(0.0, 1.0) = 0.2;  // Black detection sensitivity

// Pulsating animation (rotating line)
uniform bool enable_pulsating = false;
uniform vec4 pulsating_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);  // Cyan
uniform float pulsating_thickness : hint_range(100.0, 1000.0) = 300.0;  // Line width in pixels
uniform float pulsating_blur : hint_range(0.0, 1.0) = 0.25;  // Edge softness factor
uniform float pulsating_speed : hint_range(0.1, 5.0) = 1.0;  // Rotation speed
uniform bool pulsating_clockwise = false;  // Direction control

void fragment() {
	// Sample the base texture
	vec4 base_color = texture(TEXTURE, UV);
	
	// Calculate grayscale value to detect outline pixels
	// Simple average method: (R + G + B) / 3
	// Black pixels (0,0,0) = 0.0, White pixels (1,1,1) = 1.0
	float grayscale = (base_color.r + base_color.g + base_color.b) / 3.0;
	
	// Determine if this pixel is part of the outline
	// Pixels darker than threshold are classified as outline
	bool is_outline = grayscale < outline_threshold;
	
	if (is_outline) {
		// Outline pixel - replace with user-defined outline color
		// Preserve original alpha channel for transparency support
		vec4 final_color = vec4(outline_color.rgb, base_color.a);
		
		// Apply pulsating effect if enabled
		if (enable_pulsating) {
			// --- Pixel-Space Position ---
			// Convert UV offset from center into approximate pixel units so the
			// line's thickness stays visually consistent on non-square textures
			vec2 offset_px = (UV - vec2(0.5)) / TEXTURE_PIXEL_SIZE;
			float radius_px = length(offset_px);
			
			// --- Angle Relative To Top, Increasing Clockwise ---
			float angle_to_top = atan(offset_px.x, -offset_px.y);
			
			// --- Time-Based Rotation ---
			float direction = pulsating_clockwise ? 1.0 : -1.0;
			float line_angle = TIME * pulsating_speed * direction;
			float angle_diff = angle_to_top - line_angle;
			
			// --- Perpendicular / Forward Distance To The Line ---
			// perp_px: true perpendicular distance to the infinite line through
			//   the center at line_angle (constant-width regardless of radius)
			// fwd_px: unsigned distance along the line's axis from the center,
			//   in either direction (the line extends both ways through center)
			float perp_px = radius_px * sin(angle_diff);
			float fwd_px = abs(radius_px * cos(angle_diff));
			
			// Line spans the full texture width, half on each side of the center
			float half_length_px = 0.5 / TEXTURE_PIXEL_SIZE.x;
			float half_thickness = max(pulsating_thickness, 0.0001) * 0.5;
			// Feather scales well past half_thickness so high blur values read as clearly softer
			float feather = max(pulsating_blur, 0.0001) * half_thickness * 4.0;
			
			float width_mask = 1.0 - smoothstep(half_thickness, half_thickness + feather, abs(perp_px));
			float length_mask = 1.0 - smoothstep(half_length_px, half_length_px + feather, fwd_px);
			float line_mask = width_mask * length_mask;
			
			// --- Color Blending ---
			// line_mask = 0.0: outline_color, line_mask = 1.0: pulsating_color
			final_color.rgb = mix(final_color.rgb, pulsating_color.rgb, line_mask);
		}
		
		// Outline pixels ignore self_modulate - use shader color directly
		COLOR = final_color;
	} else {
		// Non-outline pixels respect self_modulate and parent modulation
		COLOR = base_color * COLOR;
	}
}
