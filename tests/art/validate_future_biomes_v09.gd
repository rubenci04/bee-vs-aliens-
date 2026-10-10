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

func verify_model(id: String, batch: String) -> Node3D:
	var packed := load("res://scenes/art_labs/assets_"+batch+"/"+id+".tscn") as PackedScene
	check(packed != null,"Import missing: " + id)
	if packed == null:
		return null
	var visual := packed.instantiate() as Node3D
	root.add_child(visual)
	await settle()
	var animal := visual.find_child("NaturalFauna",true,false) as Node3D
	var devices: Array[Node3D] = []
	for node: Node3D in visual.find_children("AlienControlDevice*","Node3D",true,false):
		if not node is MeshInstance3D:
			devices.append(node)
	check(not devices.is_empty(),"No external controller: " + id)
	var meshes := visual.find_children("*","MeshInstance3D",true,false)
	check(not meshes.is_empty(),"Missing geometry: " + id)
	var active_surfaces := 0
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
			active_surfaces += 1
			var tech := false
			var ancestor: Node = node
			while ancestor != null:
				tech = tech or ancestor in devices
				ancestor = ancestor.get_parent()
			check(tech,"Alien glow outside technology: " + id + "/" + node.name)
			check(float(energy)<=.65,"Emission clips in Compatibility: " + id)
	check(active_surfaces>=2,"Cyan/violet energy absent: " + id)
	visual.release_control()
	for device in devices:
		check(not device.visible,"Controller remains after release: " + id)
	if animal != null:
		for node: MeshInstance3D in animal.find_children("*","MeshInstance3D",true,false):
			check(node.is_visible_in_tree(),"Release removed anatomy: " + id)
	visual.controlled = true
	for device in devices:
		check(device.visible,"Controller restore failed: " + id)
	return visual

func run() -> void:
	var ids := ["controlled_ant","controlled_caterpillar","amphibian_mount_study","canonical_implant_kit"]
	for id in ids:
		var visual := await verify_model(id,"v09")
		if visual == null:
			continue
		match id:
			"controlled_ant":
				check(visual.find_children("Leg_*","Node3D",true,false).filter(func(n): return not n is MeshInstance3D).size()==6,"Ant must have six legs")
				check(visual.find_children("ElbowedAntenna_*","MeshInstance3D",true,false).size()==2,"Ant antennae missing")
				check(visual.find_child("Petiole",true,false)!=null,"Ant waist missing")
			"controlled_caterpillar":
				check(visual.find_children("BodySegment_*","MeshInstance3D",true,false).size()==8,"Larval segments missing")
				check(visual.find_children("TrueLeg_*","Node3D",true,false).size()==6,"Larval thoracic legs missing")
				check(visual.find_children("Proleg_*","Node3D",true,false).size()==10,"Larval prolegs missing")
				var device := visual.find_child("AlienControlDevice",true,false)
				check(device.find_children("ArmourPlate_*","Node3D",true,false).size()==3,"Armour must belong to controller")
			"amphibian_mount_study":
				check(visual.find_children("Foreleg_*","Node3D",true,false).filter(func(n): return not n is MeshInstance3D).size()==2,"Toad forelegs missing")
				check(visual.find_children("Hindleg_*","Node3D",true,false).filter(func(n): return not n is MeshInstance3D).size()==2,"Toad hindlegs missing")
			"canonical_implant_kit":
				for variant in ["insect","mammal","bird","amphibian"]:
					check(visual.find_child("Mount_"+variant,true,false)!=null,"Missing canonical mount: "+variant)
		visual.queue_free()
		await settle()
	var lab = load("res://scenes/art_labs/future_biomes_v09.tscn").instantiate()
	root.add_child(lab)
	await settle()
	check(lab.stage.get_child_count()==4,"Canonical sheet needs four hosts")
	lab.toggle_control()
	for host in lab.stage.get_children():
		check(not host.find_child("AlienControlDevice",true,false).visible,"Canonical host did not release")
		check(host.find_child("NaturalFauna",true,false).visible,"Canonical host lost anatomy")
	lab.toggle_control()
	for i in 3:
		lab.show_page(i)
		check(lab.stage.get_child_count()>0,"Empty gallery page")
		await settle()
	for id in ids:
		lab.inspect_asset(id,true)
		check(lab.inspected_id==id and lab.angled,"Asset selection mismatch")
		await settle()
		lab.show_single(id,true)
		check(not lab.ui.visible and lab.stage.get_child_count()==1,"Unclean concept sheet")
		await settle()
	lab.queue_free()
	await settle()
	print("FUTURE_BIOMES_V09_VALIDATION: "+str(failures.size())+" failures")
	quit(0 if failures.is_empty() else 1)
