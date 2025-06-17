shader_type canvas_item;

uniform float ColorAmm: hint_range(8, 256, 1.0) = 1.;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

vec3 to_indexed_palette(vec3 color) {
    vec3 quant = floor(color * ColorAmm + 0.5) / ColorAmm;
    return quant;
}

void fragment(){
	COLOR.rgb = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	COLOR.rgb = to_indexed_palette(COLOR.rgb);

}
