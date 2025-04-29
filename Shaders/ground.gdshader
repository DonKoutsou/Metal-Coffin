shader_type canvas_item;

// Color textures
uniform sampler2D GroundTexture: repeat_enable, filter_nearest_mipmap_anisotropic;
uniform sampler2D GroundTextureMask: repeat_enable, filter_nearest_mipmap_anisotropic;
uniform sampler2D GroundTexture2: repeat_enable, filter_nearest_mipmap_anisotropic;

// Noise texture
uniform sampler2D NoiseTexture: repeat_enable, filter_nearest_mipmap_anisotropic;  // Add noise texture

// Normal texture
uniform sampler2D GroundNormalTexture: hint_normal, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D GroundNormal2Texture: hint_normal, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform float NormalD = 1.0;

// Custom offset for camera movement
uniform vec2 offset;
uniform vec2 Scale1;
uniform vec2 Scale2;

void fragment() {
    // Scale the UVs for the main textures
    vec2 uv1 = (UV + offset) * Scale1;
	vec2 uv2 = (UV + offset) * Scale2;
	vec2 uvnoise = UV + offset;
    // Sample noise texture
	//float t = abs(1.0 - texture(GroundTextureMask, uv).r) * 5.0;
	
	//float texColormask = clamp(t, 0.0, 1.0);
    float patternNoise = texture(NoiseTexture, uvnoise).r; // Sample red channel for noise; adjust scale as needed
	
    // Normalize noise to [0, 1] if necessary
    // patternNoise = (patternNoise + 1.0) / 2.0; // Uncomment if your noise texture has values in range [-1, 1]
	
    // Sample colors from the textures
    vec4 texColor1 = texture(GroundTexture, uv1);
    vec4 texColor2 = texture(GroundTexture2, uv2);
	
	vec3 texNormal1 = texture(GroundNormalTexture, uv1).rgb;
	vec3 texNormal2 = clamp(texture(GroundNormal2Texture, uv2).rgb * patternNoise, vec3(0,0,0), vec3(1.0,1.0,1.0));
    // Blend colors based on sampled noise
    COLOR = mix(texColor1, texColor2, patternNoise);
	//COLOR = t;
	NORMAL_MAP = mix(texNormal1, texNormal2, patternNoise);

    NORMAL_MAP_DEPTH = NormalD;
}