// Mejora visual: hojas gigantes del techo de la zona de sombra, vistas desde abajo con el sol detrás: verde translúcido, con nervaduras.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec3 backlit : source_color = vec3(0.34, 0.72, 0.36);
uniform vec3 deep : source_color = vec3(0.1, 0.34, 0.24);

void fragment() {
	float vein = 0.5 + 0.5 * sin(UV.x * 40.0);
	ALBEDO = mix(deep, backlit, clamp(COLOR.g * 2.2, 0.0, 1.0)) * mix(0.9, 1.06, vein);
}
