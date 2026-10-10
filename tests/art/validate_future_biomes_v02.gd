extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var ids := ["controlled_stag_beetle","controlled_woodland_snail","alien_seed_carrier","alien_signal_relay"]
	for id in ids:
		var packed := load("res://scenes/art_labs/assets_v02/"+id+".tscn") as PackedScene
		check(packed != null,"Import missing: " + id)
		if packed == null:
			continue
		var visual := packed.instantiate() as Node3D
		root.add_child(visual)
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"No geometry: " + id)
		for node: MeshInstance3D in meshes:
			for surface in node.mesh.get_surface_count():
				var material := node.get_surface_override_material(surface) as ShaderMaterial
				check(material != null,"Style C missing: " + id)
				if material == null:
					continue
				if material.shader != BeeToonStyle.WING:
					check(material.next_pass != null,"Outline missing: " + id)
				var energy: Variant = material.get_shader_parameter("emission_energy")
				if energy != null and float(energy)>0.0:
					var tech: bool = id.begins_with("alien_")
					var ancestor: Node = node
					while ancestor != null:
						tech = tech or ancestor.name == "AlienControlDevice"
						ancestor = ancestor.get_parent()
					check(tech,"Emission in natural fauna: " + id + "/" + node.name)
		if id.begins_with("controlled_"):
			var device := visual.find_child("AlienControlDevice",true,false) as Node3D
			var animal := visual.find_child("NaturalFauna",true,false) as Node3D
			check(device != null and animal != null,"Animal/device separation: " + id)
			if device != null and animal != null:
				visual.release_control()
				check(not device.visible and animal.visible,"Release damaged fauna: " + id)
				visual.controlled = true
				check(device.visible,"Control restore: " + id)
		if id == "controlled_stag_beetle":
			var legs := visual.find_children("Leg_*","Node3D",true,false)
			check(legs.size() == 6,"Stag beetle must have six legs")
			check(visual.find_child("Mandible_L",true,false) != null and visual.find_child("Mandible_R",true,false) != null,"Paired mandibles missing")
		if id == "controlled_woodland_snail":
			check(visual.find_child("NaturalShellSpiral",true,false) != null,"Natural spiral missing")
			check(visual.find_children("EyeStalk*","MeshInstance3D",true,false).size() == 2,"Snail must have two eye stalks")
		if id == "alien_signal_relay":
			var clamps := visual.find_child("MountingClamps",true,false) as Node3D
			check(clamps != null,"Independent mounting clamps missing")
			if clamps != null:
				clamps.visible = false
				check(visual.find_child("CyanSignalCore",true,false).is_visible_in_tree(),"Removing clamps hid relay core")
		visual.queue_free()
	var lab = load("res://scenes/art_labs/future_biomes_v02.tscn").instantiate()
	root.add_child(lab)
	for i in 3:
		lab.show_page(i)
		check(lab.stage.get_child_count() > 0,"Empty gallery page")
		await process_frame
	for id in ids:
		lab.inspect_asset(id,true)
		check(lab.inspected_id == id and lab.angled,"Asset inspection mismatch")
		lab.show_single(id)
		check(not lab.ui.visible,"Concept sheet contains UI")
		await process_frame
	lab.queue_free()
	await process_frame
	print("FUTURE_BIOMES_V02_VALIDATION: " + str(failures.size()) + " failures")
	quit(0 if failures.is_empty() else 1)
