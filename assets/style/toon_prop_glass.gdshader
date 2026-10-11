shader_type spatial;
render_mode blend_mix, specular_disabled;
uniform vec4 albedo : source_color = vec4(0.34,0.52,0.27,0.38);
uniform float emission_energy = 0.0;
void fragment() {
	float facing = clamp(dot(NORMAL,VIEW),0.0,1.0);
	float edge = smoothstep(0.86,0.98,1.0-facing);
	// Silhouette edge in this pass: an opaque inverted hull would fill the bore.
	ALBEDO = mix(albedo.rgb,vec3(0.035,0.022,0.015),edge);
	ALPHA = mix(albedo.a,0.92,edge);
	ROUGHNESS = 0.8;
	float rim = pow(1.0-facing,3.0);
	EMISSION = albedo.rgb * rim * 0.18;
}
void light() {
	float ndl = dot(NORMAL,LIGHT)*ATTENUATION;
	float band = 0.55*smoothstep(0.0,0.03,ndl)+0.45*smoothstep(0.42,0.48,ndl);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * band;
}
