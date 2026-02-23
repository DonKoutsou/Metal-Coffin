shader_type canvas_item;

render_mode unshaded;

uniform sampler2D NoiseTexture2: repeat_enable, filter_linear_mipmap;  // Add noise texture

// Custom offset for camera movement
uniform vec2 offset;
uniform float col;
uniform float z = 0.5;

uniform int levels : hint_range(1, 16);
uniform float threshold : hint_range(0.0, 1.0);
uniform int colors : hint_range(1, 32);
uniform sampler2D dither_texture : filter_nearest;
uniform vec2 DitherRes;

float dither(float raw, float dither, int depth) {
	
	float div = 1.0 / float(depth);
	float val = 0.0;
	
	for (int i = 0; i < depth; i++) {
		if (raw <= div * (float(i + 1))) {
			if ((raw * float(depth)) - float(i) <= dither * 0.999) {
				val = div * float(i);
			} else {
				val = div * float(i + 1);
			}
			break;
		}
	}
	if (raw >= 1.0) {
		val = 1.0;
	}
	return val;
}

void fragment()
{
	vec2 uv = (UV + offset) * z;
	//vec2 screenuv = (SCREEN_UV  + offset) * z;
	// Map the dither texture onto the screen pixels with tiling and repeating
	vec2 dither_size = vec2(textureSize(dither_texture, 0));
	vec2 dither_uv = mod(uv * DitherRes, dither_size) / dither_size;
	
	// Sample the screen pixel
	vec4 n = texture(NoiseTexture2, uv);
	//vec3 screen_col = n.rgb;

	// Sample the corresponding dither pixel luminance
	float dither_luminance = texture(dither_texture, dither_uv).r;

	// Dither each channel (r, g, and b) to the number of color quantizations via dither value
	vec4 quantized_col;
    for (int i = 0; i < 4; i++) {
        float raw_channel = n[i];
        float dither_amount = threshold * dither_luminance;
        float quantized_channel = dither(raw_channel, dither_amount, levels);
        quantized_col[i] = floor(quantized_channel * float(colors)) / float(colors - 1);
    }
	
	//COLOR.rgb = n.rgb;
	COLOR.rgb = quantized_col.rgb;
	COLOR.a = col;
	// Apply the dithered color
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
