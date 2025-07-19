shader_type canvas_item;

render_mode unshaded;

uniform sampler2D noise_texture; // Your noise texture
uniform sampler2D color_ramp; // Your gradient texture

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE; // Normalize coordinates
    float noise_value = texture(noise_texture, uv).r; // Get the noise value
    vec4 color = texture(color_ramp, vec2(noise_value, 0.0)); // Sample the color ramp
    COLOR = color;
}