// Tanda S: Style C body made translucent (uniform fade) while a scenery piece hides Bee or an enemy. Double sided, no depth write.
shader_type spatial;
render_mode specular_disabled, cull_disabled, blend_mix, depth_draw_never;

#define TOON_FADE
#include "res://assets/style/toon_common.gdshaderinc"
