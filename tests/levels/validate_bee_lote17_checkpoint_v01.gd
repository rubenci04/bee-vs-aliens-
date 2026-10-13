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
	var ring := marker.get_node_or_null("CheckpointRing") as MeshInstance3D
	check(ring != null and ring.mesh is TorusMesh, "Second checkpoint retains its torus ring")
	if ring != null:
		var material := ring.mesh.material as StandardMaterial3D
		check(material.albedo_color.is_equal_approx(BeeCheckpointQoL.BEACON_COLOR), "Checkpoint ring retains the yellow beacon color")
		check(is_equal_approx(ring.position.y, BeeGameSettings.CHECKPOINT_2_RING_HEIGHT), "Ring sits above the flower as a clear marker")
	check(checkpoints.beacon.get_node_or_null("BeaconStem") != null, "Checkpoint 1 retains its original beacon")
	print("LOTE17 CHECKPOINT failures=", failures)
	quit(1 if failures else 0)
