extends SceneTree

# Camera framing contract of Level 01 (preset D): camera values, flight window inside the
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
	check(is_equal_approx(camera.global_position.z, 8.5) and is_equal_approx(camera.global_position.y, 2.0), "Camera distance/height is not preset D")
	check(is_equal_approx(rad_to_deg(camera.rotation.x), 5.0) and is_equal_approx(camera.fov, 40.0), "Camera pitch/FOV is not preset D")
	var top := BeeLevel01Framing.top_y()
	var bottom := BeeLevel01Framing.bottom_y()
	var half_min := BeeLevel01Framing.half_width_min(aspect)
	var half_max := BeeLevel01Framing.half_width_max(aspect)
	check(absf(top - 5.96) < 0.02 and absf(bottom + 0.28) < 0.02 and absf(half_min - 5.35) < 0.02, "Visible area differs from preset D review")
	# Flight window: inside the visible area with the 0.4 m margin, relative to the camera.
	var m := BeeLevel01Framing.FLIGHT_MARGIN
	check(stage.bee.flight_max.x - stage.distance <= half_min - m + 0.001 and stage.distance - stage.bee.flight_min.x <= half_min - m + 0.001, "Horizontal flight limit leaves the screen")
	check(stage.bee.flight_max.y <= top - m + 0.001 and stage.bee.flight_min.y >= bottom + m - 0.001, "Vertical flight limit leaves the screen")
	# Fixture: Bee pushed far outside must end up inside the window.
	stage.bee.global_position = Vector3(stage.distance + 50.0, 50.0, 0)
	await frames(2)
	check(stage.bee.global_position.x <= stage.distance + half_min - m + 0.001 and stage.bee.global_position.y <= top - m + 0.001, "Bee escaped the visible area")
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
