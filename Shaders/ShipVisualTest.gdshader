shader_type canvas_item;

uniform float ShipSize : hint_range(0.0, 1.0) = 0.15;
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.15;
uniform float shadow_parallax_amount : hint_range(0.0, 5.0) = 0.5;

// Must be set from GDScript with sprite's rotation (in radians)
uniform float sprite_rotation = 0.0;

vec2 rotate(vec2 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec2(
        v.x * c - v.y * s,
        v.x * s + v.y * c
    );
}

void fragment() {
    vec2 screen_uv = SCREEN_UV;

    // Scale UVs from center
    vec2 base_uv = (UV - 0.5) / ShipSize + 0.5;

    // Parallax offset in screen space (unrotated)e
    vec2 offset = (screen_uv - 0.5) * shadow_parallax_amount;

    // Rotate offset to follow sprite
    offset = rotate(offset, -sprite_rotation);

    vec2 shadow_uv = base_uv - offset;

    vec4 Ship = texture(TEXTURE, shadow_uv);
    vec4 Shadow = texture(TEXTURE, base_uv);
    Shadow.rgb *= 0.0;
	Shadow.a *= shadow_strength;

    COLOR = mix(Shadow, Ship, Ship.a);
}
