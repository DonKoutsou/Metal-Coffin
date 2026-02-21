shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest_mipmap;

group_uniforms scanline_wiggle;
uniform float color_offset_multiplier: hint_range(0.0, 0.1) =  0.004;
uniform float black_offset_multiplier: hint_range(0.0, 0.1) = 0.1;
uniform float color_offset: hint_range(-0.1, 0.1) = 0.005;

group_uniforms blur;
uniform float blur_amount: hint_range(0.0, 3.0, 0.1);

uniform sampler2D colorLookup;


float noise(vec2 uv, float offset) {
	return (fract(sin(dot(uv * offset, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
}

vec3 rgb_to_yuv(vec3 rgb) {
	const mat3 RGB_TO_YUV = mat3(
		vec3(0.299, 0.587, 0.114),
		vec3(-0.14713, -0.28886, 0.436),
		vec3(.615, -0.51499, -0.10001)
		);
	return rgb * RGB_TO_YUV;
}

vec3 yuv_to_rgb(vec3 yuv) {
	const mat3 YUV_TO_RGB = mat3(
		vec3(1.0, 0.0, 1.13983),
		vec3(1.0, -0.39465, -0.58060),
		vec3(1.0, 2.03211, 0.0)
		);
	return clamp(yuv * YUV_TO_RGB, vec3(0.0), vec3(1.0));
}

void fragment() {

		float x_offset = color_offset + noise(vec2(floor(UV.y * 487.0), fract(UV.y * 487.0)), TIME) * color_offset_multiplier;
		float black_offset = noise(vec2(floor(UV.y * 487.0), fract(UV.y * 487.0)), TIME + 69.420) * (black_offset_multiplier * 0.01);

		COLOR = textureLod(screen_texture, SCREEN_UV + vec2(black_offset,0.0), 0.0);

		vec4 color2 = textureLod(screen_texture, SCREEN_UV + vec2(x_offset,0.0), blur_amount);
		vec3 yuv1 = rgb_to_yuv(COLOR.rgb);
		vec3 yuv2 = rgb_to_yuv(color2.rgb);

		COLOR.rgb = yuv_to_rgb(vec3(yuv1.x, yuv2.yz));
}