// BEE STYLE TEST 01 - style C body: 3 light bands, soft rim, emission kept for alien tech.
shader_type spatial;
render_mode specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform float mid_band = 0.55; // Share of the sun the middle band receives.
uniform float band_softness = 0.03;
uniform vec4 rim_color : source_color = vec4(1.0, 0.93, 0.8, 1.0);
uniform float rim_strength = 0.3;
uniform float rim_power = 3.0;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	EMISSION = emission.rgb * emission_energy + rim_color.rgb * albedo.rgb * rim * rim_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT) * ATTENUATION;
	float level = mid_band * smoothstep(0.0, band_softness, ndl)
			+ (1.0 - mid_band) * smoothstep(0.45 - band_softness, 0.45 + band_softness, ndl);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * level;
}
