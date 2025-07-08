shader_type canvas_item;

render_mode unshaded;

uniform vec4 grid_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Color of the grid lines
uniform float zoom_level : hint_range(0.0, 2.0) = 0.0; // Zoom level, 0 = 1km, 1 = 10km, 2 = 100km

// Declare the grid sizes as continuous float uniforms
uniform float grid_size_km_1 = 1.0; // Grid size for 1 km
uniform float grid_size_km_10 = 10.0; // Grid size for 10 km
uniform float grid_size_km_100 = 100.0; // Grid size for 100 km

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE; // Normalize coordinates
	uv /= zoom_level;
    // Determine grid size based on zoom level
    float grid_size;
    
    if (zoom_level > 1.0) {
        grid_size = grid_size_km_1; // Use 1 km size
    } else if (zoom_level > 0.5) {
        grid_size = grid_size_km_10; // Use 10 km size
    } else {
        grid_size = grid_size_km_100; // Use 100 km size
    }

    // Calculate the pixels per kilometer 
    float pixels_per_km = 1.0; // Adjust this value based on your display scaling

    // Translate km to pixels
    float dynamic_grid_size = grid_size * pixels_per_km;

    // Calculate grid lines
    float mod_x = mod(uv.x * SCREEN_PIXEL_SIZE.x, dynamic_grid_size);
    float mod_y = mod(uv.y * SCREEN_PIXEL_SIZE.y, dynamic_grid_size);

    // Create lines
    float line_x = step(1.0, mod_x) * step(1.0, dynamic_grid_size - mod_x);
    float line_y = step(1.0, mod_y) * step(1.0, dynamic_grid_size - mod_y);

    // Final color
    vec4 final_color = (line_x + line_y > 0.0) ? grid_color : vec4(0.0);
    final_color.a = 1.0; // Ensure it is opaque

    COLOR = mix(texture(TEXTURE, UV), final_color, final_color.a);
}
