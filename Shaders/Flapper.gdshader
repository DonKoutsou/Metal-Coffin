shader_type canvas_item;

uniform float y_rot : hint_range(-360.0, 360.0) = 0.0;
uniform float x_rot : hint_range(-360.0, 360.0) = 0.0;
uniform vec3 Col : source_color;

varying flat vec2 o;
varying vec3 p;

// Creates rotation matrix
void vertex() {
    float sin_b = sin(y_rot / 180.0 * PI);
    float cos_b = cos(y_rot / 180.0 * PI);
    float sin_c = sin(x_rot / 180.0 * PI);
    float cos_c = cos(x_rot / 180.0 * PI);
    
    mat3 inv_rot_mat;
    inv_rot_mat[0][0] = cos_b;
    inv_rot_mat[0][1] = 0.0;
    inv_rot_mat[0][2] = -sin_b;
    
    inv_rot_mat[1][0] = sin_b * sin_c;
    inv_rot_mat[1][1] = cos_c;
    inv_rot_mat[1][2] = cos_b * sin_c;
    
    inv_rot_mat[2][0] = sin_b * cos_c;
    inv_rot_mat[2][1] = -sin_c;
    inv_rot_mat[2][2] = cos_b * cos_c;
    
    // Adjust the height to pivot from the top
    float height_adjust = 0.5;  // This assumes the height of the card is normalized to 1.0
    float t = tan(25.0 / 360.0 * PI);
    p = inv_rot_mat * vec3((UV - vec2(0.5, 0.0)), height_adjust / t);
    float v = (height_adjust / t) + 0.5;
    p.xy *= v * inv_rot_mat[2].z;
    o = v * inv_rot_mat[2].xy;

    // To adjust the vertex by the height
    VERTEX += (UV - vec2(0.5, 0.0)) / TEXTURE_PIXEL_SIZE * t;
    VERTEX.y -= height_adjust;  // Shift down by half the height to keep the top as pivot
}

void fragment() {
    vec2 uv = (p.xy / p.z).xy - o;
    COLOR = texture(TEXTURE, uv + 0.5);
    COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);
    
    //vec4 main_texture = texture(TEXTURE, uv + 0.5);
    //vec4 noise_texture = texture(dissolve_texture, uv + 0.5);
    //
    //// This is needed to avoid keeping a small burn_color dot with dissolve being 0 or 1
    //float burn_size_step = burn_size * step(0.001, dissolve_value) * step(dissolve_value, 0.999);
    //float threshold = smoothstep(noise_texture.x - burn_size_step, noise_texture.x, dissolve_value);
    //float border = smoothstep(noise_texture.x, noise_texture.x + burn_size_step, dissolve_value);
    //
    //COLOR.a *= threshold;
}