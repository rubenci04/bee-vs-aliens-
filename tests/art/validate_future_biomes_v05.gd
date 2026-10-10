extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var ids := ["controlled_octopus","controlled_gull","coastal_buoy"]
	for id in ids:
		var packed := load("res://scenes/art_labs/assets_v05/"+id+".tscn") as PackedScene
		check(packed != null,"Import missing: " + id)
		if packed == null:
			continue
		var visual := packed.instantiate() as Node3D
		root.add_child(visual)
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"Missing geometry: " + id)
		var emissions := 0
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
				emissions += 1
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
			check(emissions>0,"Missing alien energy: " + id)
			if device != null and animal != null:
				visual.release_control()
				check(not device.visible and animal.visible,"Release hid fauna: " + id)
				for node: MeshInstance3D in animal.find_children("*","MeshInstance3D",true,false):
					check(node.is_visible_in_tree(),"Release hid natural geometry: " + id)
				visual.controlled = true
				check(device.visible,"Restore failed: " + id)
		else:
			check(device == null and animal == null and emissions==0,"Human buoy has fauna, control or emission")
			check(visual.find_child("MooringRope",true,false) != null,"Buoy rope missing")
			check(visual.find_child("Handle",true,false) != null,"Buoy handle missing")
		match id:
			"controlled_octopus":
				check(visual.find_children("Arm_*","Node3D",true,false).size() == 8,"Octopus requires eight arms")
				check(visual.find_children("NaturalSuckers*","MeshInstance3D",true,false).size() == 8,"Missing arm sucker groups")
				check(visual.find_children("HorizontalPupil*","MeshInstance3D",true,false).size() == 2,"Octopus eyes missing")
			"controlled_gull":
				check(visual.find_child("Wing_L",true,false) != null and visual.find_child("Wing_R",true,false) != null,"Gull wings missing")
				check(visual.find_children("TuckedLeg_*","Node3D",true,false).size() == 2,"Gull requires two legs")
				check(visual.find_children("WebbedFoot*","MeshInstance3D",true,false).size() == 2,"Gull webbed feet missing")
				check(visual.find_child("NaturalTail",true,false) != null,"Gull tail missing")
		visual.queue_free()
	var lab = load("res://scenes/art_labs/future_biomes_v05.tscn").instantiate()
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
	print("FUTURE_BIOMES_V05_VALIDATION: " + str(failures.size()) + " failures")
	quit(0 if failures.is_empty() else 1)
