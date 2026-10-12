extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	var model := load("res://scenes/art_labs/giant_heron_v01/controlled.tscn").instantiate() as Node3D
	model.preview_motion = false
	root.add_child(model)
	await process_frame
	var triangles := 0
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
			var mat := mesh.get_surface_override_material(surface) as ShaderMaterial
			check(mat != null and mat.next_pass != null,"Missing toon/outline: " + mesh.name)
			var energy: Variant = mat.get_shader_parameter("emission_energy")
			check(energy == null or float(energy) == 0 or mesh.name.begins_with("implant"),"Emissive natural anatomy")
	check(triangles == 5964 and triangles <= 6000,"Triangle budget mismatch")
	var joint_names: Array[String] = ["BodyPivot","NeckBase","NeckMid","NeckUpper","HeadPivot","JawPivot","TailPivot"]
	for side in ["L","R"]:
		for family in ["WingShoulder","WingElbow","WingWrist","LegHip","LegKnee","LegAnkle","ToePivot"]:
			joint_names.append(family+"_"+side)
		check(model.find_child("WindAnchor_"+side,true,false) != null,"Missing wind anchor")
	check(model.find_child("BeakTipAnchor",true,false) != null,"Missing beak tip anchor")
	var moved := {}
	var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
	for clip in ["idle","walk","fly","wind_attack","peck_attack"]:
		check(player.has_animation(clip),"Missing clip " + clip)
		model.play_clip(clip)
		player.pause()
		player.seek(0,true)
		var rest := {}
		for name in joint_names:
			var node := model.find_child(name,true,false) as Node3D
			check(node != null,"Missing joint " + name)
			rest[name] = node.transform
		player.seek(player.current_animation_length*.55,true)
		for name in joint_names:
			var node := model.find_child(name,true,false) as Node3D
			if not node.transform.is_equal_approx(rest[name]):
				moved[name] = true
	for name in joint_names:
		check(moved.has(name),"Joint never moves: " + name)
	model.play_clip("peck_attack")
	player.pause()
	player.seek(0,true)
	var beak := model.find_child("BeakTipAnchor",true,false) as Node3D
	var rest_tip := beak.global_position
	player.seek(.88,true)
	check(beak.global_position.distance_to(rest_tip) > 0.6,"Picotazo does not reach")
	model.release_control()
	for part: Node3D in model.find_children("implant*","Node3D",true,false):
		check(not part.is_visible_in_tree(),"Implant visible after liberation")
	check((model.find_child("body",true,false) as Node3D).is_visible_in_tree(),"Animal hidden")
	check(model.find_children("*","CollisionObject3D",true,false).is_empty(),"Art adds gameplay physics")
	var freed := load("res://scenes/art_labs/giant_heron_v01/liberated.tscn").instantiate() as Node3D
	check(freed.find_children("implant*","Node3D",true,false).is_empty(),"Liberated export includes foreign tech")
	freed.free()
	var lab := load("res://scenes/art_labs/giant_heron_v01.tscn").instantiate() as Node3D
	root.add_child(lab)
	await process_frame
	lab.spawn_wind(Vector3.ZERO)
	check(lab.gusts.size()==3,"Wind trails missing")
	lab._process(1.5)
	check(lab.gusts.is_empty(),"Wind does not expire")
	print("GIANT_HERON_VALIDATION triangles=",triangles," joints=",moved.size()," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
