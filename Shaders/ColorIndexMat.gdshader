shader_type canvas_item;

uniform float ColorAmm: hint_range(8, 256, 1.0) = 1.;
uniform int levels : hint_range(1, 16);
uniform sampler2D dither_texture : filter_nearest;
uniform vec2 DitherRes;
uniform float threshold : hint_range(0.0, 1.0);

//uniform float vignette_strength: hint_range(0., 3., 0.01) = 1.;


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

vec3 to_indexed_palette(vec3 color) {
    vec3 quant = floor(color * ColorAmm + 0.5) / ColorAmm;
    return quant;
}

void fragment(){
	// Map the dither texture onto the screen pixels with tiling and repeating
	vec2 dither_size = vec2(textureSize(dither_texture, 0));
	vec2 dither_uv = mod(UV * DitherRes, dither_size) / dither_size;
	
	// Sample the screen pixel
	vec3 screen_col = texture(TEXTURE, UV).rgb;

	// Sample the corresponding dither pixel luminance
	float dither_luminance = texture(dither_texture, dither_uv).r;
	
	// Dither each channel (r, g, and b) to the number of color quantizations via dither value
	vec3 quantized_col;
    for (int i = 0; i < 3; i++) {
        float raw_channel = screen_col[i];
        float dither_amount = threshold * dither_luminance;
        float quantized_channel = dither(raw_channel, dither_amount, levels);
        quantized_col[i] = floor(quantized_channel * ColorAmm) / (ColorAmm - 1.0);
    }
	COLOR.rgb = quantized_col;
	//COLOR.rgb = texture(TEXTURE, UV).rgb;
	//COLOR.rgb *= vignette;
	COLOR.rgb = to_indexed_palette(COLOR.rgb);

}
