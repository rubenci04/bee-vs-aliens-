extends SceneTree
## DEV ONLY. Renders review captures of the first 60 m of Level 01 with Bee, a Wasp,
## a Probe and nearby pollen in frame. Gameplay is frozen; nothing is saved to the level.
## Run WITHOUT --headless:
##   godot --path . --resolution 1152x648 --script res://dev/visual_target/capture_visual_target.gd -- <prefix>

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const SHOTS := [10.0, 30.0, 50.0]

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Captures need a rendering window; run without --headless")
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else "after"
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
	for x: float in SHOTS:
		for unit in wave.active_units.duplicate():
			wave.active_units.erase(unit)
			unit.queue_free()
		stage.distance = x
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(x - 2.2, 3.0, 0)
		for spec in [["Wasp", Vector3(x + 2.4, 4.3, 0)], ["Probe", Vector3(x + 3.4, 1.9, 0)]]:
			wave._spawn({"family": spec[0], "slot": 0, "event": 0, "hard": false})
			var unit: Node3D = wave.active_units.back()
			unit.global_position = spec[1]
			unit.set_physics_process(false)
		await frames(12)
		await RenderingServer.frame_post_draw
		var path := "res://dev/visual_target/%s_x%02d.png" % [prefix, int(x)]
		var err := root.get_texture().get_image().save_png(path)
		print("CAPTURE ", path, " err=", err)
	quit(0)
