class_name BeeGameSettings
extends RefCounted
## NOCHE 01 · ETAPA 2 — session settings chosen on the title screen (no save system: they live while the game runs).
##   EASY   Bee takes EASY_DAMAGE_TAKEN x damage, Level 01 enemies (and the UFO) have EASY_ENEMY_HP x HP.
##   NORMAL exactly the tuned values.

const NORMAL := &"normal"
const EASY := &"easy"
const EASY_DAMAGE_TAKEN := 0.6
const EASY_ENEMY_HP := 0.75
const TITLE_SCENE := "res://scenes/game/bee_title_screen.tscn"
const LEVEL_01 := "res://scenes/levels/bee_level_01_vertical_slice.tscn"
## Seconds on the "SECTOR DESPEJADO" screen before going back to the title (only when the level was started from it).
const RETURN_TO_TITLE_SECONDS := 8.0

static var difficulty: StringName = NORMAL
## True when Level 01 was opened from the title screen (tests and F6 open it directly: no automatic return).
static var from_title := false
## LOTE 11: camera shake (bomb, boss, damage taken). Title menu option; the shake code reads it, so it also covers the POCs.
static var screen_shake_enabled := true


static func damage_taken_scale() -> float:
	return EASY_DAMAGE_TAKEN if difficulty == EASY else 1.0


static func enemy_hp_scale() -> float:
	return EASY_ENEMY_HP if difficulty == EASY else 1.0


static func scaled_hp(base: int) -> int:
	return maxi(1, roundi(float(base) * enemy_hp_scale()))


static func shake_label() -> String:
	return "SÍ" if screen_shake_enabled else "NO"


static func label() -> String:
	return "FÁCIL" if difficulty == EASY else "NORMAL"


## LOTE 14 · ETAPA 4: pause-menu sliders (0..1). 1.0 = the default level of each bus (music -8 dB, effects -3 dB); see MusicManager.
static var music_volume := 1.0
static var sfx_volume := 1.0
