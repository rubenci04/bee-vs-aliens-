extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var ids := ["garden_sapling","flowering_shrub","empty_drink_can","wrapped_candy"]
	for id in ids:
		var packed := load("res://scenes/art_labs/assets_v06/"+id+".tscn") as PackedScene
		check(packed != null,"Import missing: " + id)
		if packed == null:
			continue
		var visual := packed.instantiate() as Node3D
		root.add_child(visual)
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"Missing geometry: " + id)
		check(visual.find_child("AlienControlDevice",true,false) == null,"Environment has alien device: " + id)
		for node: MeshInstance3D in meshes:
			for surface in node.mesh.get_surface_count():
				var material := node.get_surface_override_material(surface) as ShaderMaterial
				check(material != null,"Missing toon: " + id)
				if material == null:
					continue
				check(material.next_pass != null,"Missing outline: " + id)
				var energy: Variant = material.get_shader_parameter("emission_energy")
				check(energy == null or float(energy)<=0,"Environment must not emit light: " + id)
		visual.release_control()
		for node: MeshInstance3D in meshes:
			check(node.is_visible_in_tree(),"Control state hid environment: " + id)
		match id:
			"garden_sapling":
				check(visual.find_child("Canopy",true,false) != null,"Tree crown missing")
				check(visual.find_children("Branch_*","MeshInstance3D",true,false).size() == 4,"Tree branches missing")
				check(visual.find_children("Root_*","MeshInstance3D",true,false).size() == 4,"Tree roots missing")
			"flowering_shrub":
				check(visual.find_children("Flower_*","Node3D",true,false).size() == 3,"Shrub requires three flowers")
				check(visual.find_child("ShrubLeaves",true,false) != null,"Shrub leaves missing")
			"empty_drink_can":
				check(visual.find_child("OpenLid",true,false) != null,"Can open lid missing")
				check(visual.find_child("PullTab",true,false) != null,"Can pull tab missing")
				check(visual.find_child("TopRim",true,false) != null and visual.find_child("BottomRim",true,false) != null,"Can rims missing")
			"wrapped_candy":
				check(visual.find_child("TwistedEnd_L",true,false) != null and visual.find_child("TwistedEnd_R",true,false) != null,"Candy twisted ends missing")
		visual.queue_free()
	var lab = load("res://scenes/art_labs/future_biomes_v06.tscn").instantiate()
	root.add_child(lab)
	for i in 3:
		lab.show_page(i)
		check(lab.stage.get_child_count()>0,"Empty gallery page")
		await process_frame
	for id in ids:
		lab.inspect_asset(id,true)
		check(lab.inspected_id == id and lab.angled,"Asset selection mismatch")
		lab.show_single(id)
		check(not lab.ui.visible,"Concept sheet has UI")
		await process_frame
	lab.queue_free()
	await process_frame
	print("FUTURE_BIOMES_V06_VALIDATION: " + str(failures.size()) + " failures")
	quit(0 if failures.is_empty() else 1)
