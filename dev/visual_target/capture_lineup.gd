extends SceneTree
## DEV ONLY. Renders every Level 01 enemy family (style C) in two light conditions.
## Run WITHOUT --headless: godot --path . --resolution 1152x648 --script res://dev/visual_target/capture_enemies.gd -- <prefix>

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
# [family, x offset from camera, y]
const LINEUP_A := [["Swarm", -4.0, 4.0], ["Spider", -1.5, 5.0], ["Dragonfly", 2.0, 4.0], ["Walker", 5.0, -0.2], ["OrganicAlien", 5.0, 3.0], ["Turret", -3.0, -0.2], ["Speeder", 1.0, 2.0]]

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else "enemies"
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
	for x: float in [120.0]:
		for unit in stage.get_node("Enemies").get_children():

			unit.queue_free()
		stage.distance = x
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(x - 6.0, 3.0, 0)
		for spec in LINEUP_A:
			wave._spawn({"family": spec[0], "slot": 0, "event": 0, "hard": false})
			var unit: Node3D = stage.get_node("Enemies").get_child(-1)
			unit.global_position = Vector3(x + spec[1], spec[2], 0)
			unit.set_physics_process(false)
		await frames(15)
		await RenderingServer.frame_post_draw
		print("CAPTURE ", root.get_texture().get_image().save_png("res://dev/visual_target/%s_lineup_x%d.png" % [prefix, int(x)]))
	quit(0)
