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
	await _overlap_crop(stage, wave, prefix)
	await _human_shot(stage, wave, prefix)
	quit(0)


## Outline check: a projectile and a pollen right next to Bee, upscaled crop around her.
func _overlap_crop(stage: BeeShmupStage, wave: BeeLevel01Controller, prefix: String) -> void:
	for unit in wave.active_units.duplicate():
		wave.active_units.erase(unit)
		unit.queue_free()
	var x := 30.0
	stage.distance = x
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(x - 2.2, 3.0, 0)
	stage.bee.facing_x = 1.0
	var shot := stage.bee.fire()
	shot.set_physics_process(false)
	shot.global_position = stage.bee.global_position + Vector3(0.55, 0.0, 0.0)
	var pollen := stage.get_node("Pollen/PollenA") as Node3D
	pollen.global_position = stage.bee.global_position + Vector3(-0.5, 0.35, 0.1)
	await frames(12)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var centre := stage.camera.unproject_position(stage.bee.global_position)
	var crop := image.get_region(Rect2i(int(centre.x) - 90, int(centre.y) - 60, 180, 120))
	crop.resize(720, 480, Image.INTERPOLATE_NEAREST)
	print("CAPTURE overlap err=", crop.save_png("res://dev/visual_target/%s_overlap_crop.png" % prefix))
	shot.queue_free()


## Giant Human mid-crossing with Bee, Wasp and pollen in frame.
func _human_shot(stage: BeeShmupStage, wave: BeeLevel01Controller, prefix: String) -> void:
	var x := 30.0
	stage.distance = x
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(x - 3.0, 2.6, 0)
	wave._spawn({"family": "Wasp", "slot": 0, "event": 0, "hard": false})
	var unit: Node3D = wave.active_units.back()
	unit.global_position = Vector3(x + 5.0, 6.0, 0)
	unit.set_physics_process(false)
	var human := stage.get_node("GiantHuman") as GiantHumanCrossingHazard
	human.begin_crossing(stage.camera)
	stage.bee.global_position = Vector3(x - 3.0, 2.6, 0)
	for i in 600:
		await physics_frame
		if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING and human.global_position.x < x + 1.5:
			break
	human.set_physics_process(false)
	human.animation_player.pause()
	await frames(10)
	await RenderingServer.frame_post_draw
	print("CAPTURE human err=", root.get_texture().get_image().save_png("res://dev/visual_target/%s_human.png" % prefix))
