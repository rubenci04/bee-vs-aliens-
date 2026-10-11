// Standalone Compatibility water visual, opaque and without screen texture.
// Natural green water and warm reflections; no cyan/violet emission.
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 deep_color : source_color = vec4(0.14, 0.28, 0.23, 1.0);
uniform vec4 surface_color : source_color = vec4(0.39, 0.51, 0.35, 1.0);
uniform vec4 reflection_color : source_color = vec4(0.72, 0.73, 0.52, 1.0);
uniform float time_offset = 0.0;
void fragment() {
	float t = TIME + time_offset;
	float wave = sin(UV.x * 45.0 + sin(UV.y * 22.0) * 1.5 + t * 0.5);
	float streak = smoothstep(0.97, 0.998, wave) * smoothstep(0.25, 1.0, UV.y);
	ALBEDO = mix(deep_color.rgb, surface_color.rgb, UV.y * 0.65);
	ALBEDO = mix(ALBEDO, reflection_color.rgb, streak * 0.48);
}
