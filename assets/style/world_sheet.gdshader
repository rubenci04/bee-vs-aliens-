// Mejora visual: hojas y pétalos finos del mundo (doble cara, color por vértice). Siempre reciben luz, de cualquier lado:
// una hoja vista de atrás no se pone negra. Más clara hacia la punta, igual que el pasto.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform float mid_band = 0.68;
uniform float band_softness = 0.04;

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = abs(dot(NORMAL, LIGHT));
	float lit = ATTENUATION * smoothstep(0.18 - band_softness, 0.18 + band_softness, ndl);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * (mid_band * ATTENUATION + (1.0 - mid_band) * lit);
}
