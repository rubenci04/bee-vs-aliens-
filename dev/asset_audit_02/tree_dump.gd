extends SceneTree
## DEV ONLY (ASSET LIBRARY DEEP AUDIT 02). Prints the node tree of models passed as user args.
##   godot --headless --path . --script res://dev/asset_audit_02/tree_dump.gd -- <path> [<path>...]

func _initialize() -> void:
	for path in OS.get_cmdline_user_args():
		var scene: Node
		if path.begins_with("res://"):
			scene = (load(path) as PackedScene).instantiate()
		else:
			var state: GLTFState = FBXState.new() if path.to_lower().ends_with(".fbx") else GLTFState.new()
			var doc: GLTFDocument = FBXDocument.new() if path.to_lower().ends_with(".fbx") else GLTFDocument.new()
			doc.append_from_file(path, state)
			scene = doc.generate_scene(state)
		print("=== ", path.get_file())
		dump(scene, 0)
		scene.free()
	quit(0)

func dump(node: Node, depth: int) -> void:
	if depth > 4:
		return
	var extra := ""
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		extra = " surfaces=%d" % (node as MeshInstance3D).mesh.get_surface_count()
	if node is Skeleton3D:
		var names := []
		for i in mini((node as Skeleton3D).get_bone_count(), 40):
			names.append((node as Skeleton3D).get_bone_name(i))
		extra = " bones=" + ",".join(names)
	if node is AnimationPlayer:
		extra = " root=" + str((node as AnimationPlayer).root_node) + " clips=" + str((node as AnimationPlayer).get_animation_list().size())
	if node is Node3D:
		extra += " scale=" + str((node as Node3D).scale)
	print("  ".repeat(depth), node.name, " <", node.get_class(), ">", extra)
	for child in node.get_children():
		dump(child, depth + 1)
