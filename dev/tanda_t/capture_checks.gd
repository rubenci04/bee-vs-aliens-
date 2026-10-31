extends SceneTree
## Tanda T: capturas de control (con ventana): flores de polen nuevas y tarántula colgada del techo.
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/tanda_t/" + name + ".png")
func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var stage = load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8: await physics_frame
	stage.wave.set_physics_process(false)
	stage.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.distance = 48.0
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(44.0, 3.5, 0.0)
	await shot("flores")
	stage.distance = 340.0
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(336.0, 2.5, 0.0)
	stage.wave._start_tarantula()
	var spider = stage.wave.tarantula
	spider.set_physics_process(false)
	spider.mode = &"ceiling"
	spider._flip = PI
	spider.global_position = Vector3(341.5, spider._ceiling_y(), 0.0)
	spider._apply_pose()
	await create_timer(0.6).timeout
	await shot("tarantula_techo")
	quit(0)
