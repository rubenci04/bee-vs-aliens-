extends SceneTree

func _initialize() -> void:
	call_deferred("validate")

func validate() -> void:
	var lab: Node3D = load("res://dev/asset_review/asset_review_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	assert(lab.metrics.size() == 5)
	for data: Dictionary in lab.metrics:
		assert(data.meshes > 0)
		assert(data.materials > 0)
	var output := FileAccess.open("res://dev/asset_review/metrics.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(lab.metrics, "\t"))
	output.close()
	for path in ["res://scenes/bee_prototype/bee_garden_poc.tscn", "res://scenes/bee_prototype/bee_combat_poc.tscn"]:
		var scene: PackedScene = load(path)
		assert(scene != null)
		var instance := scene.instantiate()
		assert(instance != null)
		instance.free()
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://dev/asset_review/asset_review_lab.png")
		assert(error == OK)
	print("ASSET_REVIEW: 5 resources + Garden + Combat PASS")
	lab.queue_free()
	await process_frame
	quit(0)
