shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float LOD : hint_range(0.0, 3.0, 0.1);

void fragment() {
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, LOD);
}
