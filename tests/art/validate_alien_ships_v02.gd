extends "res://tests/art/validate_future_biomes_v09.gd"
const IDS := ["alien_needle_interceptor","alien_armoured_bomber"]
func run() -> void:
	for id in IDS:
		var model = load("res://scenes/art_labs/alien_ships_v02/"+id+".tscn").instantiate()
		root.add_child(model)
		await settle()
		var meshes = model.find_children("*","MeshInstance3D",true,false)
		check(meshes.size()==1,"Ship must have one batched mesh: "+id)
		var triangles := 0
		var energy_surfaces := 0
		for mesh: MeshInstance3D in meshes:
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_array_index_len(surface)/3
				var material := mesh.get_surface_override_material(surface) as ShaderMaterial
				check(material!=null and material.next_pass!=null,"Toon/outline missing: "+id)
				if material == null:
					continue
				var energy: Variant = material.get_shader_parameter("emission_energy")
				if energy != null and float(energy)>0:
					energy_surfaces += 1
					check(float(energy)<=0.65,"Compatibility emission too bright: "+id)
		check(energy_surfaces==2,"Cyan and violet energy surfaces required: "+id)
		check(triangles<=5000 and triangles>=4000,"Ship triangle budget failed: "+id)
		var markers := ["CoreTarget","EngineLeft","EngineRight"]
		markers.append("Muzzle" if id==IDS[0] else "BombDropLeft")
		if id==IDS[1]:
			markers.append("BombDropRight")
		for marker in markers:
			check(model.find_child(marker,true,false)!=null,"Marker missing: "+id+"/"+marker)
		if id==IDS[0]:
			check(model.find_child("Muzzle",true,false).position.x<0,"Cannon must face -X")
		else:
			check(model.find_child("BombDropLeft",true,false).position.y<0,"Payload marker must be below hull in Godot")
		model.face_right(true)
		check(is_equal_approx(model.rotation.y,PI),"Facing switch failed: "+id)
		print("ALIEN_SHIP: ",id," / ",triangles," triangles")
		model.queue_free()
		await settle()
	var lab = load("res://scenes/art_labs/alien_ships_v02.tscn").instantiate()
	root.add_child(lab)
	await settle()
	check(lab.stage.get_child_count()==2,"Catalog must show two ships")
	lab.toggle_control()
	for ship in lab.stage.get_children():
		check(ship.find_child("AlienControlDevice",true,false).visible,"Ships must not use animal liberation toggle")
	for id in IDS:
		lab.show_single(id,false,true)
		await settle()
		check(not lab.ui.visible and lab.stage.get_child_count()==1,"Unclean ship concept view")
	lab.queue_free()
	await settle()
	print("ALIEN_SHIPS_V02_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
