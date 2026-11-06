// Mejora visual: rayo de luz sobre el fondo. Aditivo, sin profundidad, suave en los bordes y con un temblor lento.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.95, 0.8);
uniform float strength = 0.2;
uniform float phase = 0.0;

void fragment() {
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	float along = smoothstep(0.0, 0.15, UV.y) * (1.0 - smoothstep(0.35, 1.0, UV.y));
	float breathe = 0.72 + 0.28 * sin(TIME * 0.35 + phase);
	ALBEDO = color;
	ALPHA = clamp(across * across * along * breathe * strength, 0.0, 1.0);
}
