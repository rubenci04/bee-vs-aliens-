extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	var model := load("res://scenes/art_labs/giant_spider_boss_v01/controlled.tscn").instantiate() as Node3D
	model.preview_motion = false
	root.add_child(model)
	await process_frame
	await process_frame
	var regex := RegEx.create_from_string("^leg_[LR]_[0-9][0-9]$")
	var legs := model.find_children("leg_*", "Node3D", true, false).filter(func(n): return regex.search(n.name) != null)
	check(legs.size() == 8, "Exactly eight anatomical leg pivots required")
	var triangles := 0
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
			var mat := mesh.get_surface_override_material(surface) as ShaderMaterial
			check(mat != null and mat.next_pass != null, "Toon shading and outline missing: " + mesh.name)
			var energy: Variant = mat.get_shader_parameter("emission_energy")
			check(energy == null or float(energy) == 0 or mesh.name == "implant_core", "Only alien core may emit: " + mesh.name)
			if mesh.name == "body":
				check(bool(mat.get_shader_parameter("use_texture")), "Embedded warm palette not mapped into toon")
	check(triangles == 11652 and triangles <= 12000, "Triangle budget mismatch")
	check(bounds.position.y >= -0.02 and bounds.size.x > 6.0 and bounds.size.y < 3.2, "Scale/base origin/Y-up incorrect")
	check(model.find_children("*", "CollisionObject3D", true, false).is_empty(), "Art asset must not add gameplay physics")
	for anchor in ["ImplantAnchor","MuzzleAnchor","BodyAnchor","SilkAnchor","GroundAnchor"]:
		check(model.find_child(anchor,true,false) != null, "Missing anchor " + anchor)
	var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
	for clip in ["idle","walk","attack"]:
		check(player.has_animation(clip), "Missing GLB animation " + clip)
	model.play_clip("walk")
	player.seek(0.25,true)
	var pose: Transform3D = legs[0].transform
	player.seek(0.7,true)
	check(not legs[0].transform.is_equal_approx(pose), "Walk does not animate legs")
	model.release_control()
	for part: Node3D in model.find_children("implant*", "Node3D",true,false):
		check(not part.is_visible_in_tree(), "Foreign plate still visible after liberation: " + part.name)
	check((model.find_child("body",true,false) as Node3D).is_visible_in_tree(), "Liberation hides natural anatomy")
	print("GIANT_SPIDER_BOSS_VALIDATION triangles=",triangles," bounds=",bounds," animations=",player.get_animation_list()," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
