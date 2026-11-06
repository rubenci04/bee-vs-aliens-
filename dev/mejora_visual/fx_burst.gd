extends SceneTree
## Saca una ráfaga de fotos de los efectos nuevos: liberación, explosión, golpe a Bee y telarañas fijas (con ventana).
const LEVEL := "res://scenes/levels/bee_level_01_vertical_slice.tscn"
var folder := "fx"
func _initialize() -> void:
	call_deferred("run")
func snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa_screenshots/%s/%s.png" % [folder, label])
func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_screenshots/" + folder))
	var stage = load(LEVEL).instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8:
		await physics_frame
	stage.bee.health.damage_blocked = true
	await create_timer(1.0).timeout
	while paused or stage.distance < 0.0:
		await process_frame # La escena corta del arranque pausa el juego.
	await create_timer(6.0).timeout
	while paused:
		await process_frame
	stage.wave.set_physics_process(false)
	stage.distance = 100.0
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(97.0, 3.6, 0.0)
	for i in 30:
		await process_frame
	# Liberación y explosión lado a lado.
	BeeFx.liberation(stage, Vector3(100.0, 4.2, 0.0), false)
	BeeFx.explosion(stage, Vector3(104.0, 3.0, 0.0), 1.2)
	BeeFx.hit(stage, Vector3(97.0, 2.0, 0.0), Vector3.RIGHT)
	for i in 5:
		await process_frame
	await snap("efectos_t1")
	for i in 9:
		await process_frame
	await snap("efectos_t2")
	for i in 20:
		await process_frame
	await snap("efectos_t3")
	# Telarañas fijas de noche.
	stage.distance = 340.5
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(336.5, 3.0, 0.0)
	stage.wave._start_tarantula()
	var spider = stage.wave.tarantula
	for x_off in [1.5, -3.5, 4.5]:
		TarantulaWebNet.place_sticky(stage, spider, stage.bee, Vector3(340.5 + x_off, 3.8 + x_off * 0.15, 0.0))
	await create_timer(1.3).timeout
	await snap("telaranas")
	quit(0)
