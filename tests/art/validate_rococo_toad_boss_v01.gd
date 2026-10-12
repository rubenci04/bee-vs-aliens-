extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	var model := load("res://scenes/art_labs/rococo_toad_boss_v01/controlled.tscn").instantiate() as Node3D
	model.preview_motion = false
	root.add_child(model)
	await process_frame
	var triangles := 0
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size() / 3
			var mat := mesh.get_surface_override_material(surface) as ShaderMaterial
			check(mat != null and mat.next_pass != null, "Missing toon/outline " + mesh.name)
			var energy: Variant = mat.get_shader_parameter("emission_energy")
			check(energy == null or float(energy) == 0 or mesh.name.begins_with("implant"), "Natural anatomy emits: " + mesh.name)
	check(triangles == 11992 and triangles <= 12000, "Triangle budget mismatch")
	check(model.find_children("*", "CollisionObject3D", true, false).is_empty(), "Art asset adds gameplay collision")
	for anchor in ["Muzzle_L", "Muzzle_R", "TongueAnchor", "TongueTipAnchor", "ImplantAnchor", "GroundAnchor"]:
		check(model.find_child(anchor,true,false) != null, "Missing anchor " + anchor)
	for leg in ["Foreleg_L", "Foreleg_R", "Hindleg_L", "Hindleg_R"]:
		check(model.find_child(leg,true,false) != null, "Missing anatomical leg " + leg)
	var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
	for clip in ["idle", "hop", "plasma_fire", "tongue_attack"]:
		check(player.has_animation(clip), "Missing clip " + clip)
	model.play_clip("hop")
	player.pause()
	player.seek(0,true)
	var body := model.find_child("BodyPivot",true,false) as Node3D
	var initial_y := body.position.y
	player.seek(0.8,true)
	check(body.position.y > initial_y + 1.0, "Hop does not lift body")
	model.play_clip("plasma_fire")
	player.pause()
	player.seek(0,true)
	var cannon := model.find_child("implant_CannonPivot_L",true,false) as Node3D
	var rest_x := cannon.position.x
	player.seek(0.75,true)
	check(cannon.position.x > rest_x + 0.15, "Cannon has no recoil")
	model.play_clip("tongue_attack")
	player.pause()
	player.seek(0,true)
	var tip := model.find_child("TongueTipAnchor",true,false) as Node3D
	var resting_tip := tip.global_position
	player.seek(1.25,true)
	check(tip.global_position.distance_to(resting_tip) > 6.0, "Tongue does not extend six metres")
	player.seek(2.4,true)
	check(tip.global_position.distance_to(resting_tip) < 0.05, "Tongue does not retract")
	model.release_control()
	for part: Node3D in model.find_children("implant*", "Node3D",true,false):
		check(not part.is_visible_in_tree(), "Armor remains after liberation " + part.name)
	check((model.find_child("body",true,false) as Node3D).is_visible_in_tree(), "Liberation hides animal")
	var freed := load("res://scenes/art_labs/rococo_toad_boss_v01/liberated.tscn").instantiate() as Node3D
	check(freed.find_children("implant*","Node3D",true,false).is_empty(), "Freed GLB contains implants")
	freed.free()
	var lab := load("res://scenes/art_labs/rococo_toad_boss_v01.tscn").instantiate() as Node3D
	root.add_child(lab)
	await process_frame
	lab._spawn_plasma(lab.get_node("Controlled").find_child("Muzzle_L",true,false))
	lab._spawn_plasma(lab.get_node("Controlled").find_child("Muzzle_R",true,false))
	check(lab.shots.size() == 2, "Twin plasma preview missing")
	lab._process(1.3)
	check(lab.shots.is_empty(), "Plasma preview does not expire")
	print("ROCOCO_TOAD_VALIDATION triangles=", triangles, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
