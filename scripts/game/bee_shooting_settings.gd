extends RefCounted
## Tanda 4a: all new shooting/aim/readability tuning lives here.
const FIRE_INTERVAL := 1.0 / 7.5 # Same sustained Base DPS: 7.5 * 4 = 30.
const SPREAD_FIRE_INTERVAL := 0.4 # Existing five-pellet fan: 2.5 * 5 * 4 = 50.
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
