shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 viewport_size = vec2(1920.0, 1080.0);

uniform vec2 camera_position = vec2(0.0, 0.0);
uniform float camera_zoom = 1.0;
uniform float camera_rotation = 0.0;

// The major grid spacing will be chosen as powers of 10.
// This is the minimum desired major-line spacing in screen pixels.
uniform float target_major_px = 80.0;

// Minor lines are major_step / 10.
// They fade in when their pixel spacing is large enough.
uniform float minor_fade_start_px = 8.0;
uniform float minor_fade_end_px = 20.0;

uniform float minor_half_thickness_px = 0.5;
uniform float major_half_thickness_px = 1.0;
uniform float axis_half_thickness_px = 1.5;

uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 minor_color : source_color = vec4(0.35, 0.35, 0.35, 0.35);
uniform vec4 major_color : source_color = vec4(0.7, 0.7, 0.7, 0.65);
//uniform vec4 axis_color : source_color = vec4(0.3, 0.65, 1.0, 0.9);
//
//uniform bool show_axis = true;


vec4 blend_over(vec4 base, vec4 layer, float alpha) {
	float a = clamp(alpha * layer.a, 0.0, 1.0);
	base.rgb = mix(base.rgb, layer.rgb, a);
	base.a = max(base.a, a);
	return base;
}


float grid_line_alpha(vec2 world_pos, float step, float half_thickness_px, float pixels_per_world_unit) {
	vec2 cell = fract(world_pos / step);

	vec2 dist_to_line_world = min(cell, 1.0 - cell) * step;
	float dist_to_line_px = min(dist_to_line_world.x, dist_to_line_world.y) * pixels_per_world_unit;

	return 1.0 - smoothstep(half_thickness_px, half_thickness_px + 1.0, dist_to_line_px);
}


float axis_line_alpha(vec2 world_pos, float half_thickness_px, float pixels_per_world_unit) {
	vec2 dist_px = abs(world_pos) * pixels_per_world_unit;
	float d = min(dist_px.x, dist_px.y);

	return 1.0 - smoothstep(half_thickness_px, half_thickness_px + 1.0, d);
}


void fragment() {
	float ppu = max(camera_zoom, 0.000001);

	vec2 screen_px = SCREEN_UV * viewport_size;
	vec2 centered_px = screen_px - viewport_size * 0.5;

	// Convert from screen pixels to world offset.
	vec2 world_offset = centered_px / ppu;

	// Account for Camera2D rotation.
	float c = cos(camera_rotation);
	float s = sin(camera_rotation);
	world_offset = vec2(
		c * world_offset.x - s * world_offset.y,
		s * world_offset.x + c * world_offset.y
	);

	vec2 world_pos = camera_position + world_offset;

	// Pick a power-of-10 grid size.
	// Example: 1000, 100, 10, 1, 0.1, etc.
	float desired_world_step = target_major_px / ppu;
	float major_step = pow(10.0, ceil(log(max(desired_world_step, 0.0000001)) / log(10.0)));
	float minor_step = major_step / 10.0;

	float minor_px = minor_step * ppu;

	float minor_fade = smoothstep(minor_fade_start_px, minor_fade_end_px, minor_px);

	float minor_alpha = grid_line_alpha(
		world_pos,
		minor_step,
		minor_half_thickness_px,
		ppu
	) * minor_fade;

	float major_alpha = grid_line_alpha(
		world_pos,
		major_step,
		major_half_thickness_px,
		ppu
	);

	//float axis_alpha = 0.0;
	//if (show_axis) {
		//axis_alpha = axis_line_alpha(
			//world_pos,
			//axis_half_thickness_px,
			//ppu
		//);
	//}

	vec4 color = background_color;

	color = blend_over(color, minor_color, minor_alpha);
	color = blend_over(color, major_color, major_alpha);
	//color = blend_over(color, axis_color, axis_alpha);

	COLOR = color;
}