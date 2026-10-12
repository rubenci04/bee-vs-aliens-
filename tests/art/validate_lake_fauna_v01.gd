extends "res://tests/art/validate_future_biomes_v09.gd"
func run() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/lake_fauna_v01/manifest.json"))
	for entry in manifest.assets:
		var visual = load("res://scenes/art_labs/lake_fauna_v01/"+entry.id+".tscn").instantiate()
		root.add_child(visual)
		await settle()
		var device: Node3D = visual.find_child("AlienControlDevice",true,false)
		var fauna: Node3D = visual.find_child("NaturalFauna",true,false)
		var count := 0
		for mesh: MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
			for s in mesh.mesh.get_surface_count():
				count += mesh.mesh.surface_get_array_index_len(s)/3
				var mat := mesh.get_surface_override_material(s) as ShaderMaterial
				check(mat!=null and mat.next_pass!=null,"Toon/outline missing: "+entry.id)
				var energy: Variant = mat.get_shader_parameter("emission_energy")
				if energy!=null and float(energy)>0:
					check(device!=null and device.is_ancestor_of(mesh),"Alien glow outside device: "+entry.id)
		check(count==int(entry.triangles) and count<5000,"Budget mismatch: "+entry.id)
		check(FileAccess.file_exists("res://"+entry.source),"Editable source missing: "+entry.id)
		if entry.emissive:
			check(device!=null and fauna!=null,"Removable device separation missing")
			var prefix := "StriderLeg_*" if entry.id=="controlled_water_strider" else "NymphLeg_*"
			check(visual.find_children(prefix,"Node3D",true,false).filter(func(n): return not n is MeshInstance3D).size()==6,"Six natural legs required")
			visual.release_control()
			check(not device.visible and fauna.visible,"Liberation lost anatomy")
		else:
			check(device==null,"Natural roots must not carry a controller")
		visual.queue_free()
		await settle()
	print("LAKE_FAUNA_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
