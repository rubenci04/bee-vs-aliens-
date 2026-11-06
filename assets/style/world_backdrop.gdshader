// Mejora visual: fondo lejano y "aire". Sin luz (no se le marcan las caras): solo una silueta que se funde con el color de la zona.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec3 haze : source_color = vec3(0.74, 0.87, 0.94);
uniform float haze_amount = 0.55;
uniform float light_top = 0.1; // La parte de arriba de cada pieza es un poco más clara.

varying float height;

void vertex() {
	height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	vec3 base = mix(COLOR.rgb, haze, haze_amount);
	ALBEDO = mix(base, base + vec3(light_top), clamp(height / 24.0, 0.0, 1.0));
}
