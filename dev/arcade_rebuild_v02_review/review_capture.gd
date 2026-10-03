extends SceneTree
## DEV ONLY. Review captures of ARCADE CONTENT & SPECTACLE REBUILD 02 (render required, writes PNGs here).
##   godot --path . --resolution 1152x648 --script res://dev/arcade_rebuild_v02_review/review_capture.gd -- shots=all
## Each shot stages the real level (distance, director moment, units, depth entries) and saves <NN_name>.png.
## Nothing in the game changes.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/arcade_rebuild_v02_review/"

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

## Spawns one unit like the director does (optional height / depth / swarm path).
func spawn(family: String, slot := 0, y := -99.0, extra := {}) -> Node3D:
	var request := {"family": family, "slot": slot, "event": 0, "hard": false}
	if y > -50.0:
		request["y"] = y
	request.merge(extra, true)
	wave._spawn(request)
	return wave.swarm_units.back() if family == "Swarm" else wave.active_units.back()

func depth_group(units: Array, ys: Array, xs: Array) -> void:
	var anchor := Vector2(BeeLevel01Controller.DEPTH_TARGET_X + 0.5, 4.4)
	for i in units.size():
		spawn(str(units[i]), i, float(ys[i]), {"depth": true, "x": float(xs[i]), "anchor": anchor})

func swarm(count: int, y: float, path: String, shooters := []) -> void:
	for i in count:
		spawn("Swarm", i, y, {"path": path, "shooter": i in shooters})
		await frames(20)

func clear() -> void:
	for unit in wave.active_units + wave.swarm_units:
		unit.queue_free()
	wave.active_units.clear()
	wave.swarm_units.clear()
	for s in get_nodes_in_group("alien_projectiles"):
		s.queue_free()
	await frames(2)

func live(seconds: float) -> void:
	# Let the AI play with Bee bobbing (no input), so attacks and telegraphs show up.
	for i in int(seconds * 60.0):
		bee.global_position.y = 3.6 + sin(float(i) / 60.0 * 2.0) * 0.9
		await physics_frame

func run() -> void:
	root.size = Vector2i(1152, 648)
	await fresh()
	if want("opening"):
		await at(5.0, Vector2(-3.2, 2.6))
		wave.director_moment.emit(&"opening_can")
		await frames(16)
		await shot("01_opening")
	if want("early"):
		await at(22.0)
		spawn("Wasp", 0, 4.8)
		await swarm(3, 3.0, "sine")
		await live(1.6)
		await shot("02_early_combat")
		await clear()
	if want("depth"):
		await at(68.0)
		depth_group(["EyeDrone", "EyeDrone", "EyeDrone"], [4.4, 5.8, 3.0], [0.0, 1.0, 1.0])
		await frames(24)
		await shot("03_depth_formation_approaching")
		await live(2.6)
		await shot("04_depth_formation_gameplay")
		await clear()
	if want("walker"):
		await at(105.0, Vector2(-3.4, 4.8))
		var walker := spawn("Walker", 0, -99.0, {"hold": true}) as GroundWalkerEnemy
		for i in 600:
			await physics_frame
			if walker.current_state == GroundWalkerEnemy.State.SHOOT:
				break
		await frames(18)
		await shot("05_walker_showcase")
		await clear()
	if want("organic"):
		await at(80.0)
		spawn("OrganicAlien", 0, 4.0, {"depth": true, "anchor": Vector2(BeeLevel01Controller.DEPTH_TARGET_X, 4.0)})
		await frames(40)
		await live(1.8)
		await shot("06_organic_presentation")
		await clear()
		await at(214.0)
		spawn("OrganicAlien", 0, 3.6)
		spawn("Probe", 1, 5.8)
		spawn("EyeDrone", 2, 2.2)
		await live(3.4)
		await shot("07_organic_combined")
		await clear()
	if want("human"):
		await fresh()
		await at(140.0, Vector2(-3.0, 3.4))
		var human := stage.get_node("GiantHuman") as GiantHumanCrossingHazard
		human.begin_crossing(stage.camera)
		for i in 400:
			await physics_frame
			if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING and human.global_position.x - stage.camera.global_position.x < 1.0:
				break
		bee.global_position = Vector3(human.global_position.x - 2.4, 3.3, 0)
		await frames(2)
		await shot("08_human")
		human.freeze()
	if want("dragonfly"):
		await fresh()
		await at(124.0, Vector2(-3.4, 3.4))
		var fly := spawn("Dragonfly") as ControlledDragonfly
		for i in 400:
			await physics_frame
			if fly.state == ControlledDragonfly.State.HOVER:
				break
		await frames(20)
		await shot("09_dragonfly")
		await clear()
	if want("dense"):
		await fresh()
		await at(172.0)
		spawn("EyeDrone", 0, 6.0)
		spawn("Turret", 1)
		spawn("Probe", 2, 4.6)
		spawn("Probe", 3, 2.4)
		await swarm(2, 5.2, "sine", [0])
		await live(2.2)
		await shot("10_dense_mid_encounter")
		await clear()
	if want("walker2"):
		await at(180.0, Vector2(-3.4, 3.4))
		spawn("Walker", 0, -99.0, {"hold": true})
		await frames(70)
		await swarm(3, 5.6, "dive", [1])
		await live(1.0)
		await shot("11_second_walker_set_piece")
		await clear()
	if want("garden"):
		await fresh()
		await at(30.0, Vector2(-3.0, 3.6))
		await frames(90)
		await shot("12_living_garden")
	if want("frog"):
		await at(188.0, Vector2(-3.4, 5.2))
		stage.scroll_speed = 2.0
		stage.set_physics_process(true)
		wave.director_moment.emit(&"scale_event")
		var frog_event := stage.get_node("ScaleEvent") as BeeLevel01ScaleEvent
		for i in 600:
			await physics_frame
			if frog_event.landings >= 2:
				break
		await frames(30)
		await shot("13_large_scale_event")
		stage.scroll_speed = 0.0
	if want("late"):
		await fresh()
		await at(324.0)
		spawn("EyeDrone", 0, 4.2)
		spawn("Probe", 1, 5.8)
		spawn("Probe", 2, 2.6)
		spawn("Walker", 3)
		await live(3.0)
		await shot("14_late_game_pressure")
		await clear()
	if want("power"):
		await fresh()
		await at(331.0, Vector2(-3.4, 3.8))
		wave.director_moment.emit(&"preboss_power")
		await frames(26)
		await shot("15_guaranteed_spread_pickup")
	if want("ufo"):
		await fresh()
		await at(340.0, Vector2(-3.4, 3.4))
		wave.event_index = BeeLevel01Controller.EVENTS.size()
		wave.set_physics_process(true)
		for i in 300:
			await physics_frame
			var shadow := stage.get_node("AlienEscalation").get_node_or_null("UfoShadow") as Node3D
			if shadow != null and absf(shadow.global_position.x - stage.camera.global_position.x) < 3.0:
				break
		await shot("16_final_silence")
		for i in 400:
			await physics_frame
			if wave.boss != null and wave.boss._state_time > 2.2:
				break
		await shot("17_ufo_reveal")
	quit(0)
