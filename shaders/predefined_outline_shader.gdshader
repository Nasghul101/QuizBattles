/*
 * Predefined Outline Shader
 * ========================
 * 
 * A specialized shader for UI elements with pre-rendered outline borders.
 * Detects outline pixels based on color threshold, allows dynamic color
 * replacement, and provides texture-based pulsating animation effects.
 * 
 * USAGE:
 * 1. Create a ShaderMaterial using this shader
 * 2. Assign it to a CanvasItem node (Control, Sprite2D, TextureRect, etc.)
 * 3. Use textures with predefined black borders (e.g., QuizScreen_Button_Top_Outline.svg)
 * 4. Customize outline color via the "Outline Color" property
 * 5. For animation, enable "Enable Pulsating" and assign CircleFade.svg to "Fade Texture"
 * 
 * OUTLINE DETECTION:
 * - Pixels are classified as outline if their grayscale value < outline_threshold
 * - Default threshold (0.2) detects pure black and near-black pixels
 * - Adjust threshold for textures with different outline darkness
 * 
 * PULSATING ANIMATION:
 * - Creates a gradient effect that travels around the outline perimeter
 * - Uses angular position mapping to sample a radial gradient texture
 * - Effect is only applied to detected outline pixels
 * - Smoothly blends between outline color and pulsating color
 * 
 * PARAMETERS:
 * - outline_color: Custom color for outline pixels (default: white)
 * - outline_threshold: Detection sensitivity, 0.0-1.0 (default: 0.2)
 * - enable_pulsating: Toggle animation on/off (default: false)
 * - fade_texture: Radial gradient for animation (recommended: CircleFade.svg)
 * - pulsating_color: Animation color (default: cyan)
 * - pulsating_size: Gradient coverage area, 0.1-2.0 (default: 1.0)
 * - pulsating_speed: Animation speed, 0.1-5.0 (default: 1.0)
 * - pulsating_clockwise: Direction control (default: false, counterclockwise)
 * 
 * PERFORMANCE:
 * - Early-exit optimization when pulsating is disabled
 * - Minimal texture sampling (one base texture, one fade texture per outline pixel)
 * - Mobile-friendly calculations using simple trigonometry
 */

shader_type canvas_item;

// Outline color replacement
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // White
uniform float outline_threshold : hint_range(0.0, 1.0) = 0.2;  // Black detection sensitivity

// Pulsating animation
uniform bool enable_pulsating = false;
uniform sampler2D fade_texture;  // CircleFade.svg or other radial gradient
uniform vec4 pulsating_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);  // Cyan
uniform float pulsating_size : hint_range(0.1, 2.0) = 1.0;  // Coverage area multiplier
uniform float pulsating_speed : hint_range(0.1, 5.0) = 1.0;  // Animation speed
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
			// --- Angular Position Calculation ---
			// Calculate pixel position relative to texture center (0.5, 0.5)
			vec2 center = vec2(0.5, 0.5);
			float dx = UV.x - center.x;
			float dy = UV.y - center.y;
			
			// Calculate angular position around center using atan
			// Returns angle in radians, range: -π to π
			float angle = atan(dy, dx);
			
			// Normalize angle to 0.0-1.0 range for texture mapping
			// Add π to shift range to 0 to 2π, then divide by 2π
			// Note: PI is a built-in constant in Godot's shading language
			float normalized_angle = (angle + PI) / (2.0 * PI);
			
			// --- Time-Based Animation ---
			// Apply time-based offset for animation
			// Direction: clockwise (1.0) or counterclockwise (-1.0)
			// Scale factor 0.1 controls base animation speed
			float direction = pulsating_clockwise ? 1.0 : -1.0;
			float animated_angle = normalized_angle + TIME * pulsating_speed * direction * 0.1;
			
			// Wrap angle to 0.0-1.0 range using fract() for seamless looping
			animated_angle = fract(animated_angle);
			
			// --- Fade Texture Sampling ---
			// Calculate distance from center for radial gradient application
			float distance_from_center = sqrt(dx * dx + dy * dy);
			
			// Map to fade texture coordinates:
			// U (horizontal): animated angular position (creates rotation)
			// V (vertical): radial distance scaled by size parameter
			vec2 fade_uv = vec2(animated_angle, distance_from_center * pulsating_size);
			
			// Sample fade texture and extract alpha channel
			// CircleFade.svg uses alpha to create radial gradient
			// Bright center (alpha=1.0) to dark edges (alpha=0.0)
			float fade_value = texture(fade_texture, fade_uv).a;
			
			// --- Color Blending ---
			// Blend outline color with pulsating color using fade value
			// fade_value = 0.0: mostly outline_color
			// fade_value = 1.0: mostly pulsating_color
			// Creates smooth gradient transition as effect travels
			final_color.rgb = mix(outline_color.rgb, pulsating_color.rgb, fade_value);
		}
		
		// Outline pixels ignore self_modulate - use shader color directly
		COLOR = final_color;
	} else {
		// Non-outline pixels respect self_modulate and parent modulation
		COLOR = base_color * COLOR;
	}
}
