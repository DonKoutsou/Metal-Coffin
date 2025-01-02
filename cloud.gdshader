shader_type canvas_item;
render_mode unshaded;
uniform float cloud_speed : hint_range(0.0, 10.0) = 1.0;
uniform float cloud_density : hint_range(0.0, 1.0) = 0.5;
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D Noise;
uniform vec2 cloud_scale = vec2(5.0, 5.0);
// Define a uniform to pass an array of vec2 positions
uniform vec2 hole_positions[10];
uniform float hole_radius = 0.05;  // Adjust size as needed
uniform int hole_count;
float permute(float x) {
    return fract((34.0 * x + 1.0) * x);
}
bool is_within_hole(vec2 uv) {
    for (int i = 0; i < hole_count; ++i) {
        if (distance(uv, hole_positions[i]) < hole_radius) {
            return true;
        }
    }
    return false;
}
void fragment() {
    vec2 uv = UV * cloud_scale;
    //uv.x += TIME * cloud_speed;

    float n = texture(Noise, uv).x;
    n = smoothstep(cloud_density, 1.0, n);

	// If the current UV is within a hole, set n (density) to 0
    if (is_within_hole(uv)) {
        n = 0.0;
    }

    vec4 color = vec4(cloud_color.rgb * n, n * cloud_color.a);
    COLOR = color;
}
