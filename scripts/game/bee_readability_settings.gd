extends RefCounted
## Development comparison only. Production exports never enable this panel.
const ENABLED := true
const BEE_SCALES := [1.0, 1.25, 1.4]
const DEFAULT_BEE := 1
const DEFAULT_OUTLINE := 1
const DEFAULT_BACKGROUND := 1
const DEFAULT_NEON := 1
const OUTLINE_PIXELS := [0.0, 1.2, 2.8]
const OUTLINE_COLOR := Color(0.035, 0.025, 0.035)
const BACKGROUND_SATURATION := [1.0, 0.65, 0.35]
const BACKGROUND_CONTRAST := [1.0, 0.90, 0.80]
const BACKGROUND_MIN_DEPTH := -18.0
const NEON_ENERGY := [1.0, 2.4, 3.6]
const NEON_VISUAL_SCALE := [1.0, 1.0, 1.3]
const BLOOM_GAIN := [0.0, 0.40, 0.65]
const BLOOM_RADIUS := [0.0, 2.5, 3.5]
const BLOOM_RESOLUTION_DIVISOR := 2
const BLOOM_LAYER := 1 << 19
const PANEL_FONT_SIZE := 16
const PANEL_POSITION := Vector2(18, -30)
const REFRESH_INTERVAL := 0.10
const KEYS := [KEY_F5, KEY_F6, KEY_F7, KEY_F8]

static func development_enabled() -> bool:
	return ENABLED and OS.is_debug_build() and (OS.has_feature("editor") or "--debug-readability" in OS.get_cmdline_user_args())
