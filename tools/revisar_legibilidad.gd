extends SceneTree
## Rendered development fixture: real Level 01, real enemy scenes and projectile factories.
## --script res://tools/revisar_legibilidad.gd -- --debug-readability
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const SIZE := Vector2i(1154, 648)
const WARMUP_SECONDS := 2.0
const SAMPLE_SECONDS := 6.0
var stage: BeeShmupStage
var live: Node
var enemies: Array[Node3D] = []
var fixture_shots: Array[Node3D] = []
var caption: Label

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func setup_case(index: int) -> void:
	for shot in fixture_shots:
		if is_instance_valid(shot):
			shot.queue_free()
	fixture_shots.clear()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	await frames(2)
	var progress: float = [80.0, 110.0, 310.0][index]
	stage.distance = progress
	stage._update_camera_and_bounds()
	stage.get_node("LightProgression").apply_distance(progress)
	stage.bee.global_position = Vector3(progress - 3.0, 3.4, 0)
	stage.bee.facing_x = 1.0
	var families: Array = [["FlyCloud", "FlyCloud", "FlyCloud", "FlyCommon", "FlyCommon", "FlyCommon", "FlyCommon"], ["Ant", "Ant", "Ant", "Ant", "Ant"], ["Wasp", "Wasp", "Wasp", "Wasp"]][index]
	for i in families.size():
		stage.wave._spawn({"family": families[i], "slot": i % 3, "event": 900 + index, "hard": false})
		var enemy := (stage.wave as BeeLevel01Controller).active_units.back() as Node3D
		enemy.global_position = Vector3(progress + 0.5 + float(i % 3) * 2.2, 0.0 if index == 1 else 1.6 + float(i / 3) * 1.7, 0)
		enemy.set_physics_process(false)
		enemies.append(enemy)
	await frames(25)
	for enemy in enemies:
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.show()
	var style: StringName = [&"pellet", &"pebble", &"stinger"][index]
	for i in 7:
		var shot := preload("res://scenes/projectiles/toon/alien_bolt.tscn").instantiate() as AlienEnemyProjectile
		shot.set_meta("shot_style", style)
		stage.add_child(shot)
		shot.global_position = Vector3(progress - 1.3 + float(i) * 0.82, 0.5 if index == 1 else 1.9 + float(i % 3) * 1.1, 0)
		shot.set_physics_process(false)
		shot.hitbox.set_enabled(false)
		fixture_shots.append(shot)
	for i in 5:
		var shot := stage.bee._spawn_projectile(Vector3.RIGHT)
		shot.global_position = Vector3(progress - 2.0 + float(i) * 0.8, 3.4, 0)
		shot.set_physics_process(false)
		shot.hitbox.set_enabled(false)
		fixture_shots.append(shot)
	await frames(8)

func sample_seconds(seconds: float) -> float:
	var start := Time.get_ticks_usec()
	var count := 0
	while (Time.get_ticks_usec() - start) / 1000000.0 < seconds:
		await process_frame
		count += 1
	return count * 1000000.0 / float(Time.get_ticks_usec() - start)

func bee_width() -> float:
	var model: Node3D = stage.bee.get_node("VisualRoot/BeeVisual").get("model")
	var left := INF
	var right := -INF
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var box := mesh.get_aabb()
		for x in [0, 1]:
			for y in [0, 1]:
				for z in [0, 1]:
					var point := mesh.to_global(box.position + box.size * Vector3(x, y, z))
					var screen := stage.camera.unproject_position(point)
					left = minf(left, screen.x)
					right = maxf(right, screen.x)
	return right - left

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Render fixture requires a GPU window, not headless")
		quit(1)
		return
	root.size = SIZE
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(10)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	live = stage.get_node("LiveReadability")
	var canvas := CanvasLayer.new()
	canvas.layer = 22
	stage.add_child(canvas)
	caption = Label.new()
	caption.position = Vector2(610, 12)
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_constant_override("outline_size", 4)
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	canvas.add_child(caption)
	var composite := Image.create(SIZE.x * 2, SIZE.y * 3, false, Image.FORMAT_RGBA8)
	var widths := []
	for index in 3:
		await setup_case(index)
		for after in [false, true]:
			live.set_modes(1 if after else 0, 1 if after else 0, 1 if after else 0, 1 if after else 0)
			caption.text = ("DESPUÉS · " if after else "ANTES · ") + ["Enjambre / día", "Hormigas / día", "Avispas / noche"][index]
			await frames(20)
			await RenderingServer.frame_post_draw
			var picture := root.get_texture().get_image()
			picture.convert(Image.FORMAT_RGBA8)
			composite.blit_rect(picture, Rect2i(Vector2i.ZERO, SIZE), Vector2i(SIZE.x if after else 0, index * SIZE.y))
			widths.append({"case": index, "after": after, "bee_bounds_width_px": bee_width()})
	var error := composite.save_png("res://docs/legibilidad_antes_despues.png")
	assert(error == OK)
	print("CAPTURA_OK docs/legibilidad_antes_despues.png")
	await setup_case(0)
	caption.text = "BENCH · enjambre fijo / render sin VSync"
	var results := []
	# Paired repeated samples, same scene/poses/shots; differences are presentation only.
	# Rotate the order so warm-up/clock changes do not always favor the same mode.
	var orders := [[0, 1, 2], [2, 0, 1], [1, 2, 0]]
	for pass_index in orders.size():
		for mode in orders[pass_index]:
			live.set_modes(mode, mode, mode, mode)
			await sample_seconds(WARMUP_SECONDS)
			var fps := await sample_seconds(SAMPLE_SECONDS)
			results.append({"pass": pass_index, "mode": mode, "fps": fps})
			print("FPS mode=", mode, " pass=", pass_index, " mean=", snappedf(fps, 0.1))
	var report := {"resolution": SIZE, "vsync": false, "scene": "3 FlyCloud + 4 FlyCommon, 7 hostile + 5 Bee shots, frozen poses", "warmup_seconds": WARMUP_SECONDS, "sample_seconds": SAMPLE_SECONDS, "measurements": results, "bee_bounds": widths}
	var file := FileAccess.open("res://dev/legibilidad_fps.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	quit(0)
