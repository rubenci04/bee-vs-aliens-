extends SceneTree
func _initialize() -> void:
	for path in OS.get_cmdline_user_args():
		var scene := (load(path) as PackedScene).instantiate()
		root.add_child(scene)
		print("== ", path)
		_dump(scene, 0)
		for p in scene.find_children("*", "AnimationPlayer", true, false):
			print("anims: ", (p as AnimationPlayer).get_animation_list())
	quit(0)
func _dump(n: Node, depth: int) -> void:
	if depth > 4: return
	var extra := ""
	if n is Node3D:
		extra = " pos=%s" % str((n as Node3D).position)
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		extra += " aabb=%s" % str((n as MeshInstance3D).mesh.get_aabb().size)
	print("  ".repeat(depth), n.name, " [", n.get_class(), "]", extra)
	for c in n.get_children():
		_dump(c, depth + 1)
