shader_type canvas_item;

uniform sampler2D GroundTexture: repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D GroundNormalTexture: hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D GroundTextureMask: repeat_enable, filter_nearest_mipmap_anisotropic;
uniform sampler2D GroundTexture2: repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D GroundNormal2Texture: hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D NoiseTexture: repeat_enable, filter_linear_mipmap_anisotropic;

uniform float NormalD = 1.0;

uniform vec2 offset;
uniform vec2 Scale1;
uniform vec2 Scale2;

void fragment() {
    vec2 uv1 = (UV + offset) * Scale1;
	vec2 uv2 = (UV + offset) * Scale2;
	vec2 uvnoise = UV + offset;

	float t = abs(texture(GroundTextureMask, uv1).r) / 4.0;

	float texColormask = clamp(t, 0.0, 1.0);
    float patternNoise = texture(NoiseTexture, uvnoise).r;

    vec4 texColor1 = texture(GroundTexture, uv1);
    vec4 texColor2 = texture(GroundTexture2, uv2);

	vec3 texNormal1 = texture(GroundNormalTexture, uv1).rgb;
	vec3 texNormal2 = texture(GroundNormal2Texture, uv2).rgb;
	texNormal1.b = clamp(texNormal1.b + patternNoise, 0, 1);
	texNormal2.b = clamp(texNormal2.b + patternNoise, 0, 1);
	
	float MixedNoise = mix(patternNoise, texColormask, 0.3);
    COLOR = mix(texColor1, texColor2, MixedNoise);
	NORMAL_MAP = mix(texNormal1, texNormal2, MixedNoise);

    NORMAL_MAP_DEPTH = NormalD;
}