shader_type canvas_item;

uniform int ColorAmm: hint_range(1, 256, 1) = 1;
uniform sampler2D dither_texture : filter_nearest;
uniform vec2 DitherRes;
uniform float threshold : hint_range(0.0, 1.0);
uniform vec2 warp = vec2(64.0, 24.0);
uniform float D : hint_range(0.0, 1.0, 0.01);

uniform float hr: hint_range(0.0, 1.0) = 0.5;
uniform float vr: hint_range(0.0, 1.0) = 1.0;
uniform float hfov: hint_range(0.0, 360.0) = 180.0;
uniform float vfov: hint_range(0.0, 360.0) = 60;
uniform float z = 1.0;
uniform float ho: hint_range(0.0, 1.0) = 0.5;
uniform float vo: hint_range(0.0, 1.0) = 0.5;
uniform float to = 1.0;
uniform float to2 = 1.0;

vec2 Warp(vec2 pos){
pos = pos * 2.0 - 1.0;
pos *= vec2(1.0 + (pos.y * pos.y) * 1.0 / warp.x, 1.0 + (pos.x * pos.x) * 1.0/ warp.y);

return pos * 0.5+0.5;

}

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
	vec3 quant = floor(color * float(ColorAmm) + 0.5) / float(ColorAmm);
	return quant;
}

float border_factor(vec2 uv) {
    float d = min(
        min(uv.x, 1.0 - uv.x),
        min(uv.y, 1.0 - uv.y)
    );

    return d / 0.5;
}

void fragment(){
	vec2 texCoord = SCREEN_UV;
    vec2 newCoord;

    texCoord = (texCoord - 0.5) * z + 0.5;

    vec2 o;
    o.x = radians(hfov);
    o.y = radians(vfov);

    float aspect = 0.5625;

    vec2 fov;
    fov.y = o.y * vr;
    fov.x = atan(1.0 / (aspect / tan(fov.y * 0.5))) * 2.0;

    vec3 v;

    v.x = texCoord.x - 0.5 - (ho - 0.5);
    v.y = (texCoord.y - 0.5) * aspect - to2 * (vo - 0.5);
    v.z = 0.5 / tan(fov.x * 0.5);

    float ta = (0.5 - vo) * (1.0 - vr) * o.y * 2.0;

    float c = cos(ta);
    float s = sin(ta);

    float tz = v.z * c - v.y * s;
    float ty = v.z * s + v.y * c;

    v.z = tz;
    v.y = ty;

    v = normalize(v);

    float lon = atan(v.x, v.z);

    float vz2 = v.x * sin(lon) + v.z * cos(lon);

    float lat = atan(v.y, vz2);

    newCoord.x = lon / (o.x * hr) + 0.5;
    newCoord.y = lat / (o.y * vr) + to * tan((1.0 - vr) * (vo - 0.5)) + 0.5;
	
	if (any(lessThan(newCoord, vec2(0.0))) || any(greaterThan(newCoord, vec2(1.0))))
    {
        COLOR = vec4(0.0);
    }
	else
	{
		// Map the dither texture onto the screen pixels with tiling and repeating
		vec2 dither_size = vec2(textureSize(dither_texture, 0));
		vec2 dither_uv = mod(newCoord * DitherRes, dither_size) / dither_size;
		
		// Sample the screen pixel
		vec3 screen_col = texture(TEXTURE, newCoord).rgb;

		// Sample the corresponding dither pixel luminance
		float dither_luminance = texture(dither_texture, dither_uv).r;

		// Dither each channel (r, g, and b) to the number of color quantizations via dither value
		vec3 quantized_col;
		for (int i = 0; i < 3; i++) {
			float raw_channel = screen_col[i];
			float dither_amount = threshold * dither_luminance;
			float quantized_channel = dither(raw_channel, dither_amount, ColorAmm);
			quantized_col[i] = floor(quantized_channel * float(ColorAmm)) / float(ColorAmm - 1);
		}
		COLOR.rgb = quantized_col;

		COLOR.rgb = to_indexed_palette(COLOR.rgb);
		
		float border = border_factor(vec2(0.5, newCoord.y));
		border = smoothstep(0.0, D, border);

		COLOR.rgb *= border;
	}
	
}
