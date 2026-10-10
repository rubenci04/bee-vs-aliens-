extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var ids := ["sky_cloud","sky_sun","sky_crescent_moon","sky_star_cluster"]
	for id in ids:
		var packed := load("res://scenes/art_labs/assets_v07/"+id+".tscn") as PackedScene
		check(packed != null,"Import missing: " + id)
		if packed == null:
			continue
		var visual := packed.instantiate() as Node3D
		root.add_child(visual)
		var meshes := visual.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"Missing geometry: " + id)
		check(visual.find_child("AlienControlDevice",true,false) == null,"Sky has alien device: " + id)
		check(visual.find_children("*","Light3D",true,false).is_empty(),"Sky model must not control world lighting: " + id)
		for node: MeshInstance3D in meshes:
			for surface in node.mesh.get_surface_count():
				var material := node.get_surface_override_material(surface) as ShaderMaterial
				check(material != null,"Missing toon: " + id)
				if material == null:
					continue
				if node.name.begins_with("MoonMare_"):
					check(material.next_pass == null,"Moon patches should have no dark outline")
				else:
					check(material.next_pass != null,"Missing outline: " + id)
					if material.next_pass != null:
						var width: float = material.next_pass.get_shader_parameter("width")
						check(is_equal_approx(width,.0011),"Sky outline too strong: " + id)
				var energy: Variant = material.get_shader_parameter("emission_energy")
				check(energy == null or float(energy)<=0,"Sky POC must not emit alien energy: " + id)
		match id:
			"sky_cloud": check(meshes.size()==1 and visual.find_child("CloudBody",true,false)!=null,"Cloud requires one continuous body")
			"sky_crescent_moon":
				check(visual.find_child("CrescentBody",true,false)!=null,"Crescent geometry missing")
				check(visual.find_children("MoonMare_*","MeshInstance3D",true,false).size()==3,"Moon patches missing")
			"sky_star_cluster":
				check(visual.find_children("StarGlint_*","MeshInstance3D",true,false).size()==4,"Star glints missing")
				check(visual.find_children("StarDot_*","MeshInstance3D",true,false).size()==5,"Star dots missing")
		# Instance tint must not mutate a peer or the shared style cache.
		var peer := packed.instantiate() as Node3D
		root.add_child(peer)
		# Local materials must reach RenderingServer before the instances are freed.
		await process_frame
		await process_frame
		var peer_mesh := peer.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
		var peer_mat := peer_mesh.get_surface_override_material(0) as ShaderMaterial
		var original: Color = peer_mat.get_shader_parameter("albedo")
		visual.tint = Color(.4,.5,.45)
		check(peer_mat.get_shader_parameter("albedo")==original,"Tint changed peer: " + id)
		visual.tint = Color.WHITE
		var first_mat := (meshes[0] as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
		check(first_mat.get_shader_parameter("albedo")==original,"Tint did not restore source colour: " + id)
		visual.queue_free()
		peer.queue_free()
	var lab = load("res://scenes/art_labs/future_biomes_v07.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame
	for i in 3:
		lab.show_page(i)
		check(lab.stage.get_child_count()>0,"Empty gallery page")
		await process_frame
		await process_frame
	for id in ids:
		lab.inspect_asset(id,true)
		check(lab.inspected_id == id and lab.angled,"Asset selection mismatch")
		await process_frame
		await process_frame
		lab.show_single(id)
		check(not lab.ui.visible,"Concept sheet has UI")
		await process_frame
		await process_frame
	lab.queue_free()
	await process_frame
	print("FUTURE_BIOMES_V07_VALIDATION: " + str(failures.size()) + " failures")
	quit(0 if failures.is_empty() else 1)
