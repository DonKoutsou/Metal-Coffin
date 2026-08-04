shader_type canvas_item;

uniform float offset: hint_range(0.0, 20.0);

void fragment() {
	float lod = max(0.0, log2(max(offset, 1.0)));
	COLOR = textureLod(TEXTURE, UV, lod);
}
