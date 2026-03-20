/*
 * Outline Shader for UI Elements
 * 
 * A versatile canvas_item shader that provides configurable outline and pulsating
 * animation effects for all UI elements. The shader respects texture alpha channels
 * and exposes all parameters through the Godot inspector for easy customization.
 * 
 * USAGE EXAMPLE:
 *   1. Create a ShaderMaterial in your CanvasItem node
 *   2. Set the shader to this file (outline_shader.gdshader)
 *   3. Adjust properties in the inspector:
 *      - color: Base outline color (default: white)
 *      - width: Outline thickness in pixels (default: 1.0)
 *      - pattern: 0=diamond, 1=circle, 2=square (default: 0)
 *      - enable_pulsating: Toggle animated pulsating effect (default: false)
 *      - pulsating_color: Color of the pulsating animation (default: cyan)
 *      - pulsating_speed: Animation speed multiplier (default: 1.0)
 *      - aa_strength: Antialiasing strength for smooth edges (0=off, 1=normal, 2=strong)
 * 
 * ANTIALIASING:
 *   The shader applies antialiasing to both edges of the outline when aa_strength > 0:
 *   - Outer edge: Smooths the outline pixels in the margin/transparent area
 *   - Inner edge: Softens the texture edge pixels where they meet the outline
 *   The shader also filters out disconnected fragments to prevent isolated pixel artifacts.
 * 
 * COMPATIBILITY:
 *   Works with all CanvasItem nodes (Control, Sprite2D, TextureRect, etc.)
 */

shader_type canvas_item;

// Base outline properties
uniform vec4 color : source_color = vec4(1.0);  // Outline color (RGBA)
uniform float width : hint_range(0, 10) = 1.0;  // Outline thickness in pixels
uniform int pattern : hint_range(0, 2) = 0;     // Outline pattern: 0=diamond, 1=circle, 2=square
uniform bool inside = false;                     // If true, draws outline inside the texture
uniform bool add_margins = true;                 // Expands canvas to fit outline (only useful when inside=false)

// Pulsating animation properties
uniform bool enable_pulsating = false;                               // Enable/disable pulsating animation
uniform vec4 pulsating_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);  // Pulsating animation color (cyan by default)
uniform float pulsating_thickness : hint_range(0.0, 10.0) = 1.0;    // Thickness of pulsating band within outline
uniform float pulsating_speed : hint_range(0.1, 5.0) = 1.0;         // Animation speed multiplier
uniform bool pulsating_clockwise = false;                            // Animation direction (false=counterclockwise)

// Antialiasing properties
uniform float aa_strength : hint_range(0.0, 2.0) = 1.0;             // Antialiasing strength (0=off, 1=normal, 2=strong)

/*
 * Vertex shader: Expands the vertex positions to make room for the outline
 * when add_margins is enabled. This prevents the outline from being clipped.
 */
void vertex() {
	if (add_margins) {
		VERTEX += (UV * 2.0 - 1.0) * width;
	}
}

/*
 * Outline Detection Algorithm
 * 
 * Checks if the current pixel is on the edge of the texture by sampling
 * surrounding pixels in a pattern (diamond, circle, or square).
 * 
 * Algorithm:
 *   1. Iterate through pixels in the specified pattern around the current pixel
 *   2. For each neighboring pixel, check if it crosses the texture boundary
 *      (either alpha <= 0 or out of UV bounds)
 *   3. If any neighbor crosses the boundary, this pixel is on an edge
 * 
 * Parameters:
 *   - uv: Current pixel's UV coordinates
 *   - texture_pixel_size: Size of one pixel in UV space
 *   - texture: The texture sampler
 * 
 * Returns: true if this pixel is on an outline edge, false otherwise
 */
bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	for (float i = -ceil(width); i <= ceil(width); i++) {
		float x = abs(i) > width ? width * sign(i) : i;
		float offset;

		if (pattern == 0) {
			offset = width - abs(x);
		} else if (pattern == 1) {
			offset = floor(sqrt(pow(width + 0.5, 2) - x * x));
		} else if (pattern == 2) {
			offset = width;
		}

		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			float y = abs(j) > offset ? offset * sign(j) : j;
			vec2 xy = uv + texture_pixel_size * vec2(x, y);

			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a <= 0.0) == inside) {
				return true;
			}
		}
	}

	return false;
}

