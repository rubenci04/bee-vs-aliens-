// Style C body for cloth (Giant Human jeans / sneakers): the usual bands and rim plus a subtle fabric value change
// along the garment (darker at the hem, faded higher up). No texture: a smooth gradient that does not swim.
shader_type spatial;
render_mode specular_disabled;

#define TOON_FABRIC
varying float fabric_y;

void vertex() {
	fabric_y = VERTEX.y;
}

#include "res://assets/style/toon_common.gdshaderinc"
