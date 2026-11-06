extends SceneTree
## Mejora visual: recorre el Nivel 1 con un bot y guarda capturas reales (necesita ventana, NO headless).
## Bee invulnerable, dispara y se mueve en el tercio izquierdo. También mide FPS y draw calls por tramo.
## Uso:
##   godot --path . --script res://dev/mejora_visual/qa_capture.gd -- <carpeta> [nivel|titulo|robot|tarantula|todo]
## Las imágenes quedan en qa_screenshots/<carpeta>/ (la carpeta tiene .gdignore: Godot no las importa).
const SPEED := 3.0
const DISTANCES := [4.0, 30.0, 60.0, 90.0, 120.0, 150.0, 180.0, 215.0, 245.0, 270.0]
const LEVEL := "res://scenes/levels/bee_level_01_vertical_slice.tscn"
const TITLE := "res://scenes/game/bee_title_screen.tscn"

var folder := "base"
var report: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	folder = args[0] if args.size() > 0 else "base"
	var mode: String = args[1] if args.size() > 1 else "todo"
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_screenshots/" + folder))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	if mode in ["titulo", "todo"]:
		await capture_title()
	if mode in ["nivel", "todo"]:
		await capture_level()
	if mode in ["robot", "todo"]:
		await capture_boss(292.0, "robot", [2.0, 6.0, 12.0, 20.0, 30.0])
	if mode in ["tarantula", "todo"]:
		await capture_boss(340.5, "tarantula", [2.0, 6.0, 12.0, 20.0, 30.0, 45.0])
	var file := FileAccess.open("res://qa_screenshots/" + folder + "/_medidas.txt", FileAccess.WRITE)
	for line in report:
		file.store_line(line)
		print(line)
	file.close()
	Engine.time_scale = 1.0
	quit(0)

func snap(label: String) -> void:
	var old := Engine.time_scale
	Engine.time_scale = 0.0
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa_screenshots/%s/%s.png" % [folder, label])
	Engine.time_scale = old

func measure(label: String) -> void:
	report.append("%s fps=%d draw=%d objs=%d prims=%d" % [label, Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])

func capture_title() -> void:
	var scene = load(TITLE).instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 90:
		await process_frame
	await snap("titulo")
	measure("titulo")
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func bot_step(stage, t: float) -> void:
	var b = stage.bee
	var half: float = BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(stage.get_viewport()))
	b.global_position.x = stage.distance - half * (0.55 + 0.2 * sin(t * 0.5))
	b.global_position.y = 3.2 + sin(t * 0.8) * 1.6
	if int(t * 10) % 2 == 0:
		b.fire()

func clear_stuck(stage, half: float) -> void:
	for target in get_nodes_in_group("bee_auto_aim_targets"):
		var body := target as Node3D
		if body == null or absf(body.global_position.x - stage.distance) > half:
			continue
		var health = body.get_node_or_null("HealthComponent")
		if health == null and body.get_parent() != null:
			health = body.get_parent().get_node_or_null("HealthComponent")
		if health is HealthComponent:
			health.take_damage(6)

func capture_level() -> void:
	var stage = load(LEVEL).instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8:
		await physics_frame
	stage.bee.health.damage_blocked = true
	Engine.time_scale = SPEED
	var t := 0.0
	var k := 0
	var last_distance := 0.0
	var stuck := 0.0
	var guard := 0.0
	while k < DISTANCES.size() and guard < 900.0:
		await physics_frame
		t += Engine.time_scale / 60.0
		guard += 1.0 / 60.0
		bot_step(stage, t)
		var half: float = BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(stage.get_viewport()))
		if absf(stage.distance - last_distance) > 0.01:
			last_distance = stage.distance
			stuck = 0.0
		stuck += Engine.time_scale / 60.0
		if stuck > 3.0 and int(t * 10) % 3 == 0:
			clear_stuck(stage, half)
		if stage.distance >= DISTANCES[k]:
			await snap("nivel_x%03d" % int(DISTANCES[k]))
			measure("nivel_x%03d" % int(DISTANCES[k]))
			k += 1
	root.remove_child(stage)
	stage.queue_free()
	Engine.time_scale = 1.0
	for i in 3:
		await process_frame

## Salta a un jefe (como F9 / el checkpoint) y saca fotos a tiempo de juego.
func capture_boss(x: float, label: String, times: Array) -> void:
	var stage = load(LEVEL).instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8:
		await physics_frame
	stage.bee.health.damage_blocked = true
	var wave = stage.wave
	stage.distance = x
	wave.resume_after_checkpoint(x)
	stage._update_camera_and_bounds()
	if label == "tarantula":
		wave._start_tarantula()
	Engine.time_scale = 2.0
	var t := 0.0
	var started := -1.0
	var k := 0
	var guard := 0.0
	while k < times.size() and guard < 240.0:
		await physics_frame
		t += Engine.time_scale / 60.0
		guard += 1.0 / 60.0
		bot_step(stage, t)
		var boss = wave.miniboss if label == "robot" else wave.tarantula
		if is_instance_valid(boss) and started < 0.0:
			started = t
		if started >= 0.0 and t - started >= float(times[k]):
			await snap("%s_%02ds" % [label, int(times[k])])
			measure("%s_%02ds" % [label, int(times[k])])
			k += 1
	report.append("%s capturas=%d x=%.1f" % [label, k, stage.distance])
	root.remove_child(stage)
	stage.queue_free()
	Engine.time_scale = 1.0
	for i in 3:
		await process_frame
