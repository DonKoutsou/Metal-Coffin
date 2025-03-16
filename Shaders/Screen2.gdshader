shader_type canvas_item;

uniform vec2 res = vec2(864, 486);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform int mask_type : hint_range(0, 2) = 0;

group_uniforms Vignette;
uniform float vignette_strength : hint_range(0., 3., 0.01) = 1.;
uniform float image_flicker : hint_range(0., 1., .01) = 1.;
uniform float skip : hint_range(0., 1., .01) = 1.;

uniform int bloom_type : hint_range(0, 2) = 0;

uniform float hardScan : hint_range(-12.0, -1.0) = -8.0;
uniform float hardPix : hint_range(-4.0, 0.0) = -2.0;
uniform float hardBloomScan : hint_range(-4.0, 0.0) = -2.0;
uniform float hardBloomPix : hint_range(-2.0, 0.0) = -1.5;
uniform float bloomAmount : hint_range(1.0, 16.0) = 16.0;

uniform vec2 warp = vec2(64.0, 24.0);

uniform float maskDark : hint_range(0.0, 1.0) = 0.5;
uniform float maskLight : hint_range(1.0, 2.0) = 1.5;

float ToLinear1(float c){ return (c <= 0.04045) ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4); }
vec3 ToLinear(vec3 c){ return vec3(ToLinear1(c.r), ToLinear1(c.g), ToLinear1(c.b)); }
float ToSrgb1(float c){ return (c < 0.0031308) ? c * 12.92 : 1.055 * pow(c, 0.41666) - 0.055; }
vec3 ToSrgb(vec3 c){ return vec3(ToSrgb1(c.r), ToSrgb1(c.g), ToSrgb1(c.b)); }

vec3 Fetch(vec2 pos, vec2 off, sampler2D iChannel0){
	pos = floor(pos * res + off) / res;

	// Ensure that the return value is vec3(0.0) when out of bounds.
	if (max(abs(pos.x - 0.5), abs(pos.y - 0.5)) > 0.5) {
		return vec3(0.0);
	}

	return ToLinear(texture(iChannel0, pos.xy, -16.0).rgb);
}

vec2 Dist(vec2 pos){
	pos *= res;
	return (vec2(0.5) - (pos - floor(pos)));
}

float Gaus(float pos, float scale){ return exp2(scale * pos * pos); }

vec3 Horz3(vec2 pos, float off, sampler2D iChannel0){
	vec3 b = Fetch(pos, vec2(-1.0, off), iChannel0);
	vec3 c = Fetch(pos, vec2(0.0, off), iChannel0);
	vec3 d = Fetch(pos, vec2(1.0, off), iChannel0);
	float dst = Dist(pos).x;
	float scale = hardPix;

	float wb = Gaus(dst - 1.0, scale);
	float wc = Gaus(dst, scale);
	float wd = Gaus(dst + 1.0, scale);

	return (b * wb + c * wc + d * wd) / (wb + wc + wd);
}

vec3 Tri(vec2 pos, sampler2D iChannel0){
	vec3 a = Horz3(pos, -1.0, iChannel0);
	vec3 b = Horz3(pos, 0.0, iChannel0);
	vec3 c = Horz3(pos, 1.0, iChannel0);
	float wa = Gaus(Dist(pos).y - 1.0, hardScan);
	float wb = Gaus(Dist(pos).y, hardScan);
	float wc = Gaus(Dist(pos).y + 1.0, hardScan);
	return a * wa + b * wb + c * wc;
}

vec2 Warp(vec2 pos){
pos = pos * 2.0 - 1.0;
pos *= vec2(1.0 + (pos.y * pos.y) * 1.0 / warp.x, 1.0 + (pos.x * pos.x) * 1.0/ warp.y);

return pos * 0.5+0.5;

}

vec3 Mask(vec2 pos){
	if(mask_type == 0){
		float line = maskLight, odd = fract(pos.x / 6.0) < 0.5 ? 1.0 : 0.0;
		if (fract((pos.y + odd) / 2.0) < 0.5) line = maskDark;
		pos.x = fract(pos.x / 3.0);
		return vec3(pos.x < 0.333 ? maskLight : pos.x < 0.666 ? maskDark : maskDark) * line;
	} else if(mask_type == 1) {
		pos.x += pos.y * 3.0; pos.x = fract(pos.x / 6.0);
		return vec3(pos.x < 0.333 ? maskLight : pos.x < 0.666 ? maskDark : maskDark);
	} else {
		pos.xy = floor(pos.xy * vec2(1.0, 0.5));
		pos.x += pos.y * 3.0; pos.x = fract(pos.x / 6.0);
		return vec3(pos.x < 0.333 ? maskLight : pos.x < 0.666 ? maskDark : maskDark);
	}
}

float onOff(float a, float b, float c){
    return step(c, sin(TIME + a * cos(TIME * b)));
}

void fragment(){
	vec2 pos = Warp(FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE).xy);

	COLOR.rgb = Tri(pos, SCREEN_TEXTURE) * Mask(FRAGCOORD.xy);
	vec2 look = pos;
	float window = 1.0 / (1.0 + 20.0 * pow(look.y - mod(TIME / 4.0, 1.0), 2.0)) * image_flicker;
	look.x += sin(look.y * 10.0 + TIME) / 50.0 * onOff(4.0, 4.0, 0.3) * (1.0 + cos(TIME * 80.0)) * window;
	float vShift = 0.4 * onOff(2.0, 3.0, 0.9) * (pow(sin(TIME) * sin(TIME * 20.0) + (0.5 + 0.1 * sin(TIME * 200.0) * cos(TIME)), 2.0)) * skip;
	look.y = mod(look.y + vShift, 1.0);

	float aberration_amount = 0.005 * window * 5.0;
	vec2 red_offset = vec2(-aberration_amount, 0.0);
	vec2 blue_offset = vec2(aberration_amount, 0.0);

	COLOR.r = mix(COLOR.r, texture(SCREEN_TEXTURE, look + red_offset).r, 0.5);
	COLOR.g = mix(COLOR.g, texture(SCREEN_TEXTURE, look).g, 0.5);
	COLOR.b = mix(COLOR.b, texture(SCREEN_TEXTURE, look + blue_offset).b, 0.5);

	float vigAmt = (3.3) * vignette_strength;
	float vignette = (1.0 - vigAmt * pow(pos.y - 0.5, 2.0)) * (1.0 - vigAmt * pow(pos.x - 0.5, 2.0));
	COLOR.rgb *= vignette;
	COLOR.rgb = ToSrgb(COLOR.rgb);
}