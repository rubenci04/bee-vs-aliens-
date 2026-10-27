extends RefCounted
## T3m: one charge, no stored heals or extra Novas.
const ACTION := &"bee_pollen_nova"
const CARTRIDGE_COST := 7
const MAX_CARTRIDGES := 3
const CHARGE := CARTRIDGE_COST * MAX_CARTRIDGES
const HEAL_AMOUNT := 25 # E1: one press = heal 25 HP (25 % of 100) + shield
const HEAL_FRACTION := 0.25
const SHIELD_SECONDS := 2.5
const SHIELD_WARN_SECONDS := 0.4
const SHIELD_RADIUS := 0.95
const HEAL_GLOW_SECONDS := 0.5
const READY_BANNER_SECONDS := 3.0
const BASE_HITS := 3
const COMMON_DAMAGE := BASE_HITS * preload("res://scripts/game/bee_shooting_settings.gd").WEAPON_MODES[&"base"]["damage"][0]
const BOSS_DAMAGE := 6
const RADIUS := 3.5
const WAVE_SECONDS := 0.4
const INVULNERABILITY_SECONDS := SHIELD_SECONDS
const COOLDOWN_SECONDS := 3.0
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

const HINT_LABEL := "CURAR + ESCUDO"
const READY_TEXT := "Escudo y Cura de polen listos: "

static func button_hint() -> String:
	return "LT/L2" if BeeGameSettings.last_input_joypad else "Q"
