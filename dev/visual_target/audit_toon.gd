extends SceneTree
## DEV ONLY. Lists every visible MeshInstance3D / MultiMesh of Level 01 whose surface material is NOT a style C toon shader.
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var stage := LEVEL.instantiate()
	root.add_child(stage)
	for i in 5: await process_frame
	var counts := {}
	var toon_total := 0
	for n: MeshInstance3D in stage.find_children("*", "MeshInstance3D", true, false):
		if n.mesh == null or not n.is_visible_in_tree():
			continue
		for s in n.mesh.get_surface_count():
			var m: Material = n.get_surface_override_material(s)
			if m == null: m = n.material_override
			if m == null: m = n.mesh.surface_get_material(s)
			var kind := "none"
			if m is ShaderMaterial:
				var path: String = (m as ShaderMaterial).shader.resource_path
				kind = "TOON" if path.contains("toon_") else "shader:" + path.get_file()
			elif m != null:
				kind = m.get_class() + (":unshaded" if (m is BaseMaterial3D and (m as BaseMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED) else "")
			if kind == "TOON":
				toon_total += 1
				continue
			var parent := n.get_parent()
			var key := "%s  [%s / %s]" % [kind, str(parent.name).left(24), str(n.name).left(24)]
			counts[key] = int(counts.get(key, 0)) + 1
	print("TOON surfaces: ", toon_total)
	var keys := counts.keys()
	keys.sort()
	for k in keys:
		print("NONTOON ", counts[k], "x ", k)
	quit(0)
