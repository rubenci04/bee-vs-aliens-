// Style C thin dark outline (inverted hull, used as next_pass). The offset is applied in clip
// space, so the line has the same on-screen thickness whatever the scale of the imported model
// or its skeleton (some models carry large armature scales).
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.035, 0.022, 0.015, 1.0);
uniform float width = 0.0025; // Fraction of screen height (about 1.3 px at 1080p).

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 view_normal = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	vec2 direction = normalize(view_normal.xy + vec2(0.00001));
	clip.xy += direction * vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0) * width * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
