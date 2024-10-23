shader_type canvas_item;

//starfield customization
uniform float thing = 0.0; 
uniform float star_brightness : hint_range(0.0, 0.5) = 0.05; 

uniform float dist_fade : hint_range(0.0, 1.0) = 0.35; 

//this pixelation method might produce different results on screens of different resolutions
//keep it at 1000 to keep it off entirely
uniform int quantization_levels : hint_range(1, 256) = 256;

uniform float saturation : hint_range(0.0, 1.0) = 1; 
// turning the saturation to 0 will remove the space dust completely due to how the shader works.
// reccomend turning the color to white, then desaturating to about 0.1 to retain the space dust.

//if you turn the layers down below 7.0 you will need to adjust the distance fade to avoid pop-in
uniform float layers : hint_range(1.0, 9.0) = 7.0; 
//rec. not going over 12
uniform int iterations : hint_range(1, 16) = 12;

//constants
const float formuparam2 = 0.79;
const float zoom = 2.0;
const float tile = 0.850;
const float stepsize = 0.29;

float triangle(float x, float a) { 
    return 2.0 * abs(3.0 * ((x / a) - floor((x / a) + 0.5))) - 1.0;
}

float field(in vec3 p) {    
    float strength = 7.0 + 0.03 * log(1.e-6 + fract(sin(TIME) * 373.11));
    float accum = 0.0;
    float prev = 0.0;
    float tw = 0.0;    

    for (int i = 0; i < 6; ++i) {
        float mag = dot(p, p);
        p = abs(p) / mag + vec3(-0.5, -0.8 + 0.1 * sin(-TIME * 0.1 + 2.0), -1.1 + 0.3 * cos(TIME * 0.3));
        float w = exp(-float(i) / 7.0);
        accum += w * exp(-strength * pow(abs(mag - prev), 2.3));
        tw += w;
        prev = mag;
    }
    return max(0.0, 5.0 * accum / tw - 0.7);
}

//color quantization
vec3 quantizeColor(vec3 color, int levels) {
    return floor(color * float(levels)) / float(levels);
}

void fragment() {
    vec2 uv2 = FRAGCOORD.xy / vec2(512);
	uv2.x += thing;
    vec2 uvs = uv2 * vec2(512) / 512.0;

    float time = TIME;
    float formuparam = formuparam2;

    vec2 uv = uvs;               
    float a_xz = 0.9;
    float a_yz = -0.6;
    float a_xy = 0.9;    
    
    mat2 rot_xz = mat2(vec2(cos(a_xz), sin(a_xz)), vec2(-sin(a_xz), cos(a_xz)));    
    mat2 rot_yz = mat2(vec2(cos(a_yz), sin(a_yz)), vec2(-sin(a_yz), cos(a_yz)));        
    mat2 rot_xy = mat2(vec2(cos(a_xy), sin(a_xy)), vec2(-sin(a_xy), cos(a_xy)));
    
    float v2 = 1.0;    
    vec3 dir = vec3(uv * zoom, 1.0); 
    vec3 from = vec3(0.0, 0.0, 0.0);

    from.x += cos(0.01 * time) + 0.001 * time;
    from.y += sin(0.01 * time) + 0.001 * time;
    from.z += 0.003 * time;    
    
    dir.xy *= rot_xy;
    vec3 forward = vec3(0.0, 0.0, 1.0); 
    forward.xy *= rot_xy;
    dir.xz *= rot_xz;
    forward.xz *= rot_xz;    
    dir.yz *= rot_yz;
    forward.yz *= rot_yz;
    
    from.xy *= -1.0 * rot_xy;
    from.xz *= rot_xz;
    from.yz *= rot_yz;

    float parallax = (time - 3311.0)  * 0.0 * 0.1;
    from += forward * parallax;
    float sampleShift = mod(parallax, stepsize);
     
    float zoffset = -sampleShift;
    sampleShift /= stepsize;

    float s = 0.24;
    float s3 = s + stepsize / 2.0;
    vec3 v = vec3(0.0);
    float t3 = 0.0;    
    for (float r = 0.0; r < layers; r++) {
        vec3 p2 = from + (s + zoffset) * dir;
        vec3 p3 = from + (s3 + zoffset) * dir;
        
        p2 = abs(vec3(tile) - mod(p2, vec3(tile * 2.0)));
        p3 = abs(vec3(tile) - mod(p3, vec3(tile * 2.0)));        
        t3 = field(p3);
        
        float pa, a = pa = 0.0;
        for (int i = 0; i < iterations; i++) {
            p2 = abs(p2) / dot(p2, p2) - formuparam;
            float D = abs(length(p2) - pa);
            a += i > 7 ? min(12.0, D) : D;
            pa = length(p2);
        }
        
        a *= a * a;
        float s1 = s + zoffset;
        float fade = pow(dist_fade, max(0.0, float(r) - sampleShift));
        v += fade;
        
        if (r == 0.0)
            fade *= (1.0 - sampleShift);
        if (r == layers - 1.0)
            fade *= sampleShift;

        float brightness = mix(0.4, 1.0, v2);
        vec3 starColor = brightness * vec3(1.8 * t3 * t3 * t3, 1.4 * t3 * t3, t3) * fade;

        v += vec3(s1, s1 * s1, s1 * s1 * s1 * s1) * a * star_brightness * fade;

        s += stepsize;
        s3 += stepsize;        
    }

    v = mix(vec3(length(v)), v, saturation);

    vec4 forCol2 = vec4(v * 0.01, 1.0);     
	
    vec3 finalColor = forCol2.rgb * saturation;
    finalColor = quantizeColor(finalColor, quantization_levels);
    COLOR = vec4(finalColor, 1.0);
}
