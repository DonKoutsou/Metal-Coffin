shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.0, 0.4, 0.0, 1.0);
uniform float range_lines : hint_range(0.0, 10.0, 1.0) = 4.0;
uniform float sector_lines : hint_range(0.0, 10.0, 1.0) = 4.0;
uniform float line_width : hint_range(0.001, 0.1) = 0.01;
uniform float beam_angle : hint_range(0.0, 1.0) = 0.2;
uniform float beam_width : hint_range(0.0, 0.05) = 0.003;
uniform float trail_width : hint_range(0.0, 1.0) = 0.5;
uniform float sector_rotation : hint_range(0.0, 1.0) = 0.0;
uniform bool ShowRadat = false;

float greater_than(float x, float y) {
  return max(sign(x - y), 0.0);
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float a = (atan(uv.y, uv.x) + 3.141592656) / 6.283185312;
    float l = length(uv);
	
	 a = mod(a + sector_rotation, 1.0);
    // Set base color to fully transparent
    COLOR = vec4(0.0, 0.0, 0.0, 0.0);

    // Apply lines with respective color and transparency
    float range_line_alpha = line_color.a * greater_than(mod(l, 1.0 / range_lines) * range_lines, 1.0 - line_width * range_lines);
    float sector_line_alpha = line_color.a * greater_than(abs(mod(a, 1.0 / sector_lines) * sector_lines * 2.0 - 1.0), 1.0 - (line_width / 6.283185312 / l) * sector_lines);
    float combined_alpha = max(range_line_alpha, sector_line_alpha);
    COLOR.rgb = mix(COLOR.rgb, line_color.rgb, combined_alpha);
    COLOR.a = max(COLOR.a, combined_alpha);

	if (ShowRadat)
	{
		float current_beam_angle = mod(beam_angle * TIME, 1.0);
	    a = a - 1.0 * greater_than(a, current_beam_angle);

	    // Apply trail with transparency
	    float trail_alpha = line_color.a * max(0.0, (1.0 - (current_beam_angle - a) / trail_width));
	    COLOR.rgb = mix(COLOR.rgb, line_color.rgb, trail_alpha);
	    COLOR.a = max(COLOR.a, trail_alpha);

	    // Apply beam with transparency
	    float beam_alpha = line_color.a * greater_than(a, current_beam_angle - beam_width);
	    COLOR.rgb = mix(COLOR.rgb, line_color.rgb, beam_alpha);
	    COLOR.a = max(COLOR.a, beam_alpha);
	}
    

    // Ensure only the circle area of the radar is visible
    COLOR.a *= greater_than(1.0, l) + float(0.0);
}