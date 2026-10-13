extends SceneTree
## Dev tool (LOTE 14 · ETAPA 3): lists the solid / large objects of Level 1 near the flight plane (z in [-1.5, 1.5]) with their X range and height.
func _initialize():
	call_deferred("run")
func run():
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage = load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 6:
		await physics_frame
	var rows := []
	for node in stage.find_children("*", "Node3D", true, false):
		var box := AABB()
		var has := false
		if node.get_child_count() > 0 and not (node is MeshInstance3D) and node.get_parent() != null:
			for c in node.find_children("*", "MeshInstance3D", true, false):
				var m := c as MeshInstance3D
				var b: AABB = m.global_transform * m.get_aabb()
				box = b if not has else box.merge(b)
				has = true
		if not has:
			continue
		if box.position.z > 1.6 or box.end.z < -1.6:
			continue
		if box.size.y < 0.9 or box.size.x < 0.8 or box.size.x > 40.0:
			continue
		rows.append([box.position.x, box.end.x, box.position.y, box.end.y, box.position.z, box.end.z, str(node.get_path()).trim_prefix(str(stage.get_path()) + "/")])
	rows.sort_custom(func(a, b): return a[0] < b[0])
	for r in rows:
		print("SOLID x=[%.1f,%.1f] y=[%.1f,%.1f] z=[%.1f,%.1f] %s" % r)
	quit(0)
