shader_type spatial;
render_mode unshaded, blend_mul;

uniform sampler2D depth_texture : hint_depth_texture;

uniform float hole_depth : hint_range(0.1, 10.0, 0.1) = 1.0;

void fragment() {
	// sample our depth buffer
	float depth = texture(depth_texture, SCREEN_UV).r;
	
	float linear_depth = 1.0 / (depth * INV_PROJECTION_MATRIX[2].w + INV_PROJECTION_MATRIX[3].w);
	
	linear_depth = linear_depth + VERTEX.z;
	
	ALBEDO = vec3(clamp(1.-(linear_depth / hole_depth), 0., 1.));
}
