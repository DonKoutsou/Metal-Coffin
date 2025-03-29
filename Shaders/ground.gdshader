shader_type canvas_item;


// Noise texture
uniform sampler2D GroundTexture: repeat_enable, filter_nearest;
uniform sampler2D GroundNormalTexture: hint_normal, filter_nearest, repeat_enable;
// Custom offset for camera movement
uniform vec2 offset;
uniform vec2 Scale;

// Called for every pixel the material is visible on
void fragment() {
    // Combine UV, speed, time, and offset for the final texture coordinates
    vec2 uv = (UV + offset) * Scale;

	vec4 n_out4p0;
	// Texture2D:4
	n_out4p0 = texture(GroundNormalTexture, uv);
    // Apply the fog effect
    COLOR = texture(GroundTexture, uv);

	NORMAL_MAP = vec3(n_out4p0.xyz);
	NORMAL_MAP_DEPTH = n_out4p0.x;

}
