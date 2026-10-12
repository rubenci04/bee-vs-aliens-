extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	var heights: Array[float] = []
	for variant in ["worm_rose","worm_compost","mushroom_button","mushroom_umbrella","mushroom_spotted"]:
		var worm: bool = variant.begins_with("worm")
		var model := load("res://scenes/art_labs/garden_floor_v01/"+variant+".tscn").instantiate() as Node3D
		model.preview_motion = false
		root.add_child(model)
		await process_frame
		var triangles := 0
		var bounds := AABB()
		var first := true
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
				var mat := mesh.get_surface_override_material(surface) as ShaderMaterial
				check(mat != null and mat.next_pass != null,"Missing toon/outline")
				var energy: Variant = mat.get_shader_parameter("emission_energy")
				check(energy == null or float(energy)==0 or (worm and mesh.name.begins_with("implant")),"Unexpected emission")
		check(triangles<=(5000 if worm else 2000),"Budget exceeded")
		check(bounds.position.y>=-.025,"Geometry below base")
		check(model.find_children("*","CollisionObject3D",true,false).is_empty(),"Art adds physics")
		var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
		var clip := "crawl" if worm else "sway"
		check(player.has_animation("idle") and player.has_animation(clip),"Missing clips")
		model.play_clip(clip)
		player.pause()
		player.seek(0,true)
		var part := model.find_child("Segment_00" if worm else "MushroomPivot",true,false) as Node3D
		var rest := part.transform
		player.seek(.4,true)
		check(not part.transform.is_equal_approx(rest),"Animation stationary")
		if worm:
			check(model.find_children("Segment_*","Node3D",true,false).size()==(16 if variant=="worm_rose" else 12),"Wrong segment count")
			check(player.has_animation("recoil"),"Missing reaction clip")
			check(model.find_child("ImplantAnchor",true,false)!=null,"Missing implant anchor")
			model.release_control()
			for node: Node3D in model.find_children("implant*","Node3D",true,false):
				check(not node.is_visible_in_tree(),"Technology not removable")
			check((model.find_child("worm_segment_00",true,false) as Node3D).is_visible_in_tree(),"Liberation hides anatomy")
			var freed := load("res://scenes/art_labs/garden_floor_v01/"+variant+"_liberated.tscn").instantiate() as Node3D
			check(freed.find_children("implant*","Node3D",true,false).is_empty(),"Freed GLB contains technology")
			freed.free()
		else:
			heights.append(bounds.size.y)
			check(model.find_children("implant*","Node3D",true,false).is_empty(),"Natural mushroom has alien tech")
			check(model.find_child("BaseAnchor",true,false)!=null and model.find_child("CapAnchor",true,false)!=null,"Missing mushroom anchors")
			if variant=="mushroom_spotted":check(model.find_children("cap_spot_*","MeshInstance3D",true,false).size()==6,"Missing natural spots")
		print("GARDEN_FLOOR ",variant," triangles=",triangles," bounds=",bounds.size)
		model.queue_free()
	check(heights[0]<heights[1] and heights[1]<heights[2],"Three different size tiers required")
	var lab: Node3D = load("res://scenes/art_labs/garden_floor_v01.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	print("GARDEN_FLOOR_VALIDATION failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
