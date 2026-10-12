extends "res://tests/art/validate_future_biomes_v09.gd"
func run() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/garden_backdrop_v01/manifest.json"))
	for entry in manifest.assets:
		check(FileAccess.file_exists("res://"+entry.source),"Editable source missing: "+entry.id)
		var visual = load("res://scenes/art_labs/garden_backdrop_v01/"+entry.id+".tscn").instantiate()
		root.add_child(visual)
		await settle()
		var count := 0
		for mesh: MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
			for s in mesh.mesh.get_surface_count():
				count += mesh.mesh.surface_get_array_index_len(s)/3
				var material := mesh.get_surface_override_material(s) as ShaderMaterial
				check(material!=null and material.next_pass!=null,"Toon/outline missing: "+entry.id)
				var energy: Variant = material.get_shader_parameter("emission_energy")
				check(energy==null or float(energy)==0,"Natural garden prop must not emit: "+entry.id)
		check(count==int(entry.triangles) and count<5000,"Triangle budget mismatch: "+entry.id)
		visual.queue_free()
		await settle()
	print("GARDEN_BACKDROP_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
