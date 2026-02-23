shader_type canvas_item;

// Rectangle 1
uniform vec2 rect1_pos = vec2(0.25, 0.25);
uniform vec2 rect1_size = vec2(0.3, 0.4);

// Rectangle 2
uniform vec2 rect2_pos = vec2(0.55, 0.5);
uniform vec2 rect2_size = vec2(0.3, 0.3);

// Darkening strength
uniform float darkness : hint_range(0.0, 1.0) = 0.7;

// Feather/fade thickness
uniform float feather : hint_range(0.0, 0.3) = 0.05;

// Helper function for per-rectangle fade calculation
float rect_fade(vec2 uv, vec2 rect_pos, vec2 rect_size) {
    vec2 rect_min = rect_pos;
    vec2 rect_max = rect_pos + rect_size;
    vec2 d = max(rect_min - uv, uv - rect_max);
    float dist = max(d.x, d.y);
    return 1.0 - smoothstep(0.0, feather, dist);
}

void fragment() {
    vec2 uv = UV;

    // Fade for rectangle 1
    float fade1 = rect_fade(uv, rect1_pos, rect1_size);

    // Fade for rectangle 2
    float fade2 = rect_fade(uv, rect2_pos, rect2_size);

    // Use the stronger fade (so a pixel in either rect is fully visible)
    float fade = max(fade1, fade2);

    // Get base color
    vec4 base_color = vec4(0,0,0,0);

    // Mix with dark based on 'darkness'
    vec4 darkened = mix(base_color, vec4(0, 0, 0, darkness), 1);

    // Fade: 1 = fully visible inside one or both rects, 0 = dark outside both, in between at soft borders
    COLOR = mix(darkened, base_color, fade);
}