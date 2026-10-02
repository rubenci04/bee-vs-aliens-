// BEE STYLE TEST 01 - style C thin dark outline (inverted hull, used as next_pass).
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.035, 0.022, 0.015, 1.0);
uniform float width = 0.007; // Metres; about 2-3 px at preset D on 1080p.

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
