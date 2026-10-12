extends SceneTree
const OUT := "res://dev/fly_trio_motion_frames/"
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
	var lab := load("res://scenes/art_labs/fly_trio_v01.tscn").instantiate() as Node3D
	world.add_child(lab)
	lab.get_node("CanvasLayer").queue_free()
	camera.current = true
	await process_frame
	var frame := 0
	for clip in ["hover","attack","liberate"]:
		for model in [lab.get_node("Common"),lab.get_node("Green"),lab.get_node("Swarm")]:
			model.controlled = clip != "liberate"
			model.play_clip(clip)
			model.find_child("AnimationPlayer",true,false).pause()
		for i in range(16):
			for model in [lab.get_node("Common"),lab.get_node("Green"),lab.get_node("Swarm")]:
				var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
				player.seek(player.current_animation_length*i/16.0,true)
			await capture(camera,Vector3(0,5,18),Vector3(0,1.6,0),"frame_%03d"%frame,7.7)
			frame += 1
	quit(0)
