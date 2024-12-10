shader_type canvas_item;

uniform vec4 active_color : source_color;
uniform float active_width : hint_range(0.0, 0.3, .01) = 1;
uniform float angle : hint_range(0, 6.28318, .01) = 0;

void fragment() {
	COLOR.rgb = active_color.rgb;
	float line_width = active_width;
	mat2 rotation = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
	vec2 uv = (UV-vec2(.5))*rotation + vec2(.5);

	COLOR.a = max(smoothstep(line_width,.0,abs(uv.x-.5)), 
				+ max(smoothstep(line_width,.0, abs(uv.x-.5-uv.y)), 
				+ smoothstep(line_width,.0, abs(uv.y-.5+uv.x))));
	COLOR.a -= smoothstep(.5,.52, length(uv - vec2(.5)));
}