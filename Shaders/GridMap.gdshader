shader_type canvas_item;

uniform vec2 grid_size = vec2(50.0, 50.0); // Base size of each grid cell
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Color of the grid lines
uniform float line_thickness = 1.0; // Thickness of the grid lines
uniform float zoom = 1.0; // Zoom factor
uniform vec2 pan_offset = vec2(0.0, 0.0); // Pan offset
uniform vec2 view_size = vec2(100.0, 100.0); // Size of the view in pixels

void fragment() {
    // Calculate center-based offset due to zoom
    vec2 center_offset = (view_size * (1.0 - zoom)) / 2.0;

    // Adjust the grid size based on zoom
    vec2 effective_grid_size = grid_size * zoom;

    // Calculate position with pan and zoom centered around the view's center
    vec2 adjusted_coord = (FRAGCOORD.xy + pan_offset - center_offset) / effective_grid_size;

    // Determine the position within the grid cell
    vec2 pos = floor(adjusted_coord);

    // Calculate the distance to the nearest grid line
    float line_x = abs(mod(adjusted_coord.x, 1.0) - 0.5);
    float line_y = abs(mod(adjusted_coord.y, 1.0) - 0.5);

    // Determine if the current fragment is within the line_thickness range
    if (line_x < (line_thickness / effective_grid_size.x) || line_y < (line_thickness / effective_grid_size.y)) {
        COLOR = line_color;
    } else {
        discard; // Discard the fragment if it's not part of the grid line
    }
}