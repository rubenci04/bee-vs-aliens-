extends RefCounted
## T4e presentation only. Damage/aim/movement are not configured here.
const FLASH_SECONDS := 0.06
const FLASH_LOCKOUT := 0.20
const FLASH_COLOR := Color(1.0,0.96,0.86,0.55)
const OVERLAY_PRIORITY := 1
const OUTLINE_PRIORITY := 2
const TILT_KEY := KEY_U
const TILT_DEFAULT := true
const PITCH_DEGREES := 15.0
const BANK_DEGREES := 20.0
const TILT_SMOOTH_SECONDS := 0.12
static var tilt_enabled := TILT_DEFAULT
static var legacy_flash := false # Capture tool only; exports always start false.
