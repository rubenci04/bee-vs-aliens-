// Style C body for alpha-cut foliage (leaves with holes in their texture): double sided, alpha scissor, no outline.
shader_type spatial;
render_mode specular_disabled, cull_disabled;

#define TOON_CUTOUT
#include "res://assets/style/toon_common.gdshaderinc"
