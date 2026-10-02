extends SceneTree
## DEV ONLY. Renders crates (litter) and rocks. Run WITHOUT --headless:
## godot --path . --resolution 1152x648 --script res://dev/polish/capture_props.gd -- <prefix>
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const SHOTS := [[14.0, "can"], [40.0, "matchbox"], [116.0, "snack"], [92.0, "rock"], [303.0, "rock_sunset"]]

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var prefix: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "props"
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	(stage.wave as Node).set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").controls_hint.hide()
	for shot in SHOTS:
		stage.distance = shot[0]
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(shot[0] - 3.5, 3.0, 0)
		await frames(10)
		await RenderingServer.frame_post_draw
		print("CAPTURE ", root.get_texture().get_image().save_png("res://dev/polish/%s_%s.png" % [prefix, shot[1]]))
	quit(0)
