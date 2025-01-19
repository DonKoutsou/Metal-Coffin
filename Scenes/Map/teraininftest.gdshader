shader_type canvas_item;

uniform sampler2D my_texture ;
uniform vec2 texture_scale = vec2(1.0, 1.0);
uniform float zoom = 1.0;
uniform vec2 camera_position;

void fragment() {
    // Calculate world UVs using the camera position; these are in world space
    vec2 world_position = (FRAGCOORD.xy + camera_position) * texture_scale / zoom;

    // Apply wrapping to tile the texture
    vec2 world_uv = fract(world_position);

    // Sample the texture based on these adjusted coordinates
    vec4 tex_color = texture(my_texture, world_uv);

    // Output the pixel color
    COLOR = tex_color;
}