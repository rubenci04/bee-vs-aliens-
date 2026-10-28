class_name BeeGameSettings
extends RefCounted
## NOCHE 01 · ETAPA 2 — session settings chosen on the title screen (no save system: they live while the game runs).
##   EASY   Bee takes EASY_DAMAGE_TAKEN x damage, Level 01 enemies (and the UFO) have EASY_ENEMY_HP x HP.
##   NORMAL exactly the tuned values.

const NORMAL := &"normal"
const EASY := &"easy"
const EASY_DAMAGE_TAKEN := 0.6
const EASY_ENEMY_HP := 0.75
## Keep the existing five companion families; HP come from the T6a table.
const ENEMY_HEALTH := preload("res://scripts/game/bee_enemy_health_settings.gd")
const SMALL_ENEMY_HP := {"FlyCommon": ENEMY_HEALTH.COMMON_HP["FlyCommon"], "FlyCloud": ENEMY_HEALTH.COMMON_HP["FlyCloud"],
	"FlyGreen": ENEMY_HEALTH.COMMON_HP["FlyGreen"], "Wasp": ENEMY_HEALTH.COMMON_HP["Wasp"], "Ant": ENEMY_HEALTH.COMMON_HP["Ant"]}
## Sustained BASE pellets keep the same hit count on small fauna; other targets retain the existing burst DPS.
const SMALL_ENEMY_BASE_HIT_DAMAGE := 10
const SPREAD_DURATION_SEC := 20.0
const SPREAD_EXTEND_SEC := 10.0
const SPREAD_MAX_DURATION_SEC := 45.0
const SHOT_WARNING_SECONDS := 0.35
static var SHOT_WARNING_VISUAL_ENABLED := true
static var SHOT_WARNING_AUDIO_ENABLED := true
static var SHOT_WARNING_EDGE_ENABLED := true
const SHOT_WARNING_SOUND_SECONDS := 0.12
const SHOT_WARNING_SOUND_GAP_SEC := 0.15
const SHOT_WARNING_SOUND_DB := -9.0
const SHOT_WARNING_PITCH := {&"wasp": 1.3, &"ant": 0.8, &"fly_green": 1.6, &"mushroom": 0.65, &"spider": 1.1, &"worm": 0.9}
const SHOT_WARNING_SWELL := 0.18
const SHOT_WARNING_TILT := 0.18
const SHOT_WARNING_SHAKE := 0.06
const SHOT_WARNING_EDGE_MARGIN := 28.0
const SHOT_WARNING_EDGE_SIZE := 14.0
const HOSTILE_CYAN := Color(0.25, 0.95, 1.0, 0.9)
## Tanda 3: presentation only; collision, damage and movement keep their tuned values.
const DANGER_CYAN := Color(0.02, 0.86, 1.0)
const DANGER_MAGENTA := Color(1.0, 0.04, 0.65)
const DANGER_CORE := Color(0.94, 1.0, 1.0)
const DANGER_BORDER := Color(0.012, 0.018, 0.038)
const DANGER_MIN_RADIUS := 0.18
const DANGER_BORDER_SCALE := 1.22
const DANGER_LINE_MIN_WIDTH := 0.07
const DANGER_CORE_FRONT_Z := 0.34
const WARNING_EDGE := Color(0.96, 1.0, 1.0, 0.94)
const WARNING_MIN_ALPHA := 0.72
const WARNING_EDGE_WIDTH := 0.045
const AMBIENT_COMBAT_RESPONSE := 6.0
const AMBIENT_COMBAT_RATIO := 0.18
const AMBIENT_COMBAT_ALPHA := 0.18
const AMBIENT_COMBAT_FADE_SCALE := 0.35
const COMBAT_PRESENTATION_RANGE := 13.0
const COMBAT_ACTOR_PRESSURE := 0.70
const COMBAT_SHOT_PRESSURE := 0.15
const AMBIENT_CALM_DEPTH := -4.0
const AMBIENT_COMBAT_DEPTH := -9.0
const FOREGROUND_COMBAT_ALPHA_SCALE := 0.22
const BEE_READABILITY_RIM_MIN := 0.75
const BEE_READABILITY_OUTLINE := 0.0038

