shader_type canvas_item;

uniform float offset: hint_range(0.0, 20.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = UV;
	vec2 halfpixel = SCREEN_PIXEL_SIZE / 2.0;
	
	vec4 sum = texture(TEXTURE, uv) * 4.0;
	sum += texture(TEXTURE, uv - halfpixel.xy * offset);
	sum += texture(TEXTURE, uv + halfpixel.xy * offset);
	sum += texture(TEXTURE, uv + vec2(halfpixel.x, -halfpixel.y) * offset);
	sum += texture(TEXTURE, uv - vec2(halfpixel.x, -halfpixel.y) * offset);

	COLOR = sum / 8.0;
}
