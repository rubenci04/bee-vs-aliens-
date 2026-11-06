extends SceneTree
## Mejora visual · Etapa 3: el MISMO instante del nivel visto con cada cámara (necesita ventana).
## Uso: godot --path . --script res://dev/mejora_visual/camera_compare.gd -- <carpeta>
const RIG := preload("res://scripts/levels/bee_camera_rig.gd")
const LEVEL := "res://scenes/levels/bee_level_01_vertical_slice.tscn"
const STOPS := [45.0, 120.0, 215.0]
## [nombre, giro, inclinación, FOV]
const VIEWS := [["A_lateral", 0.0, 5.0, 1.0], ["B_25D_suave", 12.0, 4.5, 1.07], ["C_25D_fuerte", 26.0, 4.0, 1.22]]
var folder := "camara"
var stage

func _initialize() -> void:
	call_deferred("run")

var reaim := Callable()

func snap(label: String) -> void:
	for i in 3:
		await process_frame
		if reaim.is_valid():
			reaim.call() # El escenario repone la cámara en cada tick de física: se reorienta justo antes de dibujar.
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa_screenshots/%s/%s.png" % [folder, label])

func clear_stuck(half: float) -> void:
	for target in get_nodes_in_group("bee_auto_aim_targets"):
		var body := target as Node3D
		if body == null or absf(body.global_position.x - stage.distance) > half:
			continue
		var health = body.get_node_or_null("HealthComponent")
		if health == null and body.get_parent() != null:
			health = body.get_parent().get_node_or_null("HealthComponent")
		if health is HealthComponent:
			health.take_damage(6)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	folder = args[0] if args.size() > 0 else folder
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_screenshots/" + folder))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	stage = load(LEVEL).instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8:
		await physics_frame
	stage.bee.health.damage_blocked = true
	Engine.time_scale = 3.0
	var t := 0.0
	var stuck := 0.0
	var last := 0.0
	for stop in STOPS:
		while stage.distance < stop:
			await physics_frame
			t += Engine.time_scale / 60.0
			var half: float = BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(stage.get_viewport()))
			stage.bee.global_position.x = stage.distance - half * (0.55 + 0.2 * sin(t * 0.5))
			stage.bee.global_position.y = 3.2 + sin(t * 0.8) * 1.6
			if int(t * 10) % 2 == 0:
				stage.bee.fire()
			if absf(stage.distance - last) > 0.01:
				last = stage.distance
				stuck = 0.0
			stuck += Engine.time_scale / 60.0
			if stuck > 3.0 and int(t * 10) % 3 == 0:
				clear_stuck(half)
		await capture_stop(int(stop))
	# Bordes: dónde caen en pantalla los límites de vuelo con cada vista.
	Engine.time_scale = 1.0
	quit(0)

func capture_stop(x: int) -> void:
	Engine.time_scale = 0.0
	var camera: Camera3D = stage.camera
	var keep_transform := camera.global_transform
	var keep_fov := camera.fov
	for view in VIEWS:
		var yaw: float = view[1]
		reaim = func(): RIG.aim(camera, yaw, view[2], 0.0, Vector3(camera.global_position.x - yaw * 0.075, RIG.center_y_on_plane(), 0.0), BeeLevel01Framing.effective_fov() * float(view[3]))
		await snap("x%03d_%s" % [x, view[0]])
		reaim.call()
		print(view[0], " ", corners(camera))
	reaim = Callable()
	# D: desde atrás, sobre el hombro. Solo para la foto: otra Camera3D en el mismo instante.
	var back := Camera3D.new()
	root.add_child(back)
	var S := preload("res://scripts/game/bee_camera_settings.gd")
	var bee_pos: Vector3 = stage.bee.global_position
	back.global_position = bee_pos + Vector3(-S.BACK_DISTANCE, S.BACK_HEIGHT, S.BACK_SIDE)
	back.look_at(bee_pos + Vector3(6.0, 0.2, 0.0), Vector3.UP)
	back.fov = S.BACK_FOV
	back.make_current()
	await snap("x%03d_D_atras" % x)
	camera.make_current()
	back.queue_free()
	camera.global_transform = keep_transform
	camera.h_offset = 0.0
	camera.v_offset = 0.0
	camera.fov = keep_fov
	Engine.time_scale = 3.0

## Fracción de pantalla (0 = centro, 1 = borde) a la que cae cada esquina de la zona de vuelo.
func corners(camera: Camera3D) -> String:
	var size := Vector2(1280, 720)
	var out := ""
	var d: float = stage.distance
	for p in [Vector2(d + stage.screen_left, stage.flight_top), Vector2(d + stage.screen_left, stage.flight_bottom), Vector2(d + stage.screen_right, stage.flight_top), Vector2(d + stage.screen_right, stage.flight_bottom)]:
		var s := camera.unproject_position(Vector3(p.x, p.y, 0.0))
		out += "(%.2f,%.2f) " % [(s.x - size.x * 0.5) / (size.x * 0.5), (s.y - size.y * 0.5) / (size.y * 0.5)]
	return out
