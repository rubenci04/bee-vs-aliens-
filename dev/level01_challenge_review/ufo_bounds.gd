extends SceneTree
## DEV ONLY. Visible bounds of the UFO meshes (boss local space, at rest) vs its hurtbox.
func _initialize() -> void:
	var boss: Node3D = load("res://scenes/levels/ufo_boss_01.tscn").instantiate()
	root.add_child(boss)
	await process_frame
	await process_frame
	var inv := boss.global_transform.affine_inverse()
	for part in boss.get_node("VisualRoot").get_children():
		if part is MeshInstance3D:
			var b: AABB = inv * (part.global_transform * part.get_aabb())
			print("PART ", part.name, " x[%.2f,%.2f] y[%.2f,%.2f] z[%.2f,%.2f]" % [b.position.x, b.end.x, b.position.y, b.end.y, b.position.z, b.end.z])
	var total := AABB()
	var first := true
	for part in boss.get_node("VisualRoot").get_children():
		if part is MeshInstance3D:
			var b: AABB = inv * (part.global_transform * part.get_aabb())
			total = b if first else total.merge(b)
			first = false
	print("TOTAL x[%.2f,%.2f] y[%.2f,%.2f] z[%.2f,%.2f]" % [total.position.x, total.end.x, total.position.y, total.end.y, total.position.z, total.end.z])
	var hb: CollisionShape3D = boss.get_node("Hurtbox3D/CollisionShape3D")
	print("HURTBOX pos=", hb.position, " size=", (hb.shape as BoxShape3D).size, " VisualRoot scale=", boss.get_node("VisualRoot").scale, " pos=", boss.get_node("VisualRoot").position)
	quit(0)
