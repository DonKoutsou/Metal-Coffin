shader_type canvas_item;
//render_mode blend_disabled; // optional
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Noise texture
uniform sampler2D noise_texture: repeat_enable, filter_nearest_mipmap;
// Fog density
uniform float density: hint_range(0.0, 3.0) = 0.25;
// Fog speed
uniform vec2 speed = vec2(0.02, 0.01);
// Custom offset for camera movement
uniform vec2 offset;

uniform float custom_time;

// Called for every pixel the material is visible on
void fragment() {
    // Combine UV, speed, time, and offset for the final texture coordinates
    vec2 uv = UV + speed * TIME + offset;
    // Sample the noise texture
    float noise = texture(noise_texture, uv).r * 2.0 - 1.0;
    // Convert the noise from the (0.0, 1.0) range to the (-1.0, 1.0) range
    // and clamp it between 0.0 and 1.0 again
    //float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);
	
	vec4 color = vec4(cloud_color.rgb, noise * density);
    // Apply the fog effect
    COLOR = color;
	//NORMAL_MAP = vec3(0,0,fog * density);
}