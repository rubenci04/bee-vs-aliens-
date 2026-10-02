extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var human = load("res://scenes/levels/giant_human_hazard.tscn").instantiate()
	root.add_child(human)
	var skeleton: Skeleton3D = human.get_node("VisualRoot/Hipster/Rig/Skeleton3D")
	for i in skeleton.get_bone_count():
		print("BONE ", i, " ", skeleton.get_bone_name(i))
	for time in [0.0, 0.2, 0.4, 0.6]:
		human.animation_player.play("Run")
		human.animation_player.seek(time, true)
		await process_frame
		for i in skeleton.get_bone_count():
			if "leg" in skeleton.get_bone_name(i).to_lower() or "foot" in skeleton.get_bone_name(i).to_lower():
				print("POSE ", time, " ", skeleton.get_bone_name(i), " ", skeleton.global_transform * skeleton.get_bone_global_pose(i).origin)
	quit()
