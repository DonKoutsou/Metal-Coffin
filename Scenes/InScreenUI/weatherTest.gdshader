shader_type canvas_item;

render_mode unshaded;

// Noise texture
uniform sampler2D NoiseTexture: repeat_enable, filter_linear_mipmap;  // Add noise texture

// Custom offset for camera movement
uniform vec2 offset;
uniform float ZOOM;
uniform vec2 AspectRatio;

void fragment() {
    // Scale the UVs for the main textures
    vec2 uv = (UV + offset) * ZOOM * AspectRatio;

    // Sample noise texture
	//float t = abs(1.0 - texture(GroundTextureMask, uv).r) * 5.0;

	//float texColormask = clamp(t, 0.0, 1.0);
    vec4 patternNoise = texture(NoiseTexture, uv); // Sample red channel for noise; adjust scale as needed

	COLOR = patternNoise;

}