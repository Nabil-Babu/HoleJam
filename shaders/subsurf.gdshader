shader_type spatial;
render_mode blend_mix, depth_draw_always;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap_anisotropic;

group_uniforms Color;
uniform sampler2D albedo_texture : source_color; 
uniform vec3 color_tint : source_color = vec3(1.0);
uniform float color_shift_amount = 0.05;
uniform int color_selector: hint_range(0, 3, 1) = 0;
uniform sampler2D skin_mask_texture; 
uniform float color_coat : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float oilyness : hint_range(0.0, 2.0, 0.01) = 0.1;

group_uniforms Rim;
uniform float rim_amount : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float rim_shape : hint_range(0.1, 6.0, 0.01) = 2.5;
uniform vec3 rim_color : source_color = vec3(1.0);

group_uniforms Refraction;
uniform float refraction_strength : hint_range(-1.0, 1.0, 0.01) = 0.5;

group_uniforms Blur;
uniform float blur_amount: hint_range(0.1, 8.0) = 4.0;
uniform float roughness_affect : hint_range(0.0, 1.0, 0.01) = 0.0;

group_uniforms Roughness;
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform sampler2D roughness_texture;

float overlay(float base, float blend){
	float limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

void fragment() {
	vec2 uv = UV;
	uv.x += float(color_selector) * color_shift_amount;
	vec2 pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
	
	float fresnel = pow(clamp(1.0 - dot(NORMAL, VIEW),0.0, 1.0), 1.0);
	vec2 offset = vec2(NORMAL.x, -NORMAL.y) * fresnel;
	
	vec2 screen_uv = SCREEN_UV + offset * refraction_strength;
	
	float roughness_value = clamp(texture(roughness_texture, UV).r * roughness, 0.01, 1.0);
	
	float blur = mix(blur_amount, overlay(blur_amount, 1.0 - roughness_value), roughness_affect);
	vec3 glass = textureLod(screen_texture, screen_uv, blur).rgb;
	
	float coat_amount = pow(1.0 - color_coat, 1.0);
	
	
	vec3 final = color_tint * texture(albedo_texture, uv).xyz * mix(vec3(1.0), glass, coat_amount);
	final = mix(final, rim_color, pow(fresnel, rim_shape) * rim_amount);
	
	final -= vec3((sin(NORMAL.xy * 10.0) * 0.5 + 0.5) * (0.1 * oilyness), 0.0);
	
	float mask = texture(skin_mask_texture, uv).x;
	mask = step(mask,0.5);
	
	ALBEDO = final * vec3(1.0-mask) + texture(albedo_texture, uv).xyz * vec3(mask);
	
	EMISSION = ALBEDO * coat_amount;
	
	SPECULAR = 1.0;
	
	ROUGHNESS = roughness_value;
}