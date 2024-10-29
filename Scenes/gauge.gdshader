shader_type canvas_item;

uniform vec4 indicator_color: source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 border_color: source_color = vec4(0.7, 0.7, 0.7, 1.0);
uniform vec4 centre_color: source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 region1_color: source_color = vec4(0.0, 1.0, 0.2, 1.0);
uniform vec4 region2_color: source_color = vec4(1.0, 0.8, 0.0, 1.0);
uniform vec4 region3_color: source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 scale_mark_color: source_color = vec4(0.9, 0.9, 0.9, 1.0);

uniform bool show_edges = false;
uniform float indicator_angle: hint_range(0.0, 1.0) = 0.0;
uniform float indicator_length: hint_range(0.1, 1.0) = 0.7;
uniform float indicator_width: hint_range(0.001, 0.02) = 0.015;
uniform float border_width: hint_range(0.0, 0.5) = 0.08;
uniform float centre_width: hint_range(0.0, 0.5) = 0.12;
uniform float region1: hint_range(0.0, 1.0) = 0.5;
uniform float region2: hint_range(0.0, 1.0) = 0.75;
uniform float region3: hint_range(0.0, 1.0) = 0.9;
uniform float regions_end: hint_range(0.0, 1.0) = 1.0;
uniform float scale_marks: hint_range(0.0, 20.0, 1.0) = 15.0;
uniform float major_scale_marks: hint_range(0.0, 20.0, 1.0) = 3.0;
uniform float scale_mark_width: hint_range(0.01, 0.05) = 0.02;
uniform float scale_minor_outer: hint_range(0.0, 1.0) = 0.75;
uniform float scale_major_outer: hint_range(0.0, 1.0) = 0.85;
uniform float scale_inner: hint_range(0.0, 1.0) = 0.65;

float greater_than(float x, float y) {
    return max(sign(x - y), 0.0);
}

void fragment() {
    vec2 uv = UV;
    uv = uv * 2.0 - 1.0;

    float angle = atan(uv.y, uv.x) / (2.0 * 3.14159265359) + 0.5; // Map from [0, 1]
    float radius = length(uv);

    // Color regions
    COLOR.rgb = mix(COLOR.rgb, region3_color.rgb, region3_color.a * (greater_than(angle, region3) * greater_than(regions_end, angle)));
    COLOR.rgb = mix(COLOR.rgb, region2_color.rgb, region2_color.a * (greater_than(angle, region2) * greater_than(region3, angle)));
    COLOR.rgb = mix(COLOR.rgb, region1_color.rgb, region1_color.a * (greater_than(angle, region1) * greater_than(region2, angle)));

    // Indicator coloring
    COLOR.rgb = mix(COLOR.rgb, indicator_color.rgb, indicator_color.a * greater_than(indicator_length, radius) * greater_than(indicator_width / radius, abs(indicator_angle - angle)));

    // Centre
    COLOR.rgb = mix(COLOR.rgb, centre_color.rgb, centre_color.a * greater_than(centre_width, radius));

    // Scale marks
    COLOR.rgb = mix(COLOR.rgb, scale_mark_color.rgb, scale_mark_color.a * greater_than(angle, 0.0 - scale_mark_width) * greater_than(1.0 + scale_mark_width, angle) * 
        greater_than(abs(mod(angle, 1.0 / scale_marks) * scale_marks * 2.0 - 1.0), 1.0 - (scale_mark_width / 2.0 / radius) * scale_marks) * 
        (greater_than(scale_minor_outer, radius) * greater_than(radius, scale_inner)));

    COLOR.rgb = mix(COLOR.rgb, scale_mark_color.rgb, scale_mark_color.a * greater_than(angle, 0.0 - scale_mark_width) * greater_than(1.0 + scale_mark_width, angle) * 
        greater_than(abs(mod(angle, 1.0 / major_scale_marks) * major_scale_marks * 2.0 - 1.0), 1.0 - (scale_mark_width / 2.0 / radius) * major_scale_marks) * 
        (greater_than(scale_major_outer, radius) * greater_than(radius, scale_minor_outer)));

    // Border
    COLOR.rgb = mix(COLOR.rgb, border_color.rgb, border_color.a * greater_than(radius, 1.0 - border_width));

    // Transparency on edges
    COLOR.a *= max(sign(1.0 - radius), float(show_edges));
}