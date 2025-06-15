shader_type canvas_item;

// Noise texture
uniform sampler2D noise_texture : repeat_enable, filter_nearest_mipmap;
// Fog density
uniform float density : hint_range(0.0, 3.0) = 0.25;
// Fog speed
uniform vec2 speed = vec2(0.02, 0.01);
// Custom offset for camera movement
uniform vec2 offset;
uniform float custom_time;

// Shadow settings
uniform vec2 shadow_offset = vec2(0.01, -0.01); // Shadow direction
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.3; // Shadow opacity
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Shadow tint

void fragment() {
    vec2 base_uv = UV + speed * TIME + offset;

    // === Shadow Layer ===
    vec2 shadow_uv = base_uv + shadow_offset;
    float shadow_noise = texture(noise_texture, shadow_uv).r * 2.0 - 1.0;
    float shadow_alpha = clamp(shadow_noise, 0.0, 1.0) * density * shadow_strength;

    vec4 shadow = shadow_color;
    shadow.a *= shadow_alpha;

    // === Main Cloud Layer ===
    float main_noise = texture(noise_texture, base_uv).r * 2.0 - 1.0;
    float main_alpha = clamp(main_noise, 0.0, 1.0) * density;

    vec4 cloud = vec4(1.0, 1.0, 1.0, main_alpha);

    // Blend shadow first, then overlay cloud
    vec4 final_color = mix(shadow, cloud, cloud.a);

    COLOR = final_color;
}
