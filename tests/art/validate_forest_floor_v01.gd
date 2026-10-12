extends "res://tests/art/validate_future_biomes_v09.gd"
const IDS := ["hollow_fallen_log","forest_fern","garden_bellflower"]
func run() -> void:
	for id in IDS:
		var visual = load("res://scenes/art_labs/forest_floor_v01/"+id+".tscn").instantiate()
		root.add_child(visual)
		await settle()
		var meshes = visual.find_children("*","MeshInstance3D",true,false)
		check(meshes.size()==1,"Prop must have one batched mesh: "+id)
		check(visual.find_child("AlienControlDevice",true,false)==null,"Natural prop has alien controller: "+id)
		var triangles := 0
		for mesh: MeshInstance3D in meshes:
			for surface in mesh.mesh.get_surface_count():
				triangles += mesh.mesh.surface_get_array_index_len(surface)/3
				var material := mesh.get_surface_override_material(surface) as ShaderMaterial
				check(material!=null and material.next_pass!=null,"Toon/outline missing: "+id)
				if material!=null:
					var energy: Variant = material.get_shader_parameter("emission_energy")
					check(energy==null or is_zero_approx(float(energy)),"Natural prop emits: "+id)
		check(triangles<=3800 and triangles>0,"Prop budget exceeded: "+id)
		if id=="hollow_fallen_log":
			check(visual.find_child("HollowEntrance",true,false)!=null,"Log entrance marker missing")
		print("FOREST_PROP: ",id," / ",triangles," triangles")
		visual.queue_free()
		await settle()
	var lab = load("res://scenes/art_labs/forest_floor_v01.tscn").instantiate()
	root.add_child(lab)
	await settle()
	check(lab.stage.get_child_count()==3,"Studio must show three props")
	lab.show_garden()
	await settle()
	check(lab.stage.find_child("BeeScaleReference",true,false)!=null,"Garden missing Bee scale reference")
	for id in IDS:
		check(lab.stage.find_child(id,true,false)!=null,"Garden missing prop: "+id)
	for id in IDS:
		lab.show_single(id,false,true)
		await settle()
		check(not lab.ui.visible and lab.stage.get_child_count()==1,"Dirty concept sheet: "+id)
	lab.queue_free()
	await settle()
	print("FOREST_FLOOR_VALIDATION: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
