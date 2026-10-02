extends SceneTree

const GROUND := preload("res://scenes/bee_prototype/bee_shmup_ground_threat_poc.tscn")

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
	var scene := GROUND.instantiate() as BeeShmupStage
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	check(scene.get_node("LogObstacle/CollisionShape3D").disabled, "Solid inherited collider still covers tunnel")
	for name in ["LogTop", "LogBottom", "LogNearSide", "LogFarSide"]:
		check(not (scene.get_node("LogObstacle/" + name) as CollisionShape3D).disabled, "Shell piece missing: " + name)
	var bee := scene.bee
	scene.set_physics_process(false)
	scene.wave.set_physics_process(false)
	scene.distance = 25.0
	scene._update_camera_and_bounds()
	bee.global_position = Vector3(22.0, 0.9, 0.0)
	bee.velocity = Vector3.ZERO
	var start_x := bee.global_position.x
	Input.action_press("move_right")
	for i in 90:
		await frames(1)
		if bee.global_position.x >= 25.0:
			break
	Input.action_release("move_right")
	check(bee.global_position.x >= 25.0 and is_equal_approx(bee.global_position.z, 0.0), "Bee could not enter hollow center")
	check(bee.global_position.y > 0.5 and bee.global_position.y < 1.3, "Bee left visible tunnel height")
	if DisplayServer.get_name() != "headless":
		bee.set_physics_process(false)
		scene.camera.global_position = Vector3(29.0, 1.1, 0.0)
		scene.camera.look_at(Vector3(25.0, 0.9, 0.0))
		await frames(2)
		var path := ProjectSettings.globalize_path("res://dev/playtest_polish_01/bee_in_hollow_log.png")
		check(root.get_viewport().get_texture().get_image().save_png(path) == OK, "Log capture failed")
		bee.set_physics_process(true)
	Input.action_press("move_right")
	for i in 110:
		await frames(1)
		if bee.global_position.x >= 27.3:
			break
	Input.action_release("move_right")
	check(bee.global_position.x >= 27.3 and bee.global_position.x > start_x + 5.0, "Bee got stuck before exiting hollow log")
	check(is_equal_approx(scene.distance, 25.0), "Tunnel crossing broke stage scroll")
	print("BEE_SHMUP_HOLLOW_LOG_OK shell passage Bee enters/interior/exits no_Z")
	quit(0)
