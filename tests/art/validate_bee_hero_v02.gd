extends SceneTree
const V01_SHA := "2ef72672d95d8b1bef063982321c504db676c2e3e8f49842eae9a0c37fdc7264"
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	check(FileAccess.get_sha256("res://assets/models/shared/bee/bee_mid_poly.glb")==V01_SHA,"Bee v01 was modified")
	for version in ["full","lite"]:
		var model := load("res://scenes/art_labs/bee_hero_v02/"+version+".tscn").instantiate() as Node3D
		model.preview_motion=false
		root.add_child(model)
		await process_frame
		var imported := model.get_node("Model") as Node3D
		check(imported.transform.is_equal_approx(Transform3D.IDENTITY),"Native model root must preserve origin, rotation and scale")
		var triangles := 0
		var bounds := AABB()
		var first := true
		var source_materials := {}
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			var box: AABB=mesh.global_transform*mesh.get_aabb()
			bounds=box if first else bounds.merge(box)
			first=false
			check(mesh.scale.is_equal_approx(Vector3.ONE),"Unapplied mesh scale: "+mesh.name)
			check(mesh.rotation.is_zero_approx(),"Unapplied mesh rotation: "+mesh.name)
			for surface in mesh.mesh.get_surface_count():
				triangles+=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
				var source := mesh.mesh.surface_get_material(surface) as BaseMaterial3D
				source_materials[source.resource_name]=true
				var color := source.albedo_color
				check(not (color.b>.45 and color.b>color.r*1.25),"Bright blue/cyan in hero")
				check(not source.emission_enabled or mesh.name=="blaster_muzzle_gold","Emission outside muzzle: "+mesh.name)
				if source.resource_name=="Wing":
					check(source.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED and color.a<.6,"Wings must be translucent")
				var styled := mesh.get_surface_override_material(surface) as ShaderMaterial
				check(styled!=null,"Missing game toon")
		check(source_materials.size()==6,"Must use exactly six materials")
		check(triangles>=16000 and triangles<=18000 if version=="full" else triangles<=6000,"Triangle budget mismatch")
		check(absf(bounds.size.z-1.4)<.03,"Visual length must remain ~1.4m with legacy scale")
		for name in ["Thorax","Head","Abdomen","Eye_L","Eye_R","Brow_L","Brow_R","Wing_L","Wing_R","AntennaBase_L","AntennaBase_R","AntennaTip_L","AntennaTip_R","Stinger","stinger_drill","stinger_tip","thruster_L","thruster_R","nozzle_L","nozzle_R","antenna_R_blaster","muzzle","helmet_socket","plates"]:
			check(model.find_child(name,true,false)!=null,"Missing part/anchor "+name)
		for side in ["L","R"]:
			for i in range(3):
				for half in ["Upper","Lower"]:check(model.find_child("Leg_%s_%d_%s"%[side,i,half],true,false)!=null,"Missing legacy leg")
			var nozzle := model.find_child("nozzle_"+side,true,false) as Node3D
			check((-nozzle.global_basis.z.normalized()).dot(Vector3.BACK)>.99,"Nozzle must point backward")
		var muzzle := model.find_child("muzzle",true,false) as Node3D
		check((-muzzle.global_basis.z.normalized()).dot(Vector3.FORWARD)>.99,"Muzzle must point forward")
		check(model.find_children("*","CollisionObject3D",true,false).is_empty(),"Art model adds gameplay collision")
		var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
		for clip in ["wingbeat","drill_spin"]:
			check(player.has_animation(clip) and is_equal_approx(player.get_animation(clip).length,.5),"Wrong clip duration")
		model.play_clip("wingbeat")
		player.pause();player.seek(0,true)
		var wing := model.find_child("Wing_L",true,false) as Node3D
		var rest := wing.transform
		player.seek(.015625,true)
		check(not wing.transform.is_equal_approx(rest),"Wingbeat does not move hinge")
		model.play_clip("drill_spin")
		player.pause();player.seek(0,true)
		var drill := model.find_child("stinger_drill",true,false) as Node3D
		rest=drill.transform
		player.seek(.125,true)
		check(not drill.transform.is_equal_approx(rest),"Drill axis does not rotate")
		print("BEE_HERO_V02 ",version," triangles=",triangles," visual_bounds=",bounds)
		model.queue_free()
	var lab: Node3D=load("res://scenes/art_labs/bee_hero_v02.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	print("BEE_HERO_V02_VALIDATION failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
