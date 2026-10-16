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
	for i in 2:
		await process_frame
	var checkpoints := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	var marker := checkpoints.beacon_2
	check(marker.get_node_or_null("CheckpointFlower") != null, "Second checkpoint uses an existing garden flower asset")
	check(marker.get_node_or_null("BeaconStem") == null, "Second checkpoint no longer uses the plain post marker")
	check(marker.get_node_or_null("CheckpointRing") == null and checkpoints.beacon.get_node_or_null("CheckpointRing") == null, "Tanda A removes both legacy rings")
	check(checkpoints.beacon.get_node_or_null("BeaconStem") != null, "Checkpoint 1 retains its original beacon")
	print("LOTE17 CHECKPOINT failures=", failures)
	quit(1 if failures else 0)
