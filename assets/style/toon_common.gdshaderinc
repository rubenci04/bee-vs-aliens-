// Shared body of the style C toon shader: 3 light bands (dark / mid / lit), soft rim, optional
// albedo texture and vertex colour (imported enemy models), emission kept for alien tech.
// GARDEN IDENTITY 04 compile-time variants (defined by the including shader, off everywhere else):
//   TOON_CUTOUT  alpha scissor from the albedo texture's alpha (leaves with holes keep their shape)
//   TOON_FABRIC  subtle value change along the garment's height (needs `varying float fabric_y`)
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_texture = false;
uniform bool use_vertex_color = false;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform float mid_band = 0.55; // Share of the sun the middle band receives.
uniform float band_softness = 0.03;
uniform vec4 rim_color : source_color = vec4(1.0, 0.93, 0.8, 1.0);
uniform float rim_strength = 0.3;
uniform float rim_power = 3.0;
#ifdef TOON_CUTOUT
uniform float alpha_scissor = 0.5;
#endif
#ifdef TOON_FABRIC
uniform float fabric_variation = 0.1; // Darker at fabric_low, slightly faded towards fabric_high (model units).
uniform float fabric_low = 0.0;
uniform float fabric_high = 1.0;
#endif

void fragment() {
	vec3 base = albedo.rgb;
	float alpha = albedo.a;
	if (use_texture) {
		vec4 texel = texture(albedo_tex, UV);
		base *= texel.rgb;
		alpha *= texel.a;
	}
	if (use_vertex_color) {
		base *= COLOR.rgb;
	}
#ifdef TOON_FABRIC
	base *= mix(1.0 - fabric_variation, 1.0 + fabric_variation * 0.5, smoothstep(fabric_low, fabric_high, fabric_y));
#endif
	ALBEDO = base;
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	EMISSION = emission.rgb * emission_energy + rim_color.rgb * base * rim * rim_strength;
#ifdef TOON_CUTOUT
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
#endif
}

void light() {
	float ndl = dot(NORMAL, LIGHT) * ATTENUATION;
	float level = mid_band * smoothstep(0.0, band_softness, ndl)
			+ (1.0 - mid_band) * smoothstep(0.45 - band_softness, 0.45 + band_softness, ndl);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * level;
}
