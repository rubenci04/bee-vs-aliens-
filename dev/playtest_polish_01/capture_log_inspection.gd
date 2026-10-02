extends SceneTree

const GROUND := preload("res://scenes/bee_prototype/bee_shmup_ground_threat_poc.tscn")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := GROUND.instantiate() as BeeShmupStage
	root.add_child(scene)
	current_scene = scene
	scene.set_physics_process(false)
	scene.wave.set_physics_process(false)
	scene.distance = 25.0
	scene._update_camera_and_bounds()
	scene.bee.global_position = Vector3(23.0, 1.0, 0.0)
	scene.bee.set_physics_process(false)
	scene.camera.global_position = Vector3(33, 2.5, 0)
	scene.camera.look_at(Vector3(25, 1.0, 0))
	for i in 5:
		await process_frame
	if DisplayServer.get_name() != "headless":
		var path := ProjectSettings.globalize_path("res://dev/playtest_polish_01/log_inspection.png")
		root.get_viewport().get_texture().get_image().save_png(path)
	print("LOG_INSPECTION_OK")
	quit(0)
