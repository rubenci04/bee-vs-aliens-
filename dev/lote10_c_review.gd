extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await physics_frame
func capture(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/lote10_c_review/" + id + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://dev/lote10_c_review")
	root.add_child(load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate())
	current_scene = root.get_child(root.get_child_count()-1)
	await frames(5)
	var stage := current_scene as BeeShmupStage
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.distance = 188.0
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(stage.camera.global_position.x - 2, 4.0, 0)
	stage.wave.director_moment.emit(&"scale_event")
	var frog := stage.get_node("ScaleEvent").frog as BeeGardenToadEncounter
	for i in 500:
		await frames(1)
		if frog.state == BeeLakeToadBoss.State.TONGUE_WARN:
			await capture("frog_warning")
			break
	frog.health.take_damage(9999)
	await frames(5)
	await capture("frog_liberated")
	frog.hide()
	frog.set_physics_process(false)
	stage.distance = 340
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(stage.camera.global_position.x - 4, 5.1, 0)
	stage.wave._start_boss()
	var boss := stage.wave.boss as UfoBoss01
	await frames(200)
	boss._change_state(UfoBoss01.State.PHASE_3)
	boss._attack_step = &"cooldown"
	boss._attack_left = 10
	boss._side_timer = 10
	boss.assault.clock = 0
	await frames(20)
	await capture("ufo_sweep_warning")
	await frames(42)
	await capture("ufo_sweep_active")
	quit(0)
