shader_type spatial;

render_mode world_vertex_coords;

uniform sampler2D GroundTexture: repeat_enable, filter_nearest_mipmap;
//uniform sampler2D GroundTextureMask: repeat_enable, filter_nearest_mipmap_anisotropic;
uniform sampler2D GroundTexture2: repeat_enable, filter_nearest_mipmap;
uniform sampler2D GroundTexture3: repeat_enable, filter_nearest_mipmap;

// Noise texture
uniform sampler2D NoiseTexture: repeat_enable, filter_linear_mipmap;  // Add noise texture
// Normal texture
uniform sampler2D GroundNormalTexture: hint_normal, filter_nearest_mipmap, repeat_enable;
uniform sampler2D GroundNormal2Texture: hint_normal, filter_nearest_mipmap, repeat_enable;
uniform sampler2D GroundNormal3Texture: hint_normal, filter_nearest_mipmap, repeat_enable;

uniform sampler2D heightMap : filter_nearest;
uniform vec2 H = vec2(1.0,1.0);
uniform float Light = 1.0;
uniform vec2 offset;
uniform vec2 NoiseScale;
uniform vec2 Scale1;
uniform vec2 Scale2;
uniform vec2 Scale3;

varying vec2 wUv;
varying float height ;

void vertex() {
	wUv = vec2(VERTEX.x, VERTEX.z) * NoiseScale + offset;
	height = texture(heightMap, wUv).r * H.x;
	VERTEX.y = height;
}

void fragment() {
	vec2 uv = wUv;
	// Scale the UVs for the main textures
	vec2 uv1 = uv * Scale1;
	vec2 uv2 = uv * Scale2;
	vec2 uv3 = uv * Scale3;
	vec2 uvnoise = uv;
	// Sample noise texture
	//float t = abs(1.0 - texture(GroundTextureMask, uv).r) * 5.0;

	//float texColormask = clamp(t, 0.0, 1.0);
	vec3 patternNoise = texture(NoiseTexture, uvnoise).rgb; // Sample red channel for noise; adjust scale as needed

	// Normalize noise to [0, 1] if necessary
	// patternNoise = (patternNoise + 1.0) / 2.0; // Uncomment if your noise texture has values in range [-1, 1]

	// Sample colors from the textures
	vec4 texColor1 = textureLod(GroundTexture, uv1, height);
	vec4 texColor2 = textureLod(GroundTexture2, uv2, height);
	vec4 texColor3 = textureLod(GroundTexture3, uv3, height);

	vec3 texNormal1 = textureLod(GroundNormalTexture, uv1, height).rgb;
	vec3 texNormal2 = textureLod(GroundNormal2Texture, uv2, height).rgb;
	vec3 texNormal3 = textureLod(GroundNormal3Texture, uv3, height).rgb;
	//texNormal1.b = clamp(texNormal1.b + patternNoise, 0, 1);
	//texNormal2.b = clamp(texNormal2.b + patternNoise, 0, 1);
	// Blend colors based on sampled noise
	vec4 fincol = mix(texColor1, texColor2, patternNoise.g);
	fincol = mix(fincol, texColor3, patternNoise.b);
	
	vec3 finNorm = mix(texNormal1, texNormal2, patternNoise.g);
	finNorm = mix(finNorm, texNormal3, patternNoise.b);
	
	ALBEDO.rgb = fincol.rgb;
	ALBEDO.rgb *= Light * height;
	//COLOR = t;
	NORMAL_MAP = finNorm;
	//NORMAL_MAP += texture(NoiseTexture3, uv1).rgb;
	//NORMAL_MAP_DEPTH = NormalD;
	
}
