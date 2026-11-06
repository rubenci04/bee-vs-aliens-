// Mejora visual: matas de pasto bajo (MultiMesh con color por instancia). Oscuro en la base y claro en la punta, se mecen con el viento.
shader_type spatial;
render_mode cull_disabled, specular_disabled, shadows_disabled;

uniform float wind_strength = 0.1;
uniform float wind_speed = 1.5;
uniform float mid_band = 0.62;

varying float tip;

void vertex() {
	tip = UV.y;
	vec3 base = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float wave = sin(TIME * wind_speed + base.x * 0.7 + base.z * 0.4) + sin(TIME * wind_speed * 1.9 + base.x * 1.6) * 0.4;
	VERTEX.x += wave * wind_strength * tip * tip;
}

void fragment() {
	ALBEDO = COLOR.rgb * mix(0.5, 1.2, tip);
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = abs(dot(NORMAL, LIGHT)) * ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * (mid_band + (1.0 - mid_band) * smoothstep(0.3, 0.34, ndl));
}
