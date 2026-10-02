extends SceneTree
## DEV ONLY. Renders Bee at several sunset positions and measures her luminance contrast against
## the surrounding background (Bee mask = pixels that change when Bee is hidden).
## Run WITHOUT --headless: godot --path . --resolution 1152x648 --script res://dev/polish/capture_sunset_contrast.gd -- <prefix>
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const SHOTS := [270.0, 310.0, 350.0]

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func lum(c: Color) -> float:
	return 0.2126 * c.srgb_to_linear().r + 0.7152 * c.srgb_to_linear().g + 0.0722 * c.srgb_to_linear().b

func run() -> void:
	var prefix: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "contrast"
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	var wave := stage.wave as BeeLevel01Controller
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").controls_hint.hide()
	stage.get_node("CanvasLayer").hide()
	var total := 0.0
	for x: float in SHOTS:
		for unit in wave.active_units.duplicate():
			wave.active_units.erase(unit)
			unit.queue_free()
		stage.distance = x
		stage._update_camera_and_bounds()
		for y in [1.6, 3.0, 4.6]:
			stage.bee.global_position = Vector3(x - 1.0, y, 0)
			stage.bee.visible = true
			await frames(10)
			await RenderingServer.frame_post_draw
			var with_bee := root.get_texture().get_image()
			stage.bee.visible = false
			await frames(3)
			await RenderingServer.frame_post_draw
			var without := root.get_texture().get_image()
			var mask := {}
			var bee_lum := 0.0
			var count := 0
			for py in with_bee.get_height():
				for px in with_bee.get_width():
					var a := with_bee.get_pixel(px, py)
					var b := without.get_pixel(px, py)
					if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.06:
						mask[Vector2i(px, py)] = true
						bee_lum += lum(a)
						count += 1
			var ring := 0.0
			var ring_count := 0
			for p: Vector2i in mask:
				for d in [Vector2i(-7, 0), Vector2i(7, 0), Vector2i(0, -7), Vector2i(0, 7)]:
					var q: Vector2i = p + d
					if not mask.has(q) and q.x >= 0 and q.y >= 0 and q.x < without.get_width() and q.y < without.get_height():
						ring += lum(without.get_pixel(q.x, q.y))
						ring_count += 1
			if count < 30 or ring_count == 0:
				print("CONTRAST x=%d y=%.1f bee pixels=%d (not visible)" % [x, y, count])
				continue
			var lb := bee_lum / count
			var lg := ring / ring_count
			var ratio := (maxf(lb, lg) + 0.05) / (minf(lb, lg) + 0.05)
			total += ratio
			print("CONTRAST x=%d y=%.1f bee_lum=%.3f bg_lum=%.3f contrast_ratio=%.2f" % [x, y, lb, lg, ratio])
			if y == 3.0:
				with_bee.save_png("res://dev/polish/%s_x%d.png" % [prefix, int(x)])
	print("CONTRAST_MEAN_RATIO ", snappedf(total / 9.0, 0.01))
	quit(0)
