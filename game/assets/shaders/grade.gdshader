shader_type canvas_item;
// A restrained grade: cool shadows, warm highlights, a little more separation,
// and a soft vignette. Everything can be reduced from Settings.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float saturation : hint_range(0.0, 1.5) = 1.08;
uniform float contrast : hint_range(0.7, 1.4) = 1.06;
uniform float vignette : hint_range(0.0, 1.0) = 0.28;
uniform vec3 warm : source_color = vec3(1.04, 1.0, 0.94);
uniform vec3 cool : source_color = vec3(0.94, 0.99, 1.04);

void fragment() {
	vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	c *= mix(cool, warm, smoothstep(0.15, 0.75, l));
	float d = distance(SCREEN_UV, vec2(0.5));
	c *= mix(1.0, smoothstep(0.92, 0.25, d), vignette);
	COLOR = vec4(clamp(c, vec3(0.0), vec3(1.0)), 1.0);
}
