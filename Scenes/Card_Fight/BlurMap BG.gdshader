shader_type canvas_item;

render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D heightInfo : repeat_enable, filter_linear_mipmap;
uniform float LOD : hint_range(0.0, 10.0, 0.1);
const float z = 0.25;
uniform vec2 offset;

void fragment() {
	vec2 uv = (UV + offset) * z;
	
	vec3 Height = texture(heightInfo, uv).rgb;
	float L = (1.0 - Height.r) * LOD;
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, L);
}
