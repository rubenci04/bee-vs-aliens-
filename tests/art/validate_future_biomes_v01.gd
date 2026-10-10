extends SceneTree
## Import, material restrictions, detachable devices, facing and HUD clamps.
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var ids := ["controlled_mosquito","controlled_perch","orbital_skimmer","lotus_lily_pad","cattails_cluster","warm_asteroid"]
	for id in ids:
		var scene := load("res://scenes/art_labs/assets/" + id + ".tscn") as PackedScene
		check(scene != null,"Missing scene " + id)
		if scene == null:
			continue
		var visual := scene.instantiate() as Node3D
		root.add_child(visual)
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"No imported geometry " + id)
		for node: MeshInstance3D in meshes:
			check(node.mesh != null,"Missing mesh " + id)
			for surface in node.mesh.get_surface_count():
				var material := node.get_surface_override_material(surface) as ShaderMaterial
				check(material != null,"Toon missing " + id)
				if material == null:
					continue
				var energy: Variant = material.get_shader_parameter("emission_energy")
				if energy != null and float(energy) > 0.0:
					var alien: bool = id == "orbital_skimmer"
					var ancestor: Node = node
					while ancestor != null:
						alien = alien or ancestor.name == "AlienControlDevice"
						ancestor = ancestor.get_parent()
					check(alien,"Emission outside alien technology: " + id + "/" + node.name)
		if id.begins_with("controlled_"):
			var device := visual.find_child("AlienControlDevice",true,false) as Node3D
			var animal := visual.find_child("NaturalFauna",true,false) as Node3D
			check(device != null and animal != null,"Fauna/device separation " + id)
			visual.release_control()
			check(not device.visible and animal.visible,"Release must hide ONLY the device " + id)
			visual.controlled = true
			check(device.visible,"Controller cannot be restored " + id)
		visual.face_right(true)
		check(is_equal_approx(visual.rotation.y,PI),"Right facing " + id)
		visual.queue_free()
	var bar = load("res://scenes/ui/future_health_bar.tscn").instantiate()
	root.add_child(bar)
	bar.set_health(3,4)
	check(is_equal_approx(bar.ratio,.75),"HUD health ratio")
	bar.set_health(2,0)
	check(bar.ratio == 0.0,"HUD zero maximum")
	bar.set_health(10,4)
	check(bar.ratio == 1.0,"HUD overfill clamp")
	bar.set_health(-1,4)
	check(bar.ratio == 0.0,"HUD negative clamp")
	bar.queue_free()
	var lab = load("res://scenes/art_labs/future_biomes_v01.tscn").instantiate()
	root.add_child(lab)
	for i in 3:
		lab.show_page(i)
		check(lab.stage.get_child_count() > 0,"Empty gallery page " + str(i))
		lab.toggle_control()
		await process_frame
	lab.show_single("controlled_perch",true)
	check(not lab.ui.visible,"Creature sheet must have no UI")
	lab.queue_free()
	await process_frame
	print("FUTURE_BIOMES_VALIDATION: " + str(failures.size()) + " failures")
	quit(0 if failures.is_empty() else 1)
