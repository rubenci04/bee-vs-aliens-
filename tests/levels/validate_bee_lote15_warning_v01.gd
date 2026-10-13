extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await process_frame
	var visual_was_enabled := BeeGameSettings.SHOT_WARNING_VISUAL_ENABLED
	var audio_was_enabled := BeeGameSettings.SHOT_WARNING_AUDIO_ENABLED
	var edge_was_enabled := BeeGameSettings.SHOT_WARNING_EDGE_ENABLED
	BeeGameSettings.SHOT_WARNING_VISUAL_ENABLED = false
	BeeGameSettings.SHOT_WARNING_AUDIO_ENABLED = false
	BeeGameSettings.SHOT_WARNING_EDGE_ENABLED = true
	var shooter := Node3D.new()
	shooter.position = stage.camera.global_position + (-stage.camera.global_transform.basis.z) * 20.0 + stage.camera.global_transform.basis.x * 100.0
	stage.add_child(shooter)
	BeeShotWarning.begin(shooter, &"fly_green")
	var layer := shooter.get_child(0) as CanvasLayer if shooter.get_child_count() > 0 else null
	var arrow := layer.get_child(0) as Polygon2D if layer != null and layer.get_child_count() > 0 else null
	check(is_instance_valid(arrow), "Off-camera shooter creates an edge arrow")
	if is_instance_valid(arrow):
		var bounds := stage.get_viewport().get_visible_rect().size
		check(arrow.color == BeeGameSettings.HOSTILE_CYAN, "Off-camera arrow uses the hostile cyan")
		check(arrow.position.x >= BeeGameSettings.SHOT_WARNING_EDGE_MARGIN and arrow.position.x <= bounds.x - BeeGameSettings.SHOT_WARNING_EDGE_MARGIN, "Arrow stays within horizontal screen margins")
		check(arrow.polygon.size() == 3, "Edge cue is a directional triangle")
	check(BeeGameSettings.SHOT_WARNING_SECONDS >= 0.25 and BeeGameSettings.SHOT_WARNING_SECONDS <= 0.4, "Telegraph is within requested timing")
	check(BeeGameSettings.SHOT_WARNING_SOUND_SECONDS >= 0.08 and BeeGameSettings.SHOT_WARNING_SOUND_SECONDS <= 0.15, "Warning cue duration is within requested range")
	BeeGameSettings.SHOT_WARNING_VISUAL_ENABLED = visual_was_enabled
	BeeGameSettings.SHOT_WARNING_AUDIO_ENABLED = audio_was_enabled
	BeeGameSettings.SHOT_WARNING_EDGE_ENABLED = edge_was_enabled
	print("LOTE15 WARNING failures=", failures)
	quit(1 if failures else 0)
