extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await physics_frame
func capture(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/lote11_c_review/" + id + ".png")
func run() -> void:
	root.add_child(load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate())
	current_scene = root.get_child(root.get_child_count()-1)
	await frames(5)
	var stage := current_scene as BeeShmupStage
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.distance = 126.0
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(stage.camera.global_position.x - 2, 3.4, 0)
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	await frames(3)
	await capture("foreground_idle")
	stage.wave.director_moment.emit(&"watering_can")
	await frames(40)
	await capture("water_warning")
	await frames(30)
	await capture("water_falling")
	for i in 5:
		stage.wave.unit_downed.emit(stage.bee, false)
	juice.add_pollen(9)
	stage.bee.start_roll()
	await frames(8)
	await capture("roll_combo_hud")
	await frames(60)
	juice.add_pollen(8)
	await frames(4)
	await capture("honey_mode")
	quit(0)
