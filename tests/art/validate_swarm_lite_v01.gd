extends "res://tests/art/validate_future_biomes_v09.gd"
func run() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/swarm_lite_v01/manifest.json"))
	for entry in data.assets:
		var id: String = entry.id
		var packed := load("res://scenes/art_labs/swarm_lite_v01/"+id+".tscn") as PackedScene
		var visual := packed.instantiate() as Node3D
		root.add_child(visual)
		await settle()
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		check(meshes.size()==2,"Expected two independently removable mesh streams: "+id)
		var count := 0
		for node: MeshInstance3D in meshes:
			for surface in node.mesh.get_surface_count():
				count += node.mesh.surface_get_array_index_len(surface)/3
				var material := node.get_surface_override_material(surface) as ShaderMaterial
				check(material!=null,"Toon missing: "+id)
				if material!=null and material.shader!=BeeToonStyle.WING:
					check(material.next_pass!=null,"Outline missing: "+id)
		check(count>=4500 and count<=5500,"Triangle budget exceeded: "+id+" "+str(count))
		check(count==int(entry.glb_triangles),"Manifest mismatch: "+id)
		var device := visual.find_child("AlienControlDevice",true,false) as Node3D
		var animal := visual.find_child("NaturalFauna",true,false) as Node3D
		check(device!=null and animal!=null,"Separation missing: "+id)
		visual.release_control()
		check(not device.visible and animal.visible,"Release lost anatomy: "+id)
		visual.queue_free()
		await settle()
	var lab = load("res://scenes/art_labs/swarm_lite_v01.tscn").instantiate()
	root.add_child(lab)
	await settle()
	check(lab.stage.get_child_count()==4,"Catalog incomplete")
	lab.queue_free()
	await settle()
	print("SWARM_LITE_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
