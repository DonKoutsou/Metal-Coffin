shader_type canvas_item;

// Color textures
uniform sampler2D GroundTexture: repeat_enable, filter_linear_mipmap;
//uniform sampler2D GroundTextureMask: repeat_enable, filter_nearest_mipmap_anisotropic;
uniform sampler2D GroundTexture2: repeat_enable, filter_linear_mipmap;
uniform sampler2D GroundTexture3: repeat_enable, filter_linear_mipmap;
// Noise texture
uniform sampler2D NoiseTexture: repeat_enable, filter_linear_mipmap;  // Add noise texture
uniform sampler2D NoiseTexture3: repeat_enable, filter_linear_mipmap;  // Add noise texture
// Normal texture
uniform sampler2D GroundNormalTexture: hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D GroundNormal2Texture: hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D GroundNormal3Texture: hint_normal, filter_linear_mipmap, repeat_enable;
uniform float NormalD = 1.0;
uniform float Light = 1.0;
// Custom offset for camera movement
uniform vec2 offset;
uniform vec2 Scale1;
uniform vec2 Scale2;
uniform float z = 0.5;

void fragment() {
	vec2 uv = (UV + offset) * z;
    // Scale the UVs for the main textures
    vec2 uv1 = uv * Scale1;
	vec2 uv2 = uv * Scale2;
	vec2 uvnoise = uv;
    // Sample noise texture
	//float t = abs(1.0 - texture(GroundTextureMask, uv).r) * 5.0;

	//float texColormask = clamp(t, 0.0, 1.0);
    vec3 patternNoise = texture(NoiseTexture, uvnoise).rgb; // Sample red channel for noise; adjust scale as needed

    // Normalize noise to [0, 1] if necessary
    // patternNoise = (patternNoise + 1.0) / 2.0; // Uncomment if your noise texture has values in range [-1, 1]

    // Sample colors from the textures
    vec4 texColor1 = texture(GroundTexture, uv1);
    vec4 texColor2 = texture(GroundTexture2, uv2);
	vec4 texColor3 = texture(GroundTexture3, uv2);

	vec3 texNormal1 = texture(GroundNormalTexture, uv1).rgb;
	vec3 n = texture(NoiseTexture3, uvnoise).rgb;
	texNormal1 /= vec3(1, 1, n.b * 10.0);
	vec3 texNormal2 = texture(GroundNormal2Texture, uv2).rgb;
	vec3 texNormal3 = texture(GroundNormal3Texture, uv2).rgb;
	//texNormal1.b = clamp(texNormal1.b + patternNoise, 0, 1);
	//texNormal2.b = clamp(texNormal2.b + patternNoise, 0, 1);
    // Blend colors based on sampled noise
	vec4 fincol = mix(texColor1, texColor2, patternNoise.g);
	fincol = mix(fincol, texColor3, patternNoise.b);
	
	vec3 finNorm = mix(texNormal1, texNormal2, patternNoise.g);
	finNorm = mix(finNorm, texNormal3, patternNoise.b);
	
    COLOR = fincol;
	COLOR.rgb *= Light;
	//COLOR = t;
	NORMAL_MAP = finNorm;
	//NORMAL_MAP += texture(NoiseTexture3, uv1).rgb;
    NORMAL_MAP_DEPTH = NormalD + (n.r / 10.0);
	
}