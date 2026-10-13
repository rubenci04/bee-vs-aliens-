extends SceneTree
## Dev tool (LOTE 14 · ETAPA 3): saves dev/visual_target/lote14_<label>_x<N>.png for a few X positions of Level 1 (no director, Bee idle).
## Usage (needs a window, so NOT headless): godot --path . --resolution 1280x720 --script res://dev/lote14/capture_level.gd -- label=before [x=10,40,...]
const DEFAULT_XS := [6.0, 41.0, 56.0, 100.0, 143.0, 176.0, 215.0, 265.0, 284.0]
func _initialize():
	call_deferred("run")
func run():
	var label := "shot"
	var xs: Array = DEFAULT_XS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("label="):
			label = arg.get_slice("=", 1)
		if arg.begins_with("x="):
			xs = []
			for part in arg.get_slice("=", 1).split(","):
				xs.append(float(part))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage = load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8:
		await physics_frame
	stage.wave.set_physics_process(false)
	stage.scroll_speed = 0.0
	stage.bee.health.damage_blocked = true
	for x in xs:
		stage.distance = x
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(x - 3.2, 3.4, 0)
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://dev/visual_target/lote14_%s_x%d.png" % [label, int(x)]
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		print("CAPTURED ", path)
	quit(0)
