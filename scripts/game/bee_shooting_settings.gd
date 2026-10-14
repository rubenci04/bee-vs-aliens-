extends RefCounted
## Tanda 4a: all new shooting/aim/readability tuning lives here.
const FIRE_INTERVAL := 1.0 / 12.0 # 12 * 3 = 36 sustained DPS (+20%).
const SPREAD_FIRE_INTERVAL := FIRE_INTERVAL
# Existing modes only: triple is the Spread fan, double is Frenzy/honey.
# Integer damage: center + side pellets; DPS assumes every pellet connects.
const WEAPON_MODES := {
	&"base": {"interval": FIRE_INTERVAL, "speed": 14.0, "damage": [3]},
	&"double": {"interval": FIRE_INTERVAL, "speed": 14.0, "damage": [3, 1]},
	&"triple": {"interval": SPREAD_FIRE_INTERVAL, "speed": 14.0, "damage": [3, 1, 1]},
	&"triple_double": {"interval": SPREAD_FIRE_INTERVAL, "speed": 14.0, "damage": [3, 1, 1, 1]},
}
const SPREAD_ANGLE := 14.0
const DOUBLE_OFFSET := 0.14
const SHOT_VISUAL_LENGTH := 1.65
const SHOT_EMISSION := 3.0
const SHOT_TRAIL_SECONDS := 0.18
const SHOT_TRAIL_AMOUNT := 14
const MUZZLE_SECONDS := 0.055
const MUZZLE_SCALE := 1.2
const IMPACT_SPARK_SCALE := 0.18
const AIM_ASSIST_TARGET_MARKER := true
const TARGET_MARKER_OFFSET := Vector2(0, -16)
const TARGET_MARKER_RADIUS := 3.0
const TARGET_MARKER_OPACITY := 0.65
const AIM_ASSIST_ENABLED := true
const AIM_ASSIST_ANGLE := 12.0 # Half-angle from the intended direction.
const AIM_ASSIST_STRENGTH := 0.5
const AIM_ASSIST_RANGE := 12.0
const PLAYER_SHOT_HITBOX_SCALE := 1.25
const RETICLE_IDLE_OPACITY := 0.35
const RETICLE_ACTIVE_OPACITY := 0.85
const RETICLE_DISTANCE := 3.5
const RETICLE_RADIUS := 6.0
const RETICLE_WIDTH := 1.5
const RETICLE_SCREEN_MARGIN := 18.0
const AIM_DEBUG_DEFAULT := false
const AIM_DEBUG_KEY := KEY_F4