/*
 * Check if outline pixel is connected (not a fragment)
 * 
 * Filters out isolated pixels that are disconnected from the main outline.
 * This prevents antialiasing artifacts and stray fragments.
 * 
 * Algorithm:
 *   1. Sample 8 surrounding pixels (cardinal + diagonal)
 *   2. Count how many neighbors would also be outline pixels
 *   3. If too few neighbors, it's an isolated fragment
 * 
 * Parameters:
 *   - uv: Current pixel's UV coordinates
 *   - texture_pixel_size: Size of one pixel in UV space
 *   - texture: The texture sampler
 * 
 * Returns: true if pixel is part of connected outline, false if isolated
 */
bool isConnectedOutline(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	// Count outline neighbors in 8 directions
	int neighbor_count = 0;
	
	for (float x = -1.0; x <= 1.0; x += 1.0) {
		for (float y = -1.0; y <= 1.0; y += 1.0) {
			if (x == 0.0 && y == 0.0) continue;
			
			vec2 neighbor_uv = uv + vec2(x, y) * texture_pixel_size;
			
			// Check if neighbor would be part of outline
			if (hasContraryNeighbour(neighbor_uv, texture_pixel_size, texture)) {
				neighbor_count++;
			}
		}
	}
	
	// Need at least 2 neighbors to be considered connected
	return neighbor_count >= 2;
}

/*
 * Calculate Improved Antialiased Outline Alpha
 * 
 * Computes smooth alpha based on distance to the texture edge.
 * Works on both inside and outside of the outline for uniform smoothing.
 * 
 * Algorithm:
 *   1. Sample texture in a circle around the pixel
 *   2. Calculate coverage percentage (how many samples are solid)
 *   3. Apply smoothstep for smooth gradient
 *   4. Scale by AA strength
 * 
 * Parameters:
 *   - uv: Current pixel's UV coordinates
 *   - texture_pixel_size: Size of one pixel in UV space
 *   - texture: The texture sampler
 * 
 * Returns: Alpha multiplier for smooth blending (0.0 to 1.0)
 */
float getAntialiasingAlpha(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	if (aa_strength <= 0.0) {
		return 1.0;
	}
	
	// Sample in 8 directions around the pixel
	float solid_samples = 0.0;
	float total_samples = 8.0;
	float sample_distance = aa_strength * 0.7;
	
	vec2 sample_offsets[8] = vec2[](
		vec2(-1.0, 0.0),  // left
		vec2(1.0, 0.0),   // right
		vec2(0.0, -1.0),  // up
		vec2(0.0, 1.0),   // down
		vec2(-0.707, -0.707),  // diagonal top-left
		vec2(0.707, -0.707),   // diagonal top-right
		vec2(-0.707, 0.707),   // diagonal bottom-left
		vec2(0.707, 0.707)     // diagonal bottom-right
	);
	
	for (int i = 0; i < 8; i++) {
		vec2 sample_uv = uv + sample_offsets[i] * texture_pixel_size * sample_distance;
		if (texture(texture, sample_uv).a > 0.1) {
			solid_samples += 1.0;
		}
	}
	
	// Calculate coverage ratio
	float coverage = solid_samples / total_samples;
	
	// Apply smoothstep for gradient
	// This creates smooth transitions on both edges
	return smoothstep(0.1, 0.9, coverage);
}

/*
 * Pulsating Animation Algorithm
 * 
 * Determines if the current pixel should display the pulsating color based on
 * its angular position relative to the texture center and the current animation time.
 * 
 * Algorithm:
 *   1. Early exit if pulsating is disabled
 *   2. Calculate the angle from the texture center (0.5, 0.5) to current UV
 *   3. Calculate animated angle position based on TIME and speed
 *   4. Normalize both angles to 0-2π range
 *   5. Check if pixel angle is within the animated arc (±0.5 radians ~28°)
 *   6. Handle wrap-around at 0/2π boundary
 * 
 * The pulsating effect appears as a colored band that sweeps around the outline
 * in a circular motion, creating an attention-drawing animation.
 * 
 * Parameters:
 *   - uv: Current pixel's UV coordinates
 *   - time: Current game time (TIME built-in)
 * 
 * Returns: true if this pixel should display pulsating color, false otherwise
 */
