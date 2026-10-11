extends SceneTree
## DEV (noche 01): capture of the aftermath turtle on the garden floor (res://dev/visual_target/noche_turtle_<tag>.png).
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var tag: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "a"
	root.size = Vector2i(1152, 648)
	var stage := (load("res://scenes/levels/bee_level_01_vertical_slice.tscn") as PackedScene).instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 5:
		await physics_frame
	stage.distance = 146.0
	stage._update_camera_and_bounds()
	(stage.wave as Node).set_physics_process(false)
	stage.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").controls_hint.hide()
	var moments := stage.get_node("DirectorMoments")
	moments.call("_human_aftermath")
	for i in 150:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://dev/visual_target/noche_turtle_%s.png" % tag))
	var t0: Node3D = moments.get("beetle")
	var sp := stage.camera.unproject_position(t0.global_position + Vector3(0, 0.4, 0))
	var img := root.get_texture().get_image()
	var crop := img.get_region(Rect2i(int(sp.x) - 120, int(sp.y) - 110, 240, 150))
	crop.resize(720, 450)
	crop.save_png(ProjectSettings.globalize_path("res://dev/visual_target/noche_turtle_%s_zoom.png" % tag))
	var turtle: Node3D = moments.get("beetle")
	turtle.get_node("HealthComponent").take_damage(999)
	for i in 30:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://dev/visual_target/noche_turtle_%s_freed.png" % tag))
	print("TURTLE_CAPTURE ok")
	quit()
