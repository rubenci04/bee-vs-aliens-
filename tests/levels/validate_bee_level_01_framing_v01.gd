extends SceneTree

# Camera framing contract of Level 01 (preset E, REBUILD 03; preset D kept as reference): camera values, flight window inside the
# visible area, spawn just outside the right edge, and nothing above top edge - 0.5 m.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func run() -> void:
	create_timer(60.0, true, false, true).timeout.connect(func(): quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	var wave := stage.wave as BeeLevel01Controller
	var aspect := BeeLevel01Framing.view_aspect(root)
	var camera := stage.camera
	var preset: Dictionary = BeeLevel01Framing.PRESETS[BeeLevel01Framing.DEFAULT_PRESET]
	check(BeeLevel01Framing.DEFAULT_PRESET == &"F" and is_equal_approx(camera.global_position.z, preset["distance"]) and is_equal_approx(camera.global_position.y, preset["height"]), "Camera distance/height is not preset F (LOTE 14: E pulled back 12 %)")
	check(is_equal_approx(rad_to_deg(camera.rotation.x), preset["pitch"]) and is_equal_approx(camera.fov, preset["fov"]), "Camera pitch/FOV is not preset F")
	var top := BeeLevel01Framing.top_y()
	var bottom := BeeLevel01Framing.bottom_y()
	var half_min := BeeLevel01Framing.half_width_min(aspect)
	var half_max := BeeLevel01Framing.half_width_max(aspect)
	# REBUILD 03: preset E gave 15-25 % more width and height than preset D; LOTE 14: the default F is E pulled back 12 % (so 29-40 % over D).
	BeeLevel01Framing.use_preset(&"D")
	var d_height := BeeLevel01Framing.top_y() - BeeLevel01Framing.bottom_y()
	var d_half := BeeLevel01Framing.half_width_min(aspect)
	check(absf(BeeLevel01Framing.top_y() - 5.96) < 0.02 and absf(d_half - 5.35) < 0.02, "Preset D reference changed")
	BeeLevel01Framing.use_preset(BeeLevel01Framing.DEFAULT_PRESET)
	var width_gain := half_min / d_half
	var height_gain := (top - bottom) / d_height
	check(width_gain >= 1.29 and width_gain <= 1.40 and height_gain >= 1.29 and height_gain <= 1.40, "Camera F gain outside 29-40 %% over D (w %.2f h %.2f)" % [width_gain, height_gain])
	check(bottom <= BeeGameSettings.GROUND_ACTOR_LOWEST_Y - BeeGameSettings.GROUND_ACTOR_FRAME_MARGIN,
		"Camera must leave %.2f m below the lowest ground actor (bottom %.3f)" % [BeeGameSettings.GROUND_ACTOR_FRAME_MARGIN, bottom])
	# Horizontal flight uses 95 % of the visible width with equal left/right margins at both supported aspect ratios.
	var m := BeeLevel01Framing.FLIGHT_MARGIN
	for ratio in [16.0 / 9.0, 16.0 / 10.0]:
		var visible_half := BeeLevel01Framing.half_width_min(ratio)
		var left := BeeLevel01Framing.flight_left_offset(ratio)
		var right := BeeLevel01Framing.flight_right_offset(ratio)
		check(absf((right - left) / (2.0 * visible_half) - preload("res://scripts/game/bee_hero_look_settings.gd").playable_width_fraction()) < 0.001, "Playable width must be the configured fraction (Tanda S: 6 %% margins) at aspect %.3f" % ratio)
		check(absf((visible_half + left) - (visible_half - right)) < 0.001, "Horizontal margins must be symmetric at aspect %.3f" % ratio)
	check(stage.bee.flight_max.x - stage.distance <= BeeLevel01Framing.flight_right_offset(aspect) + 0.001 and stage.bee.flight_min.x - stage.distance >= BeeLevel01Framing.flight_left_offset(aspect) - 0.001, "Horizontal flight limit leaves the 95 % play area")
	check(stage.bee.flight_max.y <= top - m + 0.001 and stage.bee.flight_min.y >= bottom + m - 0.001, "Vertical flight limit leaves the screen")
	# The spawn anchor stays at 32 %; the flight range reaches near both screen edges.
	var width := 2.0 * half_min
	check(absf((stage.bee.flight_max.x - stage.distance - BeeLevel01Framing.flight_left_offset(aspect)) / width - preload("res://scripts/game/bee_hero_look_settings.gd").playable_width_fraction()) < 0.01, "Flight window must span the configured fraction of the visible width")
	var start_fraction := (stage.bee.global_position.x - camera.global_position.x + half_min) / width
	check(absf((BeeLevel01Framing.player_anchor_offset(aspect) + half_min) / width - 0.32) < 0.005, "Anchor must sit at 32 %% of the width")
	check(start_fraction >= 0.25 and start_fraction <= 0.33, "Bee must start near the anchor (%.2f; the scroll already advanced a little)" % start_fraction)
	# Fixture: Bee pushed far outside must end up inside the window.
	stage.bee.global_position = Vector3(stage.distance + 50.0, 50.0, 0)
	await frames(2)
	check(stage.bee.global_position.x <= stage.distance + BeeLevel01Framing.flight_right_offset(aspect) + 0.001 and stage.bee.global_position.y <= top - m + 0.001, "Bee escaped the visible area")
	# Pollen and powerups never above the entity ceiling.
	var ceiling := BeeLevel01Framing.max_entity_y()
	for group in ["Pollen", "Powerups"]:
		for item: Node3D in stage.get_node(group).get_children():
			check(item.position.y <= ceiling + 0.001, "%s above ceiling: %s" % [group, item.name])
	# Spawns: moving enemies past the right edge, turret on screen, air height capped.
	stage.scroll_speed = 0.0
	wave.set_physics_process(false)
	for family in ["Wasp", "Probe", "EyeDrone", "Speeder", "OrganicAlien", "Walker"]:
		wave._spawn({"family": family, "slot": 2, "event": 0, "hard": false})
		var unit: Node3D = wave.active_units.back()
		check(unit.global_position.x - camera.global_position.x >= half_max + 0.99, family + " spawned inside the screen")
		check(unit.global_position.y <= ceiling + 0.001, family + " spawned above the entity ceiling")
	wave._spawn({"family": "Turret", "slot": 0, "event": 0, "hard": true})
	var turret: Node3D = wave.active_units.back()
	check(is_equal_approx(turret.global_position.x - camera.global_position.x, BeeLevel01Framing.ONSCREEN_SPAWN_X) and BeeLevel01Framing.ONSCREEN_SPAWN_X < half_min, "Turret must spawn on screen")
	print("FRAMING_OK top=%.3f bottom=%.3f half=%.3f..%.3f ceiling=%.3f" % [top, bottom, half_min, half_max, ceiling])
	quit(0)
