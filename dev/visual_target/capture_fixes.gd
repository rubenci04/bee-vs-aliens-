extends SceneTree
## DEV ONLY. Level 01 frames at given scroll positions, frozen (no enemies), for the visual-anomaly fixes.
## Run WITHOUT --headless: godot --path . --resolution 1152x648 --script res://dev/visual_target/capture_fixes.gd -- <prefix> <x1,x2,...>
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else "fix"
	var xs: PackedStringArray = (args[1] if args.size() > 1 else "20,124").split(",")
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").controls_hint.hide()
	for x_text in xs:
		var x := float(x_text)
		stage.distance = x
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(x - 2.5, 3.0, 0)
		await frames(15)
		await RenderingServer.frame_post_draw
		print("CAPTURE ", root.get_texture().get_image().save_png("res://dev/visual_target/%s_x%d.png" % [prefix, int(x)]))
	quit(0)
