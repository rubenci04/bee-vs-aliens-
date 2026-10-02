extends SceneTree

const CORE := preload("res://scenes/bee_prototype/bee_shmup_core_poc.tscn")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := CORE.instantiate() as BeeShmupStage
	root.add_child(scene)
	current_scene = scene
	for i in 3:
		await physics_frame
	scene.distance = 6.0
	scene._update_camera_and_bounds()
	for i in 90:
		await physics_frame
	var probe := scene.wave.get_node("Probe1") as AlienProbeRanged
	if probe == null or not probe.is_active():
		push_error("Probe failed to enter")
		quit(1)
		return
	scene.bee.global_position = probe.global_position + Vector3(-3.0, 0.0, 0.0)
	scene.bee.facing_x = 1.0
	scene.bee.refresh_auto_aim()
	for i in 3:
		await process_frame
	if DisplayServer.get_name() != "headless":
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://dev/playtest_polish_01/probe_reticle.png"))
	print("PROBE_RETICLE_OK")
	quit(0)
