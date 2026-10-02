// BEE STYLE TEST 01 - style C wings: semi-transparent membrane, fresnel edge and a light sheen.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.75, 0.85, 0.88, 1.0);
uniform float alpha = 0.4;
uniform vec4 sheen_color : source_color = vec4(1.0, 0.97, 0.88, 1.0);
uniform float sheen_strength = 0.35;

void fragment() {
	float edge = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	ALBEDO = tint.rgb;
	ALPHA = clamp(alpha + edge * 0.35, 0.0, 0.9);
	ROUGHNESS = 0.22;
	SPECULAR = 0.6;
	EMISSION = sheen_color.rgb * edge * sheen_strength;
}
