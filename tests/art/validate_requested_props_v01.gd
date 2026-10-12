extends "res://tests/art/validate_future_biomes_v09.gd"
const BATCHES := ["pine_woods_v01","ground_litter_v01","ground_litter_v02","residential_sky_v01"]
func run() -> void:
	var total := 0
	for batch in BATCHES:
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/"+batch+"/manifest.json"))
		for entry in manifest.assets:
			var id: String = entry.id
			check(FileAccess.file_exists("res://"+entry.source),"Blender source missing: "+id)
			var visual = load("res://scenes/art_labs/"+batch+"/"+id+".tscn").instantiate()
			root.add_child(visual)
			await settle()
			var triangles := 0
			var meshes = visual.find_children("*","MeshInstance3D",true,false)
			check(meshes.size()==1,"Expected batched prop mesh: "+id)
			var glass_found := false
			var warm_found := false
			for mesh: MeshInstance3D in meshes:
				for surface in mesh.mesh.get_surface_count():
					triangles += mesh.mesh.surface_get_array_index_len(surface)/3
					var material := mesh.get_surface_override_material(surface) as ShaderMaterial
					check(material!=null,"Toon material missing: "+id)
					if material==null:
						continue
					if material.shader==preload("res://assets/style/toon_prop_glass.gdshader"):
						glass_found = true
						var tint: Color = material.get_shader_parameter("albedo")
						check(tint.a>0.3 and tint.a<0.8,"Glass must be translucent")
					else:
						check(material.next_pass!=null,"Toon outline missing: "+id)
					var energy: Variant = material.get_shader_parameter("emission_energy")
					if energy!=null and float(energy)>0:
						check(id=="warm_street_lamp","Unexpected prop emission: "+id)
						check(float(energy)<=0.22,"Street lamp emission too bright")
						var color: Color = material.get_shader_parameter("emission")
						check(color.r>color.g and color.g>color.b,"Street lamp must emit warm amber")
						warm_found = true
			check(triangles==int(entry.triangles) and triangles<=5000,"Triangle budget/import mismatch: "+id)
			if id=="glass_bottle":
				check(glass_found,"Bottle lost glass material")
				check(visual.find_child("BottleMouth",true,false)!=null,"Bottle mouth reference missing")
			if id=="warm_street_lamp":
				check(warm_found,"Street lamp lacks warm bulb")
				check(visual.find_child("WarmLightAnchor",true,false)!=null,"Lamp light anchor missing")
			print("REQUESTED_PROP: ",batch,"/",id," / ",triangles," triangles")
			total += 1
			visual.queue_free()
			await settle()
		var lab = load("res://scenes/art_labs/"+batch+".tscn").instantiate()
		root.add_child(lab)
		await settle()
		check(lab.stage.get_child_count()==manifest.assets.size(),"Incomplete catalog: "+batch)
		for id in lab.asset_ids:
			lab.show_single(id,false,true)
			await settle()
			check(not lab.ui.visible and lab.stage.get_child_count()==1,"Unclean prop sheet: "+id)
			var box: AABB = lab.bounds_of(lab.stage.get_child(0))
			check(box.get_center().length()<0.01,"Prop preview not centered: "+id)
			check(box.size.y<lab.camera.size,"Prop clipped vertically: "+id)
		lab.queue_free()
		await settle()
	check(total==12,"Requested set incomplete")
	print("REQUESTED_PROPS_VALIDATION: ",failures.size()," failures / ",total," assets")
	quit(0 if failures.is_empty() else 1)
