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
	for variant in ["crater","side_tunnel"]:
		var model := load("res://scenes/art_labs/anthills_v01/"+variant+".tscn").instantiate() as Node3D
		root.add_child(model)
		await process_frame
		var triangles := 0
		var bounds := AABB()
		var first := true
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			var box: AABB = mesh.global_transform*mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
				var mat := mesh.get_surface_override_material(surface) as ShaderMaterial
				check(mat!=null and mat.next_pass!=null,"Missing toon/outline")
				check(bool(mat.get_shader_parameter("use_texture")),"Natural palette absent")
				var energy: Variant = mat.get_shader_parameter("emission_energy")
				check(energy==null or float(energy)==0,"Natural mound emits")
		check(triangles==(1336 if variant=="crater" else 1636) and triangles<=2000,"Triangle budget mismatch")
		check(bounds.position.y>=-.02,"Model below ground")
		heights.append(bounds.size.y)
		check(model.find_children("*","CollisionObject3D",true,false).is_empty(),"Art prop adds gameplay collision")
		check(model.find_children("*","AnimationPlayer",true,false).is_empty(),"Static prop has unnecessary animation")
		for anchor in ["BaseAnchor","EntranceAnchor","TunnelAnchor","GroundAnchor","BodyAnchor"]:
			check(model.find_child(anchor,true,false)!=null,"Missing anchor "+anchor)
		# Ray against actual triangles: the first surface must be recessed inside the
		# entrance, so a dark painted disk cannot satisfy this check.
		var entrance := model.find_child("EntranceAnchor",true,false) as Node3D
		var tunnel := model.find_child("TunnelAnchor",true,false) as Node3D
		var direction := (tunnel.global_position-entrance.global_position).normalized()
		var start := entrance.global_position-direction
		var end := tunnel.global_position+direction*2
		var soil := model.find_child("soil_mound",true,false) as MeshInstance3D
		var closest := INF
		for surface in soil.mesh.get_surface_count():
			var arrays := soil.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for i in range(0,indices.size(),3):
				var hit: Variant = Geometry3D.segment_intersects_triangle(start,end,soil.global_transform*vertices[indices[i]],soil.global_transform*vertices[indices[i+1]],soil.global_transform*vertices[indices[i+2]])
				if hit!=null:closest=minf(closest,start.distance_to(hit))
		check(closest<INF and closest>1.20,"Entrance has no real recessed cavity: "+variant)
		print("ANTHILL ",variant," triangles=",triangles," height=",bounds.size.y," entrance_ray_depth=",closest-1)
		model.queue_free()
	check(heights[1]>heights[0]*2,"Two distinct height profiles required")
	var lab: Node3D = load("res://scenes/art_labs/anthills_v01.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	print("ANTHILLS_VALIDATION failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