static func presentation_combat_intensity(stage: Node3D) -> float:
	if stage == null or not stage.is_inside_tree():
		return 0.0
	var pressure := 0.0
	var camera: Camera3D = stage.get("camera")
	if camera == null:
		return 0.0
	for node in stage.get_tree().get_nodes_in_group("bee_auto_aim_targets"):
		if node is Node3D and absf(node.global_position.x - camera.global_position.x) < COMBAT_PRESENTATION_RANGE:
			if node.has_method("health_bar_visible") and node.call("health_bar_visible"):
				return 1.0
			pressure += COMBAT_ACTOR_PRESSURE
	for node in stage.get_tree().get_nodes_in_group("alien_projectiles"):
		if node is Node3D and absf(node.global_position.x - camera.global_position.x) < COMBAT_PRESENTATION_RANGE:
			pressure += COMBAT_SHOT_PRESSURE
	return clampf(pressure, 0.0, 1.0)
const POST_ROBOT_CALM_SEC := 5.5
const POST_ROBOT_HEAL_FRACTION := 0.5
const POST_ROBOT_MIN_BOMBS := 3
const POST_ROBOT_MIN_POLLEN := 10
const POST_ROBOT_PICKUP_OFFSETS := [Vector2(-3.0, 3.2), Vector2(0.5, 4.4), Vector2(4.0, 3.8)] # Tanda E: relative to where the advance ends (in view when it stops)
const POST_ROBOT_FORCE_SEC := 8.0 # Tanda E: safety net, the calm starts at most this long after the robot falls
const POST_ROBOT_FORCED_CALM_SEC := 3.5 # Tanda E: shorter calm when the sequence had to be forced (8 + 3.5 < 12 s)
const ROBOT_LASER_WARNING_SEC := 0.85
const ROBOT_LASER_COLOR := Color(0.72, 1.0, 1.0, 0.95)
const MUSIC_DEFAULT_VOLUME := 0.25
const SFX_DEFAULT_VOLUME := 1.0
const MUSIC_FADE_IN_SEC := 2.5
const MUSIC_DUCK_DB := -4.0
const MUSIC_DUCK_SEC := 0.3
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const MUSIC_TRACK_GAIN_DB := {&"title": -3.7, &"story": -3.7, &"level": -3.7, &"boss": -3.7, &"boss_tarantula": -3.7, &"victory": -3.7}
const JOYPAD_DEADZONE := 0.2
const JOYPAD_TRIGGER_THRESHOLD := 0.3
const JOYPAD_AIM_SMOOTH_SEC := 0.12
const JOYPAD_NOTICE_SEC := 3.0
const JOYPAD_STARTUP_NOTICE_SUPPRESS_MSEC := 5000
const JOYPAD_NOTICE_POSITION := Vector2(24.0, 72.0)
const JOYPAD_VIBRATION_SEC := 0.15
const JOYPAD_VIBRATION_STRENGTH := 0.2
const MOUSE_AIM_IDLE_SEC := 1.5
const STING_MIN_INTERVAL_SEC := 0.35
const PIRUETA_COOLDOWN_SEC := 1.2
const PIRUETA_DASH_DISTANCE := 3.0
const PIRUETA_DASH_SEC := 0.2
const PIRUETA_HINT_SHOT_COUNT := 6
const PIRUETA_RING_RADIUS := 9.0
const PIRUETA_RING_POSITION := Vector2(250.0, 102.0)
const BEE_TURN_HYSTERESIS_METERS := 0.4
const BEE_TURN_MIN_INTERVAL_SEC := 0.12
const BEE_TURN_DURATION_SEC := 0.22
const BEE_TURN_ROLL := 0.1
## Same species companions retain the roster and debut order, replacing HP with quantity.
const SMALL_ENEMY_COMPANIONS := 2
const SMALL_ENEMY_COMPANION_GAP_SEC := 0.7
const SMALL_ENEMY_COMPANION_MAX_DELAY_SEC := 4.0
const SMALL_ENEMY_COMPANION_DAMAGE_SCALE := 0.5
const SMALL_ENEMY_MIN_ENTRY_GAP_SEC := 0.2
const TITLE_MENU_HEIGHT_FRACTION := 0.45
const TITLE_LOGO_HEIGHT_FRACTION := 0.16
const TITLE_MENU_WIDTH := 440.0
const TITLE_MENU_MARGIN := 24
const TITLE_BACKGROUND_PATH := "res://assets/ui/title/title_background.png"
const TITLE_LOGO_PATH := "res://assets/ui/title/title_logo_cutout.png"
const TITLE_LOGO_WIDTH := 610.0
const TITLE_LOGO_HEIGHT := 260.0
const TITLE_LOGO_START_SCALE := 0.82
const TITLE_LOGO_INTRO_SECONDS := 0.85
const TITLE_LOGO_GLOW_ALPHA := 0.12
const TITLE_LOGO_GLOW_MIN_ALPHA := 0.02
const TITLE_LOGO_GLOW_SECONDS := 1.8
const TITLE_TAGLINE_TOP := 0.265
const TITLE_TAGLINE_WIDTH := 720.0
const TITLE_TAGLINE_FONT_SIZE := 25
const TITLE_PANEL_TOP := 0.36
const TITLE_PANEL_BOTTOM_MARGIN := 0.045
const TITLE_PANEL_MARGIN := 38.0
const TITLE_PANEL_WIDTH := 420.0
const TITLE_PANEL_RADIUS := 22
const TITLE_PANEL_COLOR := Color(0.025, 0.045, 0.065, 0.86)
const TITLE_PANEL_BORDER := Color(0.36, 0.77, 0.78, 0.82)
const TITLE_BUTTON_HEIGHT := 51.0
const TITLE_BUTTON_FONT_SIZE := 23
const TITLE_BUTTON_COLOR := Color(0.11, 0.17, 0.19, 0.94)
const TITLE_BUTTON_FOCUS_COLOR := Color(0.18, 0.34, 0.34, 0.98)
const TITLE_BUTTON_BORDER := Color(0.78, 0.69, 0.39, 0.94)
const TITLE_BUTTON_RADIUS := 13
const TITLE_MENU_GAP := 8
const TITLE_OPTION_FONT_SIZE := 17
const TITLE_SLIDER_WIDTH := 160.0
const TITLE_CONTROLS_WIDTH := 640.0
const TITLE_CONTROLS_HEIGHT := 370.0
const TITLE_FALLBACK_TOP := Color(0.025, 0.06, 0.13)
const TITLE_FALLBACK_BOTTOM := Color(0.24, 0.12, 0.16)
const INTRO_IMAGES := ["res://assets/ui/intro/intro_01.png", "res://assets/ui/intro/intro_02.png", "res://assets/ui/intro/intro_03.png", "res://assets/ui/intro/intro_04.png", "res://assets/ui/intro/intro_05.png"]
const INTRO_TEXTS_PATH := "res://assets/ui/intro/intro_texts.json"
const INTRO_SLIDE_SECONDS := 5.5
const INTRO_SKIP_LOCK_SECONDS := 0.6
const INTRO_FADE_SECONDS := 0.45
const INTRO_TYPEWRITER_CHARS_PER_SECOND := 38.0
const INTRO_IMAGE_ZOOM_START := 1.0
const INTRO_IMAGE_ZOOM_END := 1.07
const INTRO_TEXT_BAND_HEIGHT_FRACTION := 0.38
const INTRO_TEXT_FONT_SIZE := 33
const INTRO_SKIP_FONT_SIZE := 18
const INTRO_MUSIC_DUCK_DB := -2.0
const INTRO_LOGO_HOLD_SECONDS := 1.1
const INTRO_TYPE_SOUND_ENABLED := false
const INTRO_TYPE_SOUND_OPTION := false
const INTRO_FALLBACK_TOP := Color(0.015, 0.025, 0.06)
const INTRO_FALLBACK_BOTTOM := Color(0.09, 0.045, 0.13)
const INTRO_TEXT_MARGIN_X := 0.09
const INTRO_TEXT_TOP_INSET := 0.035
const INTRO_TEXT_OUTLINE_SIZE := 6
const INTRO_GRADIENT_COLOR := Color(0.015, 0.02, 0.035, 0.94)
const INTRO_SKIP_WIDTH := 210.0
const INTRO_SKIP_HEIGHT := 40.0
const INTRO_SKIP_RIGHT_MARGIN := 32.0
const INTRO_SKIP_BOTTOM_MARGIN := 22.0
const INTRO_END_LOGO_WIDTH := 760.0
const INTRO_END_LOGO_HEIGHT := 360.0
const INTRO_TYPEWRITER_DELAY := 0.18
static var intro_return_to_title := false
static var intro_duck_enabled := false
const HUD_PANEL_POSITION := Vector2(12.0, 10.0)
const HUD_PANEL_SIZE := Vector2(344.0, 100.0)
const HUD_ROW_HEALTH_Y := 23.0
const HUD_ROW_POLLEN_Y := 49.0
const HUD_ROW_ABILITY_Y := 80.0
const HUD_CONTROL_ROW_Y := 118.0
const HUD_LEGEND_SECONDS := 8.0 ## Controls legend: shown at the start and when a skill is taught, then fades.
const HUD_CELL_GAP := 3.0
const HUD_HEALTH_CELL_START_X := 54.0
const HUD_VALUE_START_X := 248.0
const HUD_COMBO_PANEL_SIZE := Vector2(188.0, 66.0)
const HUD_HINT_GAP := 12.0
const HUD_TERMINAL_PANEL_SIZE := Vector2(640.0, 104.0)
const HUD_TERMINAL_FONT_SIZE := 32
const HUD_TERMINAL_PANEL_COLOR := Color(0.035, 0.055, 0.075, 0.94)
const HUD_VICTORY_TITLE_TOP := -104.0
const HUD_VICTORY_TITLE_BOTTOM := -50.0
const HUD_VICTORY_BANNER_TOP := 42.0
const HUD_VICTORY_BANNER_BOTTOM := 172.0
const HUD_VICTORY_FONT_SIZE := 42
const CHECKPOINT_2_FLOWER_SCALE := 1.25
const CHECKPOINT_2_FLOWER_Z := -1.85
const CHECKPOINT_2_RING_HEIGHT := 3.15
const CHECKPOINT_2_LABEL_HEIGHT := 4.05
const HUD_PANEL_COLOR := Color(0.035, 0.075, 0.09, 0.58)
const HUD_PANEL_BORDER := Color(0.35, 0.78, 0.77, 0.92)
const HUD_HEALTH_COLOR := Color(1.0, 0.64, 0.23)
const HUD_POLLEN_COLOR := Color(1.0, 0.84, 0.24)
const HUD_READY_COLOR := Color(0.55, 0.94, 0.82)
const HUD_EMPTY_COLOR := Color(0.34, 0.42, 0.45, 0.9)
const HUD_LABEL_COLOR := Color(0.89, 0.95, 0.95)
const HUD_COMBO_COLOR := Color(1.0, 0.8, 0.28)
const HUD_FONT_SIZE := 15
const HUD_SMALL_FONT_SIZE := 12
const HUD_HEX_WIDTH := 15.0
const HUD_HEX_HEIGHT := 14.0
const HUD_HEALTH_CELLS := 10
const HUD_POLLEN_CELLS := 10
const HUD_BOMB_ICON_COUNT := 5
const HUD_DEBUG_ACTION := &"bee_hud_debug"
## Lote 17: lower the camera centre without reducing its existing vertical coverage so feet stay visible.
const CAMERA_PRESET_F_HEIGHT := 2.45
const GROUND_ACTOR_LOWEST_Y := -0.2
const GROUND_ACTOR_FRAME_MARGIN := 0.35
## Lote 17: keep tarantula damage readable without the pale, washed-out overlay; exposed implant gets a gold contour.
const TARANTULA_HIT_FLASH_COLOR := preload("res://scripts/game/bee_feedback_settings.gd").FLASH_COLOR
const TARANTULA_EXPOSED_OUTLINE_COLOR := Color(1.0, 0.62, 0.08, 1.0)
const TARANTULA_EXPOSED_OUTLINE_WIDTH := 0.0035
static var vibration_enabled := true
static var last_input_joypad := false
static var last_joypad_device := -1

