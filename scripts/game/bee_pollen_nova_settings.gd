extends RefCounted
## T3m: one charge, no stored heals or extra Novas.
const ACTION := &"bee_pollen_nova"
const CARTRIDGE_COST := 7
const MAX_CARTRIDGES := 3
const CHARGE := CARTRIDGE_COST * MAX_CARTRIDGES
const HOLD_SECONDS := 0.5
const HEAL_FRACTION := 0.20
const HEAL_GLOW_SECONDS := 0.5
const READY_BANNER_SECONDS := 3.0
const BASE_HITS := 3
const COMMON_DAMAGE := BASE_HITS * preload("res://scripts/game/bee_shooting_settings.gd").WEAPON_MODES[&"base"]["damage"][0]
const BOSS_DAMAGE := 6
const RADIUS := 4.0
const WAVE_SECONDS := 0.4
const INVULNERABILITY_SECONDS := 0.3
const COOLDOWN_SECONDS := 1.0
const TRIGGER_THRESHOLD := 0.55
const WAVE_THICKNESS := 0.06
const WAVE_ALPHA := 0.65
const GLOW_RATE := 5.0
const GLOW_ALPHA := 0.3
const HINT_SIZE := Vector2(344, 26)
const HINT_GAP := 4.0
const HINT_TEXT_OFFSET := Vector2(8, 18)
const WAVE_RINGS := 48
const WAVE_SEGMENTS := 6

static func button_hint() -> String:
	return "LT/L2" if BeeGameSettings.last_input_joypad else "Q"
