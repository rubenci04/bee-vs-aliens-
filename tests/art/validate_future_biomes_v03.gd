extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var ids := ["controlled_firefly","controlled_flying_ladybird","controlled_owl","controlled_manta_ray"]
	for id in ids:
		var packed := load("res://scenes/art_labs/assets_v03/"+id+".tscn") as PackedScene
		check(packed != null,"Import missing: " + id)
		if packed == null:
			continue
		var visual := packed.instantiate() as Node3D
		root.add_child(visual)
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"Missing geometry: " + id)
		var warm_lanterns := 0
		for node: MeshInstance3D in meshes:
			for surface in node.mesh.get_surface_count():
				var material := node.get_surface_override_material(surface) as ShaderMaterial
				check(material != null,"Missing toon: " + id)
				if material == null:
					continue
				if material.shader != BeeToonStyle.WING:
					check(material.next_pass != null,"Missing outline: " + id)
				var energy: Variant = material.get_shader_parameter("emission_energy")
				if energy == null or float(energy)<=0:
					continue
				var tech := false
				var ancestor: Node = node
				while ancestor != null:
					tech = tech or ancestor.name == "AlienControlDevice"
					ancestor = ancestor.get_parent()
				var emission: Color = material.get_shader_parameter("emission")
				if not tech:
					var warm: bool = emission.h > .08 and emission.h < .20 and emission.r > emission.b*2
					check(id == "controlled_firefly" and node.name.begins_with("Abdomen_") and warm,
						"Unexpected natural emission: " + id + "/" + node.name)
					warm_lanterns += 1
		var device := visual.find_child("AlienControlDevice",true,false) as Node3D
		var animal := visual.find_child("NaturalFauna",true,false) as Node3D
		check(device != null and animal != null,"Fauna/device separation: " + id)
		if device != null and animal != null:
			visual.release_control()
			check(not device.visible and animal.visible,"Release hid fauna: " + id)
			for node: MeshInstance3D in animal.find_children("*","MeshInstance3D",true,false):
				check(node.is_visible_in_tree(),"Release hid natural geometry: " + id)
			visual.controlled = true
			check(device.visible,"Restore failed: " + id)
		if id in ["controlled_firefly","controlled_flying_ladybird"]:
			check(visual.find_children("Leg_*","Node3D",true,false).size() == 6,"Insect must have six legs: " + id)
			check(visual.find_child("Wing_L",true,false) != null and visual.find_child("Wing_R",true,false) != null,"Missing two natural wings: " + id)
		if id == "controlled_firefly":
			check(warm_lanterns == 2,"Firefly requires two warm natural terminal segments")
		if id == "controlled_flying_ladybird":
			check(visual.find_children("NaturalSpot_*","MeshInstance3D",true,false).size() == 6,"Ladybird spots missing")
		if id == "controlled_owl":
			check(visual.find_child("Wing_L",true,false) != null and visual.find_child("Wing_R",true,false) != null,"Owl wings missing")
			check(visual.find_children("TuckedLeg_*","Node3D",true,false).size() == 2,"Owl must have two tucked legs")
		if id == "controlled_manta_ray":
			check(visual.find_child("PectoralFin_L",true,false) != null and visual.find_child("PectoralFin_R",true,false) != null,"Manta pectoral fins missing")
			check(visual.find_child("NaturalTail",true,false) != null,"Manta tail missing")
		visual.queue_free()
	var lab = load("res://scenes/art_labs/future_biomes_v03.tscn").instantiate()
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
	print("FUTURE_BIOMES_V03_VALIDATION: " + str(failures.size()) + " failures")
	quit(0 if failures.is_empty() else 1)
