shader_type canvas_item;

// === TEXTURES ===
uniform sampler2D noise_texture : repeat_enable, filter_nearest_mipmap;
uniform sampler2D noise_texturenormal : repeat_enable, filter_nearest_mipmap;
// === CLOUD SETTINGS ===
uniform float density : hint_range(0.0, 3.0) = 0.25;
uniform vec2 speed = vec2(0.02, 0.01);
uniform vec2 offset;
uniform float custom_time;
uniform bool UseCustomTime;
uniform float NormalStr = 0.5;
// === SHADOW SETTINGS ===
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.15; // Subtle shadow
uniform float shadow_parallax_amount : hint_range(-1.0, 1.0) = 0.5;


void fragment() {
    // === CLOUD LAYER ===
	float T;
	if (UseCustomTime){
		T = custom_time;
	}
	else{
		T = TIME / 2.0;
	}
	vec2 screen_shadow_uv = SCREEN_UV  ;
	vec2 world_shadow_uv = (UV + speed * T + offset) ;
	vec2 shadow_uv = world_shadow_uv + (screen_shadow_uv - 0.5) * shadow_parallax_amount;
    
    float main_noise = texture(noise_texture, shadow_uv).r * 2.0 - 1.0;
	vec3 normal_noise = texture(noise_texturenormal, shadow_uv).rgb;
    float main_alpha = clamp(main_noise, 0.0, 1.0) * density;
    vec4 cloud = vec4(vec3(1.0,1.0,1.0), main_alpha);
	
    // === SHADOW LAYER (SCREEN-SPACE) ===
	vec2 cloud_uv = UV + speed * T + offset;
    float raw_shadow_noise = texture(noise_texture, cloud_uv).r;
    float shadow_noise = smoothstep(0.4, 0.7, raw_shadow_noise) * 2.0 - 1.0;
    float shadow_alpha = clamp(shadow_noise, 0.0, 1.0) * density * shadow_strength;
    vec4 shadow = vec4(vec3(0.0, 0.0, 0.0), shadow_alpha);
	
	normal_noise.b = clamp(normal_noise.b + shadow_noise, 0, 1);
    // === COMBINE SHADOW + CLOUD ===
    COLOR = mix(shadow, cloud, cloud.a);
	NORMAL_MAP = normal_noise;
	NORMAL_MAP_DEPTH = NormalStr;
}
