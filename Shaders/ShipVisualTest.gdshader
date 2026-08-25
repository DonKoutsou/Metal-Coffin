shader_type canvas_item;

uniform float ShipSize : hint_range(0.001, 1.0) = 0.08;
//uniform float shadow_strength : hint_range(0.0, 1.0) = 0.15;
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

float uv_inside(vec2 uv) {
	vec2 a = step(vec2(0.0), uv);
	vec2 b = step(uv, vec2(1.0));
	return a.x * a.y * b.x * b.y;
}

vec4 sample_texture_no_extend(sampler2D tex, vec2 uv) {
	float m = uv_inside(uv);

	// Clamp only to avoid repeat-mode surprises.
	// The mask makes anything outside transparent.
	vec4 col = texture(tex, clamp(uv, vec2(0.0), vec2(1.0)));
	return col * m;
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

	vec4 Ship = sample_texture_no_extend(TEXTURE, shadow_uv);
	vec4 ShadowSource = sample_texture_no_extend(TEXTURE, base_uv);
	vec4 Shadow = vec4(0.0, 0.0, 0.0, ShadowSource.a * 0.5);

	COLOR = mix(Shadow, Ship, Ship.a);
}
