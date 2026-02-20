shader_type canvas_item;

render_mode unshaded;

uniform sampler2D NoiseTexture2: repeat_enable, filter_linear_mipmap;  // Add noise texture

// Custom offset for camera movement
uniform vec2 offset;
//uniform float col;
uniform float z = 0.5;

void fragment() {
	vec2 uv = (UV + offset) * z;
	//vec4 n = texture(NoiseTexture2, uv) * col;
	COLOR = texture(NoiseTexture2, uv);
	//COLOR.a = n.r;
	// Called for every pixel the material is visible on.
}
