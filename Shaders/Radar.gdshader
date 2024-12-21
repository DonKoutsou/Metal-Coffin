shader_type canvas_item;
render_mode unshaded;
uniform vec4 line_color : source_color = vec4(0.0, 0.4, 0.0, 1.0);

uniform float line_width : hint_range(0.001, 0.1) = 0.01;

uniform bool Paused = false;
uniform float scale_factor : hint_range(0, 2.0) = 1.0; // New scaling uniform


float greater_than(float x, float y) {
  return max(sign(x - y), 0.0);
}

void fragment() {
    // Apply the scaling factor to the UV coordinates to scale the effect
    vec2 uv = (UV * 2.0 - 1.0) / scale_factor;
    float a = (atan(uv.y, uv.x) + 3.141592656) / 6.283185312;
    float l = length(uv);
    // Set base color to fully transparent
    COLOR = vec4(0.0, 0.0, 0.0, 0.0);

    // Adjust line width based on scale factor
    float scaled_line_width = (line_width / 10.0) / scale_factor;
    // Apply lines with respective color and transparency
    float range_line_alpha = line_color.a * greater_than(mod(l, 1.0 / 1.0) * 1.0, 1.0 - scaled_line_width * 1.0);

    COLOR.rgb = mix(COLOR.rgb, line_color.rgb, range_line_alpha);
    COLOR.a = max(COLOR.a, range_line_alpha);
	COLOR.a *= greater_than(1.0, l) + float(0.0);
}