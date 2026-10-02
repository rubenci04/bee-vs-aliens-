extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func run() -> void:
	var stage = load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	var scenery = stage.get_node("Scenery")
	print("FLORA_COUNTS ", JSON.stringify(scenery.flower_counts))
	print("SCENERY_TOTAL ", scenery.get_child_count())
	for asset in scenery.FLOWER_VARIANTS:
		var sample: Node3D = asset.instantiate()
		root.add_child(sample)
		var bounds := AABB()
		var first := true
		for mesh: MeshInstance3D in sample.find_children("*", "MeshInstance3D", true, false):
			var box: AABB = sample.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		print("FLORA_SIZE ", asset.resource_path.get_file(), " ", bounds.size)
		sample.queue_free()
	if DisplayServer.get_name() == "headless":
		quit(0)
		return
	var views = [[10.0,"01_start"],[28.0,"02_multicolor_cluster"],[55.0,"03_log_area"],[143.0,"04_human_area"],[198.0,"05_alien_area"],[324.0,"06_final"]]
	var recovered_x := 135.0
	for prop: Node3D in scenery.get_children():
		if prop.find_child("Petal0", true, false) != null:
			recovered_x = prop.global_position.x
			if recovered_x > 125:
				break
	views.append([recovered_x,"07_recovered_old_flower"])
	views.append([29.0,"08_promoted_kenney_variants"])
	for view in views:
		stage.distance = float(view[0])
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(stage.distance - 2.0, 3.8, 0)
		stage.section_label.text = "FLORA REVIEW · " + str(view[1])
		var human = stage.get_node("GiantHuman")
		human.set_physics_process(false)
		human.visual_root.hide()
		if str(view[1]) == "04_human_area":
			human.global_position = Vector3(stage.distance + 2, 0, 0)
			human.visual_root.show()
			human.animation_player.play("Run")
			human.animation_player.seek(0.2, true)
			human.animation_player.pause()
			stage.bee.global_position = Vector3(stage.distance + 2, 0.9, 0)
		await frames(5)
		var error := root.get_viewport().get_texture().get_image().save_png("res://dev/level_01_flora_review/" + str(view[1]) + ".png")
		if error != OK:
			push_error("Flora capture failed")
			quit(1)
			return
	print("FLORA_REVIEW_OK captures=8")
	quit(0)
