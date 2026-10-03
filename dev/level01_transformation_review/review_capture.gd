extends SceneTree
## DEV ONLY. Review captures of the Level 01 Transformation Pass (render required, writes PNGs here).
##   godot --path . --resolution 1152x648 --script res://dev/level01_transformation_review/review_capture.gd -- shots=all
## Each shot stages the real level (distance, director moment, units) and saves <name>.png. Nothing in the game changes.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/level01_transformation_review/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var wanted: PackedStringArray = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			wanted = arg.substr(6).split(",")
	call_deferred("run")

func want(name: String) -> bool:
	return wanted.is_empty() or "all" in wanted or name in wanted

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + file + ".png")
	print("SHOT ", file)

func fresh() -> void:
	if stage != null:
		stage.queue_free()
		await frames(2)
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	wave.set_physics_process(false)

func at(distance: float, bee_xy := Vector2(-3.0, 3.6)) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x + bee_xy.x, bee_xy.y, 0)
	bee.facing_x = 1.0
	await frames(3)

func spawn(family: String, slot := 0, y := -99.0) -> Node3D:
	var request := {"family": family, "slot": slot, "event": 0, "hard": false}
	if y > -50.0:
		request["y"] = y
	wave._spawn(request)
	return wave.active_units.back()

func run() -> void:
	root.size = Vector2i(1152, 648)
	await fresh()
	if want("opening_can"):
		await at(4.0, Vector2(-3.2, 2.4))
		wave.director_moment.emit(&"opening_can")
		await frames(14)
		await shot("01_opening_giant_can")
	if want("aftermath"):
		await at(147.0, Vector2(-3.0, 3.4))
		wave.director_moment.emit(&"human_aftermath")
		await frames(110)
		await shot("08b_human_aftermath")
	if want("bomb_reward"):
		await at(299.0, Vector2(-3.0, 3.6))
		wave.director_moment.emit(&"bomb_reward")
		await frames(12)
		await shot("bomb_reward")
	if want("dragonfly"):
		await at(120.0, Vector2(-3.4, 3.4))
		var fly := spawn("Dragonfly") as ControlledDragonfly
		for i in 400:
			await physics_frame
			if fly.state == ControlledDragonfly.State.HOVER:
				break
		await frames(30)
		await shot("05_dragonfly_controlled")
		bee.refresh_auto_aim()
		await shot("06_dragonfly_implant_target")
		for i in 400:
			await physics_frame
			if fly.state == ControlledDragonfly.State.PASS:
				break
		await frames(28)
		await shot("05b_dragonfly_pass")
		for i in 200:
			await physics_frame
			if fly.state == ControlledDragonfly.State.HOVER:
				break
		fly.health.take_damage(20)
		await frames(2)
		await shot("06b_dragonfly_implant_damage")
		fly.health.take_damage(999)
		await frames(8)
		await shot("07_dragonfly_liberation")
		await frames(40)
		await shot("07b_dragonfly_natural")
		await frames(60)
		await shot("07c_dragonfly_exit")
	if want("contamination"):
		await at(262.0, Vector2(-3.0, 3.4))
		wave.director_moment.emit(&"contaminated_garden")
		await frames(30)
		await shot("10_contaminated_garden")
		var escalation := stage.get_node("AlienEscalation") as BeeLevel01AlienEscalation
		escalation.device_health.take_damage(999)
		await frames(50)
		await shot("10b_garden_freed")
	if want("sunset"):
		await at(316.0, Vector2(-3.4, 3.4))
		spawn("Probe", 0, 5.6)
		spawn("EyeDrone", 1, 2.4)
		spawn("Wasp", 2, 3.8)
		await frames(170)
		await shot("11_sunset_combat")
		for unit in wave.active_units.duplicate():
			wave.active_units.erase(unit)
			unit.queue_free()
		for s in get_nodes_in_group("alien_projectiles"):
			s.queue_free()
	if want("ufo"):
		await at(340.0, Vector2(-3.4, 3.4))
		wave.event_index = BeeLevel01Controller.EVENTS.size()
		wave.set_physics_process(true)
		for i in 300:
			await physics_frame
			var shadow := stage.get_node("AlienEscalation").get_node_or_null("UfoShadow") as Node3D
			if shadow != null and absf(shadow.global_position.x - stage.camera.global_position.x) < 3.0:
				break
		await shot("12_ufo_shadow")
		for i in 400:
			await physics_frame
			if wave.boss != null and wave.boss._state_time > 2.2:
				break
		await shot("13_ufo_reveal")
		for i in 600:
			await physics_frame
			if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1 and wave.boss._state_time > 3.0:
				break
		await shot("14_boss")
	if want("style"):
		await at(100.0, Vector2(-3.6, 3.6))
		var suffix := "after" if "after" in wanted else "before"
		for unit in [spawn("Wasp", 0, 4.6), spawn("Probe", 1, 2.6), spawn("EyeDrone", 2, 5.6)]:
			unit.set_physics_process(false)
		var xs := [-0.6, 1.4, 3.2]
		for i in wave.active_units.size():
			wave.active_units[i].global_position.x = stage.camera.global_position.x + xs[i]
		await frames(4)
		await shot("style_compare_" + suffix)
		for unit in wave.active_units.duplicate():
			wave.active_units.erase(unit)
			unit.queue_free()
	if want("formation"):
		await fresh()
		await at(20.0, Vector2(-3.6, 3.6))
		spawn("Wasp", 0, 4.8)
		spawn("Wasp", 1, 2.8)
		await frames(80)
		await shot("02_early_formation")
		for unit in wave.active_units.duplicate():
			wave.active_units.erase(unit)
			unit.queue_free()
	if want("eye"):
		await fresh()
		await at(100.0, Vector2(-3.4, 3.6))
		var eye := spawn("EyeDrone", 0) as EyeDroneEnemy
		for i in 700:
			await physics_frame
			if eye.fan_shot_count >= 1:
				break
		await frames(22)
		await shot("03_eye_pattern")
		wave.active_units.erase(eye)
		eye.queue_free()
		for s in get_nodes_in_group("alien_projectiles"):
			s.queue_free()
	if want("wasp"):
		await fresh()
		await at(60.0, Vector2(-3.4, 3.6))
		var wasp := spawn("Wasp", 0) as WaspEnemy
		for i in 600:
			await physics_frame
			if wasp.current_state == WaspEnemy.State.DASH:
				break
		await frames(10)
		await shot("04_wasp_pass")
		wave.active_units.erase(wasp)
		wasp.queue_free()
	if want("human"):
		await fresh()
		await at(140.0, Vector2(-3.0, 3.4))
		var human := stage.get_node("GiantHuman") as GiantHumanCrossingHazard
		human.begin_crossing(stage.camera)
		for i in 400:
			await physics_frame
			if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING and human.global_position.x - stage.camera.global_position.x < 1.0:
				break
		bee.global_position = Vector3(human.global_position.x - 2.4, 3.3, 0) # About to fly through the safe corridor.
		await frames(2)
		await shot("08_giant_human")
		human.freeze()
	if want("rock"):
		await fresh()
		await at(207.0, Vector2(-3.4, 4.6))
		spawn("Turret", 0)
		spawn("Probe", 1, 5.6)
		await frames(150)
		await shot("09_rock_turret")
		for unit in wave.active_units.duplicate():
			wave.active_units.erase(unit)
			unit.queue_free()
	quit(0)
