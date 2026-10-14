extends SceneTree
const STYLE := preload("res://scripts/vfx/bee_warning_style.gd")
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const SIZE := Vector2i(1154, 648)
var stage: BeeShmupStage
var actors: Array[Node3D] = []
var extras: Array[Node] = []
var caption: Label

func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for tick in count: await process_frame

func setup_case(case: int, styled: bool) -> void:
	STYLE.enabled = styled
	for actor in actors: actor.free()
	actors.clear()
	for node in extras:
		if is_instance_valid(node): node.free()
	extras.clear()
	# The real attack creates visual warnings under stage: remove the previous case's visual samples only.
	for node in stage.get_children():
		if node is MeshInstance3D and node.has_meta("review_warning"): node.free()
	var previous := stage.get_children()
	if case == 0:
		var boss := preload("res://scenes/levels/tarantula_boss_01.tscn").instantiate() as TarantulaBoss01
		stage.add_child(boss)
		boss.begin(stage.camera, stage.bee)
		boss.global_position = Vector3(stage.camera.global_position.x + 3, -0.1, 0)
		boss._apply_pose()
		boss._begin_charge()
		boss.set_physics_process(false)
		actors.append(boss)
	elif case == 1:
		var robot := preload("res://scenes/levels/walker_miniboss.tscn").instantiate() as WalkerMiniboss
		stage.add_child(robot)
		robot.global_position = Vector3(stage.camera.global_position.x + 3, 0, 0)
		robot.activate(stage.bee)
		robot._begin_laser()
		robot._beam.show() # Review the active gradient alongside its prior warning edges.
		robot.set_physics_process(false)
		actors.append(robot)
	else:
		for offset in [-2.0, 2.0]:
			stage.wave._spawn({"family": "Ant" if offset < 0 else "WormA", "slot": 0, "event": 910, "hard": false})
			var enemy := stage.wave.active_units.back() as AssetFauna
			enemy.global_position = Vector3(stage.camera.global_position.x + offset, 0, 0)
			enemy.state = AssetFauna.State.IDLE
			enemy._start_telegraph()
			if offset > 0:
				enemy._worm._begin_mark()
			enemy.set_physics_process(false)
			actors.append(enemy)
	for node in stage.get_children():
		if node not in previous and node is MeshInstance3D:
			node.set_meta("review_warning", true)
			extras.append(node)
	caption.text = ["TARÁNTULA · banda de carga", "ROBOT · aviso + rayo celeste", "SUELO · hormiga / aviso de gusano A"][case]
	await frames(2)
	for actor in actors: actor.process_mode = Node.PROCESS_MODE_DISABLED

func sample(seconds: float) -> float:
	var start := Time.get_ticks_usec()
	var count := 0
	while float(Time.get_ticks_usec()-start)/1000000.0 < seconds:
		await process_frame
		count += 1
	return count * 1000000.0 / float(Time.get_ticks_usec()-start)

func run() -> void:
	root.size = SIZE
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	stage = LEVEL.instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.distance = 110
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(stage.camera.global_position.x - 3, 4, 0)
	var layer := CanvasLayer.new()
	stage.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(300, 75)
	caption.add_theme_font_size_override("font_size", 25)
	caption.add_theme_constant_override("outline_size", 5)
	layer.add_child(caption)
	for dark in [false, true]:
		stage.get_node("LightProgression").apply_distance(310 if dark else 80)
		var image := Image.create(SIZE.x, SIZE.y * 3, false, Image.FORMAT_RGBA8)
		for case in 3:
			await setup_case(case, true)
			await RenderingServer.frame_post_draw
			var picture := root.get_texture().get_image()
			picture.convert(Image.FORMAT_RGBA8)
			image.blit_rect(picture, Rect2i(Vector2i.ZERO, SIZE), Vector2i(0, SIZE.y * case))
		assert(image.save_png("res://docs/avisos_en_escena_%s.png" % ("noche" if dark else "dia")) == OK)
	if "--capture-only" in OS.get_cmdline_user_args():
		print("T3H_SCENES_CAPTURE_OK")
		quit()
		return
	var data := []
	for case in 3:
		for pass_index in 2:
			for styled in ([false, true] if pass_index == 0 else [true, false]):
				await setup_case(case, styled)
				await sample(1.0)
				var fps := await sample(3.0)
				data.append({"case":case,"styled":styled,"pass":pass_index,"fps":fps})
				print("T3H_FPS ", data.back())
	FileAccess.open("res://dev/t3h_fps.json",FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	var isolated := []
	for pass_index in 2:
		for mode in ([0,1,2,3] if pass_index == 0 else [3,2,1,0]):
			await setup_case(1, mode > 0)
			if mode >= 2:
				for node in stage.find_children("*", "MeshInstance3D", true, false):
					if not node.has_meta("warning_original_material"): continue
					var beam := int(node.get_meta("warning_style_mode",-1)) == 4
					if (mode == 2 and not beam) or (mode == 3 and beam):
						node.material_override = node.get_meta("warning_original_material")
			await sample(1.0)
			var fps := await sample(3.0)
			isolated.append({"pass":pass_index,"mode":mode,"fps":fps})
			print("T3H_ROBOT_ISOLATED ", isolated.back())
	FileAccess.open("res://dev/t3h_robot_fps.json",FileAccess.WRITE).store_string(JSON.stringify(isolated,"\t"))
	STYLE.enabled = true
	print("T3H_SCENES_OK")
	quit()