static func warning_enabled(setting: String) -> bool:
	match setting:
		"SHOT_WARNING_VISUAL_ENABLED": return SHOT_WARNING_VISUAL_ENABLED
		"SHOT_WARNING_AUDIO_ENABLED": return SHOT_WARNING_AUDIO_ENABLED
		_: return SHOT_WARNING_EDGE_ENABLED

static func toggle_warning(setting: String) -> bool:
	var value := not warning_enabled(setting)
	match setting:
		"SHOT_WARNING_VISUAL_ENABLED": SHOT_WARNING_VISUAL_ENABLED = value
		"SHOT_WARNING_AUDIO_ENABLED": SHOT_WARNING_AUDIO_ENABLED = value
		_: SHOT_WARNING_EDGE_ENABLED = value
	return value
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
static var level_intro_pending := false ## E2: set when Level 1 starts from the beginning (not from a checkpoint respawn).
const LEVEL_INTRO_SECONDS := 4.0
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
static var music_volume := MUSIC_DEFAULT_VOLUME
static var sfx_volume := SFX_DEFAULT_VOLUME

static func load_audio_settings() -> void:
	var config := ConfigFile.new()
	if config.load(AUDIO_SETTINGS_PATH) == OK:
		music_volume = clampf(float(config.get_value("audio", "music", MUSIC_DEFAULT_VOLUME)), 0.0, 1.0)
		sfx_volume = clampf(float(config.get_value("audio", "sfx", SFX_DEFAULT_VOLUME)), 0.0, 1.0)

static func save_audio_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.save(AUDIO_SETTINGS_PATH)


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
