shader_type canvas_item;


// Noise texture
uniform sampler2D GroundTexture: repeat_enable, filter_nearest;
uniform sampler2D GroundNormalTexture: hint_normal, filter_nearest, repeat_enable;
// Custom offset for camera movement
uniform vec2 offset;
uniform vec2 Scale;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a)*(1.0 - u.y) + (d - b)*u.x*u.y;
}

void fragment() {
    vec2 uv = (UV + offset) * Scale;
    float patternNoise = noise(uv * 5.0); // Adjust scale

    vec4 texColor1 = texture(GroundTexture, uv);
    vec4 texColor2 = texture(GroundTexture, uv + vec2(0.05, 0.05)); // Offset texture

    COLOR = mix(texColor1, texColor2, patternNoise); // Blend based on noise

    vec4 normalTex = texture(GroundNormalTexture, uv);
    NORMAL_MAP = normalTex.xyz;
    NORMAL_MAP_DEPTH = normalTex.x;
}
