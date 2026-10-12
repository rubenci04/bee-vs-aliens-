extends SceneTree
const OUT := "res://concept_art/levels/level_02/giant_heron/"
func _initialize() -> void:
	call_deferred("run")
func capture(camera: Camera3D, point: Vector3, target: Vector3, path: String, size: float, up := Vector3.UP) -> void:
	camera.position = point
	camera.size = size
	camera.look_at(target, up)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + path + ".png")
func run() -> void:
	root.size = Vector2i(1200, 800)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.65, 0.67, 0.69)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.87, 0.9, 0.95)
	env.environment.ambient_light_energy = 0.45
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	world.add_child(sun)
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_color = Color(1, 0.93, 0.81)
	sun.light_energy = 1.0
	var model := load("res://scenes/art_labs/giant_heron_v01/controlled.tscn").instantiate() as Node3D
	model.preview_motion = false
	world.add_child(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	world.add_child(camera)
	await process_frame
	await process_frame
	var centre := Vector3(-.4,2.45,0)
	for freed in [false, true]:
		model.controlled = not freed
		var suffix := "_liberado" if freed else ""
		await capture(camera, Vector3(0,2.45,18),centre,"side"+suffix,6.2)
		await capture(camera, Vector3(-18,2.45,0),centre,"front"+suffix,6.2)
		await capture(camera, Vector3(18,2.45,0),centre,"rear"+suffix,6.2)
		await capture(camera, Vector3(0,18,0),Vector3.ZERO,"top"+suffix,6.2,Vector3.FORWARD)
	model.controlled = true
	await capture(camera, Vector3(-9,7,14),centre,"hero",6.4)
	var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
	for clip in ["wind_attack","peck_attack"]:
		model.play_clip(clip)
		player.pause()
		player.seek(1.4 if clip == "wind_attack" else .9,true)
		var fx := load("res://scripts/art/giant_heron_lab.gd").new() as Node3D
		world.add_child(fx)
		fx.set_process(false)
		if clip == "wind_attack":
			for side in ["L","R"]:
				fx.spawn_wind(model.find_child("WindAnchor_"+side,true,false).global_position)
			for gust in fx.gusts:
				gust.position.x -= 1.3
		await capture(camera,Vector3(-8,6,17),centre,clip,7.8)
		fx.queue_free()
	quit(0)
