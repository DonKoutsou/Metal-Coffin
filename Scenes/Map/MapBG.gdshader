shader_type canvas_item;

render_mode unshaded;

uniform sampler2D NoiseTexture2: repeat_enable, filter_linear_mipmap;  // Add noise texture

uniform vec2 offset;
uniform float col;
uniform float z = 0.5;
uniform int colors : hint_range(1, 32);


void fragment()
{
	vec2 uv = (UV + offset) * z;

	// Sample the screen pixel
	vec4 n = texture(NoiseTexture2, uv);

	// Dither each channel (r, g, and b) to the number of color quantizations via dither value
	vec4 quantized_col;
	for (int i = 0; i < 4; i++) {
		float raw_channel = n[i];
		quantized_col[i] = floor(raw_channel * float(colors)) / float(colors - 1);
	}
	
	//COLOR.rgb = n.rgb;
	COLOR.rgb = quantized_col.rgb;
	COLOR.a = col;
}
