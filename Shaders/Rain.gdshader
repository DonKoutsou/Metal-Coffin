shader_type canvas_item;
render_mode unshaded;

#define iResolution 1.0/SCREEN_PIXEL_SIZE
#define iTime TIME * 0.3
#define fragColor COLOR

uniform sampler2D iChannel0 : hint_screen_texture;
uniform float frequency : hint_range(-10.0, 4.0, 0.1) = 0.0;
uniform float size : hint_range(0.001, 0.05, 0.001) = 0.015;
uniform float refraction_strength : hint_range(0.0, 1.0, 0.01) = 0.3; // <--- NEW UNIFORM

vec2 rand(vec2 c) {
    mat2 m = mat2(vec2(12.9898,.16180),vec2(78.233,.31415));
    return fract(sin(m * c) * vec2(43758.5453, 14142.1));
}

vec2 noise(vec2 p) {
    vec2 co = floor(p);
    vec2 mu = fract(p);
    mu = 3.*mu*mu-2.*mu*mu*mu;
    vec2 a = rand((co+vec2(0.,0.)));
    vec2 b = rand((co+vec2(1.,0.)));
    vec2 c = rand((co+vec2(0.,1.)));
    vec2 d = rand((co+vec2(1.,1.)));
    return mix(mix(a, b, mu.x), mix(c, d, mu.x), mu.y);
}

void fragment() {
    vec2 u = SCREEN_UV,
         v = SCREEN_UV * 0.1,
         n = noise(v*200.); // Displacement

    fragColor = textureLod(iChannel0, u, 2.5);

    for (float r = 4. ; r > frequency ; r--) {
        vec2 x = iResolution.xy * r * size;
        vec2 p = 6.28 * u * x + (n - .5) * 2.;
        vec2 s = sin(p);

        vec2 v = round(u * x - 0.25) / x;
        vec4 d = vec4(noise(v*200.), noise(v));

        float t = (s.x+s.y) * max(0., 1. - fract(iTime * (d.b + .1) + d.g) * 2.);;

        if (d.r < (5.-r)*.08 && t > .5) {
            vec3 v = normalize(-vec3(cos(p), mix(.2, 2., t-.5)));
            fragColor = texture(iChannel0, u - v.xy * refraction_strength); // <--- Here we use the uniform
        }
    }
}