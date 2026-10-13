// LOTE 11 · C4 — soft, out-of-focus grass blade for the foreground layers (unshaded, no depth write).
// Quad (UV 0..1, v=0 at the tip): width narrows towards the tip, the edge is feathered to fake the blur and the blade sways
// from its base. `fade` scales the whole alpha (the near layers are the faintest).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 blade_color : source_color = vec4(0.30, 0.42, 0.14, 1.0);
uniform float fade : hint_range(0.0, 1.0) = 0.3;
uniform float feather : hint_range(0.05, 1.0) = 0.55;
uniform float sway_amount = 0.12;
uniform float sway_speed = 1.1;
// LOTE 14: the blade fades out over the middle of the screen (half size, fractions of the screen, and feather) so it never covers the action.
uniform vec2 center_half = vec2(0.30, 0.34);
uniform float center_feather : hint_range(0.01, 0.5) = 0.10;

void vertex() {
	float tip = 1.0 - UV.y; // 0 at the base, 1 at the tip
	float phase = float(INSTANCE_ID) * 1.7;
	VERTEX.x += sin(TIME * sway_speed + phase) * sway_amount * tip * tip;
}

void fragment() {
	float tip = 1.0 - UV.y;
	float half_width = mix(0.5, 0.06, tip);
	float d = abs(UV.x - 0.5);
	float body = 1.0 - smoothstep(half_width * (1.0 - feather), half_width, d);
	float ends = smoothstep(0.0, 0.12, UV.y) * smoothstep(0.0, 0.08, 1.0 - UV.y);
	ALBEDO = blade_color.rgb;
	vec2 away = abs(SCREEN_UV - vec2(0.5, 0.5)) - center_half;
	float outside = smoothstep(0.0, center_feather, max(away.x, away.y));
	ALPHA = body * ends * fade * outside;
}
