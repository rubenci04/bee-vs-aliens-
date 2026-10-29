extends SceneTree
## Run without --headless to save four review frames from the real v02 model.
const PLAYER := preload("res://scenes/bee_prototype/bee_player.tscn")
const OUT := "res://docs/capturas_tanda_j/"


func _initialize() -> void:
	call_deferred("run")


func frame(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(OUT + name + ".png")
	print("BEE_CAPTURE %s %s" % [name, result])


func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("BEE_CAPTURE_UNAVAILABLE headless display")
		quit(0)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.18, 0.24, 0.26)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(1.0, 0.88, 0.70)
	environment.environment.ambient_light_energy = 0.75
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, -25.0, 0.0)
	world.add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 4.0)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.4
	camera.current = true
	world.add_child(camera)
	var bee := PLAYER.instantiate() as BeePlayer
	world.add_child(bee)
	bee.set_physics_process(false)
	var visual = bee.get_node("VisualRoot/BeeVisual")
	for i in 12:
		await process_frame
	await frame("01_reposo")
	bee.velocity = Vector3(bee.horizontal_speed, bee.vertical_speed * 0.35, 0.0)
	for i in 15:
		await process_frame
	await frame("02_avance")
	bee.velocity = Vector3.ZERO
	bee.start_roll()
	for i in 7:
		bee._update_roll(1.0 / 60.0)
		await process_frame
	visual.set_process(false)
	visual.model.show() # Hold one visible roll frame between the existing invulnerability blinks.
	await frame("03_pirueta")
	visual.set_process(true)
	bee._update_roll(bee.roll_duration)
	bee._update_roll(bee.roll_cooldown)
	bee.start_melee()
	bee.sting_dash.step(0.20)
	camera.position.x = bee.position.x
	camera.position.y = bee.position.y
	for i in 3:
		await process_frame
	await frame("04_punetazo")
	quit(0)
