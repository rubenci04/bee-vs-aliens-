extends SceneTree
const OUT := "res://concept_art/levels/level_01/garden_floor_v01/"
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
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	world.add_child(camera)
	for variant in ["worm_rose", "worm_compost", "mushroom_button", "mushroom_umbrella", "mushroom_spotted"]:
		var model := load("res://scenes/art_labs/garden_floor_v01/"+variant+".tscn").instantiate() as Node3D
		model.preview_motion = false
		world.add_child(model)
		await process_frame
		var centre := Vector3(0,{"worm_rose":.2,"worm_compost":.25,"mushroom_button":.35,"mushroom_umbrella":.50,"mushroom_spotted":.88}[variant],0)
		var size: float = {"worm_rose":3.4,"worm_compost":3.0,"mushroom_button":1.4,"mushroom_umbrella":2.1,"mushroom_spotted":3.5}[variant]
		for freed in ([false,true] if variant.begins_with("worm") else [false]):
			model.controlled = not freed
			var suffix := "_liberado" if freed else ""
			await capture(camera,Vector3(0,centre.y,12),centre,variant+"_side"+suffix,size)
			await capture(camera,Vector3(-12,centre.y,0),centre,variant+"_front"+suffix,size)
			await capture(camera,Vector3(12,centre.y,0),centre,variant+"_rear"+suffix,size)
			await capture(camera,Vector3(0,12,0),Vector3.ZERO,variant+"_top"+suffix,size,Vector3.FORWARD)
		model.controlled = true
		await capture(camera,Vector3(-7,5,12),centre,variant+"_hero",size)
		model.queue_free()
		await process_frame
	var lab := load("res://scenes/art_labs/garden_floor_v01.tscn").instantiate() as Node3D
	world.add_child(lab)
	lab.get_node("CanvasLayer").queue_free()
	camera.current = true
	await process_frame
	await capture(camera,Vector3(0,4,18),Vector3(0,1.6,0),"overview",14.0)
	quit(0)
