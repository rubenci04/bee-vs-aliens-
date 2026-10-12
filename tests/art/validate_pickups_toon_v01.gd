extends "res://tests/art/validate_future_biomes_v09.gd"
func run() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/pickups_toon_v01/manifest.json"))
	for entry in manifest.assets:
		var visual = load("res://scenes/art_labs/pickups_toon_v01/"+entry.id+".tscn").instantiate()
		root.add_child(visual)
		await settle()
		var count := 0
		var meshes: Array = visual.find_children("*","MeshInstance3D",true,false)
		check(meshes.size()==1,"Pickup should use one mesh stream: "+entry.id)
		for mesh: MeshInstance3D in meshes:
			for s in mesh.mesh.get_surface_count():
				count += mesh.mesh.surface_get_array_index_len(s)/3
				var mat := mesh.get_surface_override_material(s) as ShaderMaterial
				check(mat!=null and mat.next_pass!=null,"Toon/outline absent: "+entry.id)
				var energy: Variant = mat.get_shader_parameter("emission_energy")
				check(energy==null or float(energy)==0,"Natural pickup must not emit: "+entry.id)
		check(count==int(entry.triangles) and count<4000,"Pickup triangle budget mismatch: "+entry.id)
		visual.queue_free()
		await settle()
	print("PICKUPS_TOON_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
