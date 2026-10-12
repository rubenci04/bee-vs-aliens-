extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	for variant in ["common","green","swarm"]:
		var model := load("res://scenes/art_labs/fly_trio_v01/"+variant+".tscn").instantiate() as Node3D
		model.preview_motion = false
		root.add_child(model)
		await process_frame
		var triangles := 0
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
				var mat := mesh.get_surface_override_material(surface) as ShaderMaterial
				check(mat != null and mat.next_pass != null,"Toon/outline missing")
				var energy: Variant = mat.get_shader_parameter("emission_energy")
				check(energy == null or float(energy)==0 or mesh.name.begins_with("implant"),"Natural emission")
		check(triangles == (4896 if variant=="swarm" else 4104),"Unexpected triangles "+variant)
		check(triangles<=5000,"Repetition budget exceeded")
		var count := 8 if variant=="swarm" else 1
		check(model.find_children("Fly_*","Node3D",true,false).size()==count,"Fly count mismatch")
		check(model.find_children("Wing_*","Node3D",true,false).size()==count*2,"Two wings per fly required")
		check(model.find_children("Leg_*","Node3D",true,false).size()==count*6,"Six legs per fly required")
		check(model.find_children("*","CollisionObject3D",true,false).is_empty(),"Art adds physics")
		var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
		for clip in ["hover","attack","liberate"]:
			check(player.has_animation(clip),"Missing clip " + clip)
		model.play_clip("hover")
		player.pause()
		player.seek(0,true)
		var wing := model.find_child("Wing_00_L",true,false) as Node3D
		var rest := wing.transform
		player.seek(.10,true)
		check(not wing.transform.is_equal_approx(rest),"Wings do not flap")
		if variant=="swarm":
			var a := model.find_child("Fly_00",true,false) as Node3D
			var b := model.find_child("Fly_01",true,false) as Node3D
			var offset := a.position-b.position
			player.seek(.65,true)
			check(not (a.position-b.position).is_equal_approx(offset),"Cloud is rigid instead of independently moving")
		model.release_control()
		for part: Node3D in model.find_children("implant*","Node3D",true,false):
			check(not part.is_visible_in_tree(),"Implant visible after release")
		check((model.find_child("abdomen_00",true,false) as Node3D).is_visible_in_tree(),"Release hides anatomy")
		var freed := load("res://scenes/art_labs/fly_trio_v01/"+variant+"_liberated.tscn").instantiate() as Node3D
		check(freed.find_children("implant*","Node3D",true,false).is_empty(),"Freed GLB contains technology")
		freed.free()
		model.queue_free()
		print("FLY_TRIO ",variant," triangles=",triangles," members=",count)
	var lab: Node3D = load("res://scenes/art_labs/fly_trio_v01.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	print("FLY_TRIO_VALIDATION failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
