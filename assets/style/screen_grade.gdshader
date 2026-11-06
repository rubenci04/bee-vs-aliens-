// Mejora visual: viñeta suave de pantalla. Lleva el ojo al centro y oscurece un poco los bordes según la zona.
shader_type canvas_item;

uniform float vignette = 0.18;
uniform vec3 vignette_color : source_color = vec3(0.02, 0.02, 0.06);

void fragment() {
	vec2 centered = (UV - 0.5) * vec2(1.0, 0.82);
	float edge = smoothstep(0.34, 0.78, length(centered));
	COLOR = vec4(vignette_color, edge * vignette);
}
