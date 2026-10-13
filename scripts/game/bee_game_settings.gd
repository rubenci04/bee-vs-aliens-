class_name BeeGameSettings
extends RefCounted
## NOCHE 01 · ETAPA 2 — session settings chosen on the title screen (no save system: they live while the game runs).
##   EASY   Bee takes EASY_DAMAGE_TAKEN x damage, Level 01 enemies (and the UFO) have EASY_ENEMY_HP x HP.
##   NORMAL exactly the tuned values.

const NORMAL := &"normal"
const EASY := &"easy"
const EASY_DAMAGE_TAKEN := 0.6
const EASY_ENEMY_HP := 0.75
## Lote 15: health measured against one BASE tap (10 damage), body hits.
const SMALL_ENEMY_HP := {"FlyCommon": 10, "FlyCloud": 10, "FlyGreen": 20, "Wasp": 20, "Ant": 20}
const SPREAD_DURATION_SEC := 20.0
const SPREAD_EXTEND_SEC := 10.0
const SPREAD_MAX_DURATION_SEC := 45.0
## Bee model can be changed live with set_bee_model_version().
static var BEE_MODEL_VERSION := "v02"
const BEE_VISUAL_SCALE := 1.0
const BEE_V01_VISUAL_SCALE := 1.2
const BEE_DEFAULT_AIM_DISTANCE := 10.0
const BEE_THRUSTERS_ENABLED := true
const BEE_THRUSTER_IDLE_INTENSITY := 0.12
const BEE_THRUSTER_MAX_INTENSITY := 0.90
const BEE_THRUSTER_BURST_SECONDS := 0.18
const BEE_THRUSTER_MAX_TILT_RADIANS := 0.14
const BEE_THRUSTER_PARTICLES := 18
const BEE_DRILL_ACTIVE_SECONDS := 0.24
const BEE_DRILL_SPIN_RATE := 5.0
const BEE_DRILL_TRAIL_PARTICLES := 18
const BEE_ROLL_ARMOR_FLASH_SECONDS := 0.16
const BEE_INVULNERABILITY_BLINK_HZ := 14.0
const BEE_ROLL_FLASH_GOLD := Color(1.0, 0.84, 0.46, 0.68)
const BEE_ROLL_FLASH_EMISSION := Color(0.72, 0.34, 0.06)
const BEE_THRUSTER_MIN_PARTICLE_SPEED := 0.25
const BEE_THRUSTER_MAX_PARTICLE_SPEED := 2.8
const BEE_THRUSTER_IDLE_SCALE := 0.45
const BEE_THRUSTER_FULL_SCALE := 1.3
const BEE_THRUSTER_PARTICLE_LIFETIME := 0.22
const BEE_THRUSTER_PARTICLE_RANDOMNESS := 0.18
const BEE_THRUSTER_PARTICLE_SPREAD_DEGREES := 9.0
const BEE_THRUSTER_IDLE_MAX_PARTICLE_SPEED := 0.65
const BEE_THRUSTER_ACCEL_PARTICLE_SPEED := 1.3
const BEE_THRUSTER_PARTICLE_SCALE_MIN := 0.035
const BEE_THRUSTER_PARTICLE_SCALE_MAX := 0.075
const BEE_THRUSTER_EMISSION_RADIUS := 0.018
const BEE_THRUSTER_COLOR_START := Color(1.0, 0.98, 0.68, 0.96)
const BEE_THRUSTER_COLOR_MID := Color(1.0, 0.58, 0.12, 0.78)
const BEE_THRUSTER_COLOR_END := Color(0.78, 0.16, 0.025, 0.0)
const BEE_THRUSTER_MESH_RADIUS := 0.045
const BEE_THRUSTER_MESH_HEIGHT := 0.09
const BEE_BLASTER_RECOIL_DISTANCE := 0.045
const BEE_BLASTER_RECOIL_IN_SECONDS := 0.035
const BEE_BLASTER_RECOIL_OUT_SECONDS := 0.075
const BEE_DRILL_TRAIL_LIFETIME := 0.20
const BEE_DRILL_TRAIL_RANDOMNESS := 0.35
const BEE_DRILL_TRAIL_SPREAD_DEGREES := 160.0
const BEE_DRILL_TRAIL_GRAVITY := 0.8
const BEE_DRILL_TRAIL_SPEED_MIN := 0.2
const BEE_DRILL_TRAIL_SPEED_MAX := 1.8
const BEE_DRILL_TRAIL_SCALE_MIN := 0.025
const BEE_DRILL_TRAIL_SCALE_MAX := 0.055
const BEE_DRILL_TRAIL_COLOR_START := Color(0.9, 0.94, 0.98, 0.92)
const BEE_DRILL_TRAIL_COLOR_END := Color(1.0, 0.68, 0.18, 0.0)
const BEE_DRILL_SHARD_RADIUS := 0.035
const BEE_DRILL_SHARD_HEIGHT := 0.07
const BEE_DRILL_SHARD_METALLIC := 0.78
const BEE_DRILL_SHARD_ROUGHNESS := 0.2
const BEE_ROLL_FLASH_EMISSION_STRENGTH := 0.35
const BEE_MUZZLE_FLASH_GOLD := Color(1.0, 0.9, 0.52)
const BEE_MUZZLE_FLASH_SIZE := Vector3(0.16, 0.06, 0.06)
const BEE_MUZZLE_SPREAD_FLASH_SIZE := Vector3(0.19, 0.105, 0.07)
const BEE_MELEE_VFX_DURATION := 0.18
const BEE_MELEE_VFX_COLOR := Color(1.0, 0.72, 0.2)
const BEE_MELEE_VFX_REACH := 0.3
const BEE_IMPACT_VFX_COLOR := Color(1.0, 0.7, 0.18)
const BEE_IMPACT_VFX_AMOUNT := 8
const BEE_IMPACT_VFX_REACH := 0.36
const BEE_SPARK_VFX_DURATION := 0.36
const BEE_SPARK_VFX_COLOR := Color(1.0, 0.72, 0.2)
const BEE_SPARK_VFX_AMOUNT := 14
const BEE_SPARK_VFX_MIN_REACH := 0.42
const BEE_GOLD := Color(1.0, 0.68, 0.18)
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


static func set_bee_model_version(version: String) -> bool:
	if version not in ["v01", "v02"]:
		return false
	BEE_MODEL_VERSION = version
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		for visual in tree.get_nodes_in_group("bee_visual_instances"):
			if is_instance_valid(visual) and visual.has_method("apply_model_version"):
				visual.call("apply_model_version", version)
	return true
