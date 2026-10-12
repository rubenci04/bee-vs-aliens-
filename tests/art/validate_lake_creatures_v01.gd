extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	for variant in ["turtle","salamander","mosquito_cloud"]:
		var model := load("res://scenes/art_labs/lake_creatures_v01/"+variant+".tscn").instantiate() as Node3D
		model.preview_motion = false
		root.add_child(model)
		await process_frame
		var triangles := 0
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
				var mat := mesh.get_surface_override_material(surface) as ShaderMaterial
				check(mat != null and mat.next_pass != null,"Missing toon/outline")
				var energy: Variant = mat.get_shader_parameter("emission_energy")
				check(energy == null or float(energy)==0 or mesh.name.begins_with("implant"),"Natural emissive piece")
		check(triangles<=5000,"Triangle budget per enemy exceeded")
		check(triangles=={"turtle":4908,"salamander":4112,"mosquito_cloud":4680}[variant],"Unexpected instance triangle count")
		check(model.find_children("*","CollisionObject3D",true,false).is_empty(),"Art asset adds physics")
		var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
		for clip in ["idle","swim","attack","liberate"]:
			check(player.has_animation(clip),"Missing clip "+clip)
		model.play_clip("swim")
		player.pause()
		player.seek(0,true)
		var name := "WingPivot_00_L" if variant=="mosquito_cloud" else "Leg_L_Front"
		var part := model.find_child(name,true,false) as Node3D
		var pose := part.transform
		player.seek(.13,true)
		check(not part.transform.is_equal_approx(pose),"Limb/wing does not move")
		if variant=="mosquito_cloud":
			var body := model.find_child("mosquito_body_00",true,false) as MeshInstance3D
			var box: AABB = body.global_transform * body.get_aabb()
			check(box.size.x > .65 and box.size.y > .30,"Imported mosquito anatomy/part transforms collapsed")
			check(model.find_children("Mosquito_*","Node3D",true,false).size()==6,"Need six original-derived mosquitoes")
			check(model.find_children("WingPivot_*","Node3D",true,false).size()==12,"Need two wings each")
			var a := model.find_child("Mosquito_00",true,false) as Node3D
			var b := model.find_child("Mosquito_01",true,false) as Node3D
			var delta_pos := a.position-b.position
			player.seek(.7,true)
			check(not (a.position-b.position).is_equal_approx(delta_pos),"Cloud lacks independent motion")
		else:
			check(model.find_children("Leg_*","Node3D",true,false).size()==4,"Animal must have four limbs")
			check(model.find_child("ImplantAnchor",true,false)!=null,"Missing implant anchor")
			if variant=="salamander":
				for tail in ["TailBase","TailMid","TailTip"]:
					check(model.find_child(tail,true,false)!=null,"Missing tail articulation")
		model.release_control()
		for node: Node3D in model.find_children("implant*","Node3D",true,false):
			check(not node.is_visible_in_tree(),"Technology not removable")
		var freed := load("res://scenes/art_labs/lake_creatures_v01/"+variant+"_liberated.tscn").instantiate() as Node3D
		check(freed.find_children("implant*","Node3D",true,false).is_empty(),"Liberated GLB has technology")
		freed.free()
		print("LAKE_CREATURES ",variant," triangles=",triangles)
		model.queue_free()
	var lab: Node3D = load("res://scenes/art_labs/lake_creatures_v01.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	print("LAKE_CREATURES_VALIDATION failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
