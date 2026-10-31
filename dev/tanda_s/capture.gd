extends SceneTree
## Tanda S: capturas del Nivel 1 jugado (necesita ventana, NO headless). Bee invulnerable, en el tercio izquierdo, disparando.
## Uso:  godot --path . --script res://dev/tanda_s/capture.gd -- antes|despues
##        godot --path . --script res://dev/tanda_s/capture.gd -- comparar   (arma dev/tanda_s/comparacion.png)
const TIMES := [20.0, 45.0, 75.0, 120.0, 160.0, 200.0]
const DIR := "res://dev/tanda_s/"
const SPEED := 2.0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if not args.is_empty() else "antes"
	if mode == "comparar":
		compare()
		quit(0)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR + mode))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage = load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8: await physics_frame
	stage.bee.health.damage_blocked = true
	Engine.time_scale = SPEED
	var t := 0.0
	var k := 0
	var last_distance := 0.0
	var stuck := 0.0
	while k < TIMES.size():
		await physics_frame
		t += Engine.time_scale / 60.0
		var b = stage.bee
		var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(stage.get_viewport()))
		b.global_position.x = stage.distance - half * (0.55 + 0.2 * sin(t * 0.5)) # tercio izquierdo
		b.global_position.y = 3.2 + sin(t * 0.8) * 1.2
		if int(t * 10) % 3 == 0: b.fire()
		# Si el avance se traba más de 4 s (el bot no apunta al suelo), ayuda a despejar lo que está en pantalla.
		if absf(stage.distance - last_distance) > 0.01:
			last_distance = stage.distance
			stuck = 0.0
		stuck += Engine.time_scale / 60.0
		if stuck > 4.0 and int(t * 10) % 3 == 0:
			for target in get_nodes_in_group("bee_auto_aim_targets"):
				var body := target as Node3D
				if body == null or absf(body.global_position.x - stage.distance) > half: continue
				var health = body.get_node_or_null("HealthComponent")
				if health == null and body.get_parent() != null: health = body.get_parent().get_node_or_null("HealthComponent")
				if health is HealthComponent: health.take_damage(6)
		if t >= TIMES[k]:
			Engine.time_scale = 0.0
			for i in 4: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(DIR + mode + "/s%03d.png" % int(TIMES[k]))
			print("CAP ", TIMES[k], " d=", stage.distance)
			Engine.time_scale = SPEED
			k += 1
	Engine.time_scale = 1.0
	quit(0)

## Hoja comparativa: antes a la izquierda, después a la derecha, un segundo por fila (a mitad de tamaño).
func compare() -> void:
	var cell := Vector2i(640, 360)
	var sheet := Image.create(cell.x * 2 + 8, (cell.y + 8) * TIMES.size(), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	for row in TIMES.size():
		for col in 2:
			var path := DIR + ("antes" if col == 0 else "despues") + "/s%03d.png" % int(TIMES[row])
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			if image == null: continue
			image.convert(Image.FORMAT_RGB8)
			image.resize(cell.x, cell.y)
			sheet.blit_rect(image, Rect2i(Vector2i.ZERO, cell), Vector2i(col * (cell.x + 8), row * (cell.y + 8)))
	sheet.save_png(DIR + "comparacion.png")
	print("COMPARACION ok")
