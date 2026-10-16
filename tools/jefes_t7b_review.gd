extends SceneTree
const SIZE := Vector2i(1154, 648)
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func picture(path: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	root.size = SIZE
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("Juice").set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 294
	stage.bee.global_position = Vector3(291, 4, 0)
	stage.wave._spawn({"family":"Walker", "slot":0, "event":77, "hard":true, "miniboss":true})
	var robot := stage.wave.miniboss as WalkerMiniboss
	robot.set_physics_process(false)
	robot.global_position = Vector3(294, -0.2, 0)
	robot.visual_root.rotation.y = -PI * 0.25
	robot.visual_root.position.y = -0.25
	for i in 45: stage._update_camera_and_bounds()
	await picture("res://docs/robot_t7b_despues.png")
	robot.health.current_health = 0
	robot.hide()
	robot._bar_layer.hide()
	for i in 45: stage._update_camera_and_bounds()
	stage.wave._start_tarantula()
	var boss := stage.wave.tarantula as TarantulaBoss01
	boss.set_physics_process(false)
	boss._enter_fight()
	boss._change_state(TarantulaBoss01.State.PHASE_2)
	boss._hint_label.hide() # Pose captions replace the temporary phase instruction in this review only.
	boss.health.damage_blocked = false
	boss.side = 1
	boss.mode = &"hang"
	boss._swing = 0.5
	boss.hang_pivot_x = 295
	boss.global_position = Vector3(294, 4.3, 0)
	boss._apply_pose()
	var caption := Label.new()
	caption.position = Vector2(380, 130)
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_constant_override("outline_size", 5)
	stage.get_node("CanvasLayer").add_child(caption)
	var montage := Image.create(SIZE.x * 2, SIZE.y * 2, false, Image.FORMAT_RGBA8)
	for i in 4:
		if i == 1: boss._end_hang()
		if i == 2: boss._update_hang_return(TarantulaBoss01.HANG_UP * 0.5)
		if i == 3: boss._update_hang_return(TarantulaBoss01.HANG_UP * 0.5 + 0.00001)
		caption.text = ["Colgada: volumen dentro del margen", "Inicio del retorno: misma pose", "Retorno: posición y giro interpolados", "Techo: pose final sin salto"][i]
		await frames(3)
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.convert(Image.FORMAT_RGBA8)
		montage.blit_rect(image, Rect2i(Vector2i.ZERO, SIZE), Vector2i((i % 2) * SIZE.x, (i / 2) * SIZE.y))
	montage.save_png("res://docs/tarantula_t7b_regreso.png")
	print("T7B_REVIEW_COMPLETE")
	quit()
