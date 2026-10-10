extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func settle() -> void:
	await process_frame
	await process_frame

func run() -> void:
	var ids := ["coastal_rowboat","shore_wave_module","shore_rock"]
	for id in ids:
		var packed := load("res://scenes/art_labs/assets_v08/"+id+".tscn") as PackedScene
		check(packed != null,"Import missing: " + id)
		if packed == null:
			continue
		var visual := packed.instantiate() as Node3D
		root.add_child(visual)
		await settle()
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"Missing geometry: " + id)
		check(visual.find_child("AlienControlDevice",true,false) == null,"Environment has alien device: " + id)
		check(visual.find_children("*","Light3D",true,false).is_empty(),"Prop contains a light: " + id)
		for node: MeshInstance3D in meshes:
			check(node.mesh != null,"Null geometry: " + id)
			for surface in node.mesh.get_surface_count():
				var material := node.get_surface_override_material(surface) as ShaderMaterial
				check(material != null,"Missing toon: " + id)
				if material == null:
					continue
				check(material.next_pass != null,"Missing outline: " + id)
				var energy: Variant = material.get_shader_parameter("emission_energy")
				check(energy == null or float(energy)<=0,"Environment emits light: " + id)
		visual.release_control()
		for node: MeshInstance3D in meshes:
			check(node.is_visible_in_tree(),"Control state hid environment: " + id)
		match id:
			"coastal_rowboat":
				check(visual.find_child("HollowHull",true,false) != null,"Hollow hull missing")
				check(visual.find_child("Gunwale",true,false) != null,"Gunwale missing")
				check(visual.find_children("Bench_?","MeshInstance3D",true,false).size()==3,"Expected three benches")
				check(visual.find_children("Oar_*","Node3D",true,false).size()==2,"Expected two removable oars")
				check(visual.find_children("Blade_*","MeshInstance3D",true,false).size()==2,"Expected two paddle blades")
			"shore_wave_module":
				check(visual.find_child("WaterBody",true,false) != null,"Wave body missing")
				check(visual.find_child("FoamCrest",true,false) != null,"Foam crest missing")
			"shore_rock":
				check(visual.find_child("Stone",true,false) != null,"Stone missing")
				check(visual.find_child("MossCap",true,false) != null,"Conforming moss missing")
		visual.queue_free()
		await settle()
	var lab = load("res://scenes/art_labs/future_biomes_v08.tscn").instantiate()
	root.add_child(lab)
	await settle()
	for i in 3:
		lab.show_page(i)
		check(lab.stage.get_child_count()>0,"Empty gallery page")
		await settle()
	for id in ids:
		lab.inspect_asset(id,true)
		check(lab.inspected_id == id and lab.angled,"Asset selection mismatch")
		await settle()
		lab.show_single(id)
		check(not lab.ui.visible,"Concept sheet has UI")
		check(lab.stage.get_child_count()==1,"Concept sheet has environment")
		await settle()
	lab.queue_free()
	await settle()
	print("FUTURE_BIOMES_V08_VALIDATION: " + str(failures.size()) + " failures")
	quit(0 if failures.is_empty() else 1)
