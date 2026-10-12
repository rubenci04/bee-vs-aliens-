extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await physics_frame
func capture(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/lote11_review/" + id + ".png")
func run() -> void:
	root.add_child(load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate())
	current_scene = root.get_child(root.get_child_count()-1)
	await frames(5)
	var stage := current_scene as BeeShmupStage
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	var args := OS.get_cmdline_user_args()
	for a in args:
		stage.distance = float(a)
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(stage.camera.global_position.x - 2, 4.0, 0)
		await frames(3)
		await capture("at_%d" % int(float(a)))
	quit(0)
