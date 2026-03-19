shader_type canvas_item;

uniform sampler2D t;
uniform float line_step = 0.1;
uniform vec3 low_color : source_color = vec3(0);
uniform vec3 high_color : source_color = vec3(1);
uniform float line_width = 1.0;
uniform vec4 line_color : source_color = vec4(1.0);

void fragment() {
    float height = texture(t, UV).r;
    
    // Mod pixel height into a single line's range
    float dist = mod(height, line_step);
    
    // Center line over threshold
    float fract_dist = min(dist, line_step - dist);
    
    // Dude, just trust the process.
    float delta = fwidth(height);
    delta = clamp(delta, 0.0001, 0.01);
    // Scale the thickness by the local gradient (delta)
    float line = smoothstep(line_width * delta, 0.0, fract_dist);
   
    vec3 c = mix(low_color, high_color, floor( height /line_step)*line_step );
	COLOR.rgb = mix(c, line_color.rgb, line * line_color.a);
}