bool isPulsating(vec2 uv, float time) {
	if (!enable_pulsating) {
		return false;
	}
	
	// Calculate angle from center (0.5, 0.5) to current UV
	vec2 center = vec2(0.5, 0.5);
	vec2 dir = uv - center;
	float pixel_angle = atan(dir.y, dir.x);
	
	// Calculate the animated angle position
	// Normalize TIME with speed, move counterclockwise by default (subtract)
	float rotation_direction = pulsating_clockwise ? 1.0 : -1.0;
	float animated_angle = rotation_direction * time * pulsating_speed;
	
	// Normalize both angles to 0-2π range
	pixel_angle = mod(pixel_angle + 3.14159265359, 6.28318530718);
	animated_angle = mod(animated_angle + 3.14159265359, 6.28318530718);
	
	// Define the arc width for pulsating effect (smaller = tighter band)
	float arc_width = 0.5; // radians (~28 degrees)
	
	// Check if pixel angle is within the animated arc
	float angle_diff = abs(pixel_angle - animated_angle);
	// Handle wrap-around at 0/2π boundary
	if (angle_diff > 3.14159265359) {
		angle_diff = 6.28318530718 - angle_diff;
	}
	
	return angle_diff < arc_width;
}

/*
 * Fragment Shader: Main rendering logic
 * 
 * Processing steps:
 *   1. Adjust UV coordinates if margins are added
 *   2. Sample the base texture
 *   3. Skip outline processing for margin area or zero width
 *   4. Detect outline pixels using hasContraryNeighbour
 *   5. Filter out isolated fragments using connectivity check
 *   6. Detect texture edge pixels for inner AA (when inside=false)
 *   7. Apply base outline color to outline pixels
 *   8. Blend pulsating color if animation is enabled and pixel is in arc
 *   9. Apply antialiasing to outline pixels (outer edge)
 *   10. Apply antialiasing to texture edge pixels (inner edge)
 *   11. Output final color with proper alpha blending
 */
void fragment() {
	vec2 uv = UV;
	bool should_process_outline = true;

	if (add_margins) {
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));

		uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;

		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			COLOR.a = 0.0;
			should_process_outline = false;
		} else {
			COLOR *= texture(TEXTURE, uv);
		}
	} else {
		COLOR *= texture(TEXTURE, uv);
	}
	
	// Skip outline processing if width is 0 (no outline needed)
	if (width <= 0.0) {
		should_process_outline = false;
	}

	// Check if this pixel should be an outline pixel
	bool is_outline = should_process_outline && (COLOR.a > 0.0) == inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE);
	
	if (is_outline) {
		// Filter out isolated fragments (disconnected pixels)
		if (!isConnectedOutline(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
			// Skip isolated fragments
			is_outline = false;
		}
	}
	
	// Also check if this is a texture edge pixel (for inner AA when inside=false)
	bool is_texture_edge = false;
	if (!inside && !is_outline && COLOR.a > 0.0 && aa_strength > 0.0) {
		// Check if this solid pixel is near the edge
		is_texture_edge = hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE);
	}
	
	if (is_outline) {
		// Base outline color
		vec4 outline_col = color;
		
		// Only check pulsating if enabled (optimization)
		if (enable_pulsating && isPulsating(uv, TIME)) {
			// Blend pulsating color with base outline color
			// Use pulsating_thickness to determine blend strength
			float blend_factor = clamp(pulsating_thickness / width, 0.0, 1.0);
			outline_col = mix(color, pulsating_color, blend_factor);
		}
		
		// Apply antialiasing to smooth all edges
		if (aa_strength > 0.0) {
			float aa_alpha = getAntialiasingAlpha(uv, TEXTURE_PIXEL_SIZE, TEXTURE);
			outline_col.a *= aa_alpha;
		}
		
		// Blend outline with existing color
		// For inside mode: mix with texture color
		// For outside mode: replace transparent areas with outline
		if (inside) {
			// Inside mode: blend outline color with existing texture
			COLOR.rgb = mix(COLOR.rgb, outline_col.rgb, outline_col.a);
		} else {
			// Outside mode: the outline is in transparent area, so just apply it
			COLOR.rgb = outline_col.rgb;
			COLOR.a = outline_col.a;
		}
	} else if (is_texture_edge) {
		// Apply AA to the texture edge (inner edge of outline)
		// This smooths the transition between texture and outline
		float edge_aa = getAntialiasingAlpha(uv, TEXTURE_PIXEL_SIZE, TEXTURE);
		COLOR.a *= edge_aa;
	}
}