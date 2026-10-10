extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var ids := ["controlled_stick_insect","controlled_pigeon","controlled_mouse","giant_bottle_cap"]
	for id in ids:
		var packed := load("res://scenes/art_labs/assets_v04/"+id+".tscn") as PackedScene
		check(packed != null,"Import missing: " + id)
		if packed == null:
			continue
		var visual := packed.instantiate() as Node3D
		root.add_child(visual)
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"Missing geometry: " + id)
		for node: MeshInstance3D in meshes:
			for surface in node.mesh.get_surface_count():
				var material := node.get_surface_override_material(surface) as ShaderMaterial
				check(material != null,"Missing toon: " + id)
				if material == null:
					continue
				check(material.next_pass != null,"Missing outline: " + id)
				var energy: Variant = material.get_shader_parameter("emission_energy")
				if energy == null or float(energy)<=0:
					continue
				var tech := false
				var ancestor: Node = node
				while ancestor != null:
					tech = tech or ancestor.name == "AlienControlDevice"
					ancestor = ancestor.get_parent()
				check(tech,"Emission outside alien device: " + id + "/" + node.name)
		var device := visual.find_child("AlienControlDevice",true,false) as Node3D
		var animal := visual.find_child("NaturalFauna",true,false) as Node3D
		if id.begins_with("controlled_"):
			check(device != null and animal != null,"Fauna/device separation: " + id)
			if device != null and animal != null:
				visual.release_control()
				check(not device.visible and animal.visible,"Release hid fauna: " + id)
				for node: MeshInstance3D in animal.find_children("*","MeshInstance3D",true,false):
					check(node.is_visible_in_tree(),"Release hid natural geometry: " + id)
				visual.controlled = true
				check(device.visible,"Restore failed: " + id)
		else:
			check(device == null and animal == null,"Human prop has fauna or control device")
			check(visual.find_child("HollowCap",true,false) != null,"Missing concave cap")
			check(visual.find_children("GripRib_*","MeshInstance3D",true,false).size() == 28,"Cap grip ribs missing")
		match id:
			"controlled_stick_insect":
				check(visual.find_children("Leg_*","Node3D",true,false).size() == 6,"Stick insect must have six legs")
				check(visual.find_children("NaturalAntenna*","MeshInstance3D",true,false).size() == 2,"Stick antennae missing")
			"controlled_pigeon":
				check(visual.find_child("Wing_L",true,false) != null and visual.find_child("Wing_R",true,false) != null,"Pigeon wings missing")
				check(visual.find_children("TuckedLeg_*","Node3D",true,false).size() == 2,"Pigeon requires two legs")
				check(visual.find_child("NaturalTail",true,false) != null,"Pigeon tail missing")
			"controlled_mouse":
				check(visual.find_children("Leg_*","Node3D",true,false).size() == 4,"Mouse requires four legs")
				check(visual.find_children("Ear_*","Node3D",true,false).size() == 2,"Mouse ears missing")
				check(visual.find_child("NaturalTail",true,false) != null,"Mouse tail missing")
		visual.queue_free()
	var lab = load("res://scenes/art_labs/future_biomes_v04.tscn").instantiate()
	root.add_child(lab)
	for i in 3:
		lab.show_page(i)
		check(lab.stage.get_child_count()>0,"Empty gallery page")
		lab.toggle_control()
		await process_frame
	for id in ids:
		lab.inspect_asset(id,true)
		check(lab.inspected_id == id and lab.angled,"Asset selection mismatch")
		lab.show_single(id,true)
		check(not lab.ui.visible,"Concept sheet has UI")
		await process_frame
	lab.queue_free()
	await process_frame
	print("FUTURE_BIOMES_V04_VALIDATION: " + str(failures.size()) + " failures")
	quit(0 if failures.is_empty() else 1)
