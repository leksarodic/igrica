shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.28, 0.42, 0.44, 0.72);
uniform vec4 deep_color : source_color = vec4(0.11, 0.20, 0.23, 0.88);
uniform float wave_height : hint_range(0.0, 0.2) = 0.045;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.7;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world_pos.x * 0.7 + TIME * wave_speed) * wave_height;
	VERTEX.y += cos(world_pos.z * 0.5 + TIME * wave_speed * 0.8) * wave_height * 0.6;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	vec3 c = mix(deep_color.rgb, shallow_color.rgb, 0.55 + 0.25 * fresnel);
	ALBEDO = c;
	ROUGHNESS = 0.10;
	METALLIC = 0.18;
	ALPHA = mix(deep_color.a, shallow_color.a, 0.5);
	EMISSION = c * 0.05;
	SPECULAR = 0.7;
}
