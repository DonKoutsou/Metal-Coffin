shader_type canvas_item;
render_mode unshaded;

uniform float angle : hint_range(0.0, 180.0) = 60.0; // Cone angle in degrees
uniform float range = 1.0; // Maximum reach of the cone, as a normalized value
uniform vec2 cone_origin = vec2(0.5, 0.5); // Center of the cone in normalized coordinates
uniform float edge_softness : hint_range(0.0, 1.0) = 0.1; // Soft edges
uniform float boundary_thickness : hint_range(0.0, 1.0) = 0.05; // Thickness of the boundary edges
uniform vec4 cone_color : source_color = vec4(1.0, 0.7, 0.3, 1.0); // Cone color

void fragment() {
    // Calculate vector from cone_origin to the current fragment
    vec2 frag_vec = (UV - cone_origin);
    float distance = length(frag_vec);

    // Normalize the frag_vec for angle calculation
    vec2 norm_vec = normalize(frag_vec);

    // Cone apex direction (right)
    vec2 cone_dir = vec2(1.0, 0.0);

    // Angle between cone direction and fragment
    float cos_angle = dot(cone_dir, norm_vec);
    float angle_in_cone = degrees(acos(cos_angle));

    // Calculate the radius at the current angle of view
    float current_radius = distance / max(range, 0.001);

    // Boundary limits
    float outer_limit = 1.0;
    float inner_limit = outer_limit - boundary_thickness;

    // Check if within the cone's angle and within the boundary thickness
    if (angle_in_cone <= angle / 2.0 && current_radius <= outer_limit && current_radius >= inner_limit) {
        // Calculate edge blend factor
        float angle_blend = smoothstep(angle / 2.0, angle / 2.0 - edge_softness * 90.0, angle_in_cone);
        float edge_blend = smoothstep(inner_limit, outer_limit, current_radius);

        // Combine blends for smooth edges
        float blend = angle_blend * (1.0 - edge_blend);

        // Output the final color with blending
        COLOR = vec4(cone_color.rgb, cone_color.a * blend);
    } else {
        // Outside cone boundaries
        discard;
    }
}