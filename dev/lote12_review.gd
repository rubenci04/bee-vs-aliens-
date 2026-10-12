extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await physics_frame
func capture(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/lote12_review/" + id + ".png")
func run() -> void:
	root.add_child(load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate())
	current_scene = root.get_child(root.get_child_count()-1)
	await frames(5)
	var stage := current_scene as BeeShmupStage
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.distance = 70.0
	stage._update_camera_and_bounds()
	var w := stage.wave as BeeLevel01Controller
	stage.bee.global_position = Vector3(stage.camera.global_position.x - 4, 3.4, 0)
	var shots := [["FlyCommon", 4.4], ["FlyGreen", 3.0], ["FlyCloud", 4.6]]
	var slot := 0
	for s in shots:
		w._spawn({"family": s[0], "slot": slot, "event": 0, "hard": false, "y": s[1], "x": -2.0 - float(slot) * 3.0})
		slot += 1
	await frames(90)
	await capture("air_roster")
	for u in w.active_units: u.queue_free()
	w.active_units.clear()
	await frames(3)
	for s in ["WormB", "Turtle", "Snail"]:
		w._spawn({"family": s, "slot": slot, "event": 0, "hard": false, "x": -4.0 - float(slot) * 1.2})
		slot += 1
	await frames(150)
	await capture("ground_roster")
	w._spawn({"family": "WormA", "slot": 9, "event": 0, "hard": false})
	await frames(200)
	await capture("worm_a_warning")
	await frames(70)
	await capture("worm_a_up")
	stage.distance = 98.0
	stage._update_camera_and_bounds()
	await frames(6)
	await capture("mushrooms")
	quit(0)
