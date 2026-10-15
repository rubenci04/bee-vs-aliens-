extends SceneTree
## Same camera and scale in both runs; capture before editing, then after.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(960, 400)
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.0
	camera.position = Vector3(0, 0, 6)
	world.add_child(camera)
	camera.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, -30, 0)
	world.add_child(sun)
	var canvas := CanvasLayer.new()
	world.add_child(canvas)
	var label := Label.new()
	var before := "before" in OS.get_cmdline_user_args()
	label.text = ("ANTES" if before else "DESPUÉS") + " · Polen ×1                         Racimo ×10 · cámara y escala iguales"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 23)
	canvas.add_child(label)
	for i in 2:
		var item := (load("res://scenes/items/toon/pollen.tscn" if i == 0 else "res://scenes/items/toon/pollen_cluster.tscn") as PackedScene).instantiate()
		world.add_child(item)
		item.position.x = -1.2 if i == 0 else 1.2
		item.process_mode = Node.PROCESS_MODE_DISABLED
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://dev/t3m_pickup_before.png" if before else "res://dev/t3m_pickup_after.png"
	root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path)
	if not before:
		world.queue_free()
		await process_frame
		await capture_gameplay()
	quit()

func capture_gameplay() -> void:
	root.size = Vector2i(1154, 648)
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 25
	stage._update_camera_and_bounds()
	stage.bee.set_physics_process(false)
	stage.bee.global_position = Vector3(24, 4, 0)
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	juice.set_physics_process(false)
	juice.add_pollen(20)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/t3m_hud_charged.png")
	juice.try_pollen_nova()
	var nova := stage.get_node("PollenNova")
	nova.set_physics_process(false)
	nova._physics_process(0.18)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/t3m_nova_wave.png")
	var title := preload("res://scenes/game/bee_title_screen.tscn").instantiate()
	stage.queue_free()
	await process_frame
	root.add_child(title)
	current_scene = title
	title._show_controls()
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/t3m_controls.png")
