extends SceneTree
## Six exact poses of the real T4b movement; not a recording of realtime input.
const SIZE := Vector2i(800, 500)
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	root.size = SIZE
	Engine.physics_ticks_per_second = 300
	BeeJuice.hit_stop_enabled = false # Pose sampling; local hit-stop is checked by T4f.
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.get_node("Juice").set_physics_process(false)
	stage.distance = 25
	stage._update_camera_and_bounds()
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.global_position = Vector3(23, 4, 0)
	stage.wave._spawn({"family":"Wasp", "slot":0, "event":0, "hard":false})
	var wasp := stage.wave.active_units.back() as WaspEnemy
	wasp.global_position = bee.global_position + Vector3(1.6, 0, 0)
	wasp.health.max_health = 100
	wasp.health.current_health = 100
	wasp.set_physics_process(false)
	for child in stage.get_children():
		if child is Node3D and child != bee and child != wasp and not child.is_ancestor_of(wasp): child.hide()
	for layer in stage.find_children("*", "CanvasLayer", true, false): layer.hide()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.8
	camera.position = Vector3(24.2, 4.8, 5)
	stage.add_child(camera)
	camera.look_at(Vector3(24.2, 4, 0))
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	stage.add_child(light)
	var layer := CanvasLayer.new()
	stage.add_child(layer)
	var caption := Label.new()
	caption.position = Vector2(14, 14)
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_constant_override("outline_size", 5)
	layer.add_child(caption)
	var visual := bee.get_node("VisualRoot/BeeVisual")
	await frames(3)
	assert(bee.start_melee())
	var montage := Image.create(SIZE.x * 3, SIZE.y * 2, false, Image.FORMAT_RGBA8)
	var previous := 0.0
	var times := [0.10, 0.16, 0.19, 0.226667, 0.326667, 0.393334]
	var texts := ["1 · 0,10 s · Preparación", "2 · 0,16 s · Patas atrás", "3 · 0,19 s · Golpe al frente", "4 · ≈0,22 s · Contacto", "5 · ≈0,33 s · Recuperación", "6 · ≈0,39 s · Patas plegadas"]
	for i in times.size():
		while previous + 0.00001 < times[i]:
			bee.sting_dash.step(1.0 / 300.0)
			previous += 1.0 / 300.0
			await physics_frame
		visual.punch_pose.update(bee.sting_dash)
		caption.text = texts[i]
		await frames(2)
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.convert(Image.FORMAT_RGBA8)
		montage.blit_rect(picture, Rect2i(Vector2i.ZERO, SIZE), Vector2i((i % 3) * SIZE.x, (i / 3) * SIZE.y))
	assert(montage.save_png("res://docs/punetazo_t4g_secuencia.png") == OK)
	print("T4G_CAPTURE hp=", wasp.health.current_health, " active=", bee.sting_dash.active)
	assert(wasp.health.current_health == 70 and not bee.sting_dash.active)
	quit()
