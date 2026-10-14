extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Snapshot cached game resources before gallery recolouring.
	var baseline := BeeShotStyles.build_original(&"stone")
	var original_mesh := baseline.get_node("Body/Rock").mesh as Mesh
	var original_color: Color = original_mesh.surface_get_material(0).albedo_color
	var scene: Node3D = load("res://tools/galeria_propuestas.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.ready_for_review and scene.samples.size() == 12)
	var styles := [&"pebble", &"seed", &"stone", &"mud", &"pellet", &"bubble"]
	for row in styles.size():
		var a: Node3D = scene.samples[row * 2]
		var b: Node3D = scene.samples[row * 2 + 1]
		assert(a.position.is_equal_approx(b.position))
		assert(a.find_children("*", "CollisionObject3D", true, false).is_empty())
		assert(b.find_children("*", "CollisionObject3D", true, false).is_empty())
		var source := BeeShotStyles.build_original(styles[row])
		var preview := a.get_node("StyledShot") as Node3D
		assert(preview.scale == source.scale)
		for original: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
			var copy := preview.get_node(source.get_path_to(original)) as MeshInstance3D
			assert(copy.mesh != original.mesh)
			assert(copy.mesh.get_faces() == original.mesh.get_faces())
			assert(copy.scale == original.scale)
			assert(copy.material_override.emission_enabled or copy.material_override.albedo_color.a < 1.0)
		var tail := a.get_node("StyledTrail") as CPUParticles3D
		assert(tail.mesh.material.emission == Color(scene.COLORS[styles[row]], 1.0))
		source.free()
	assert(original_mesh.surface_get_material(0).albedo_color == original_color)
	scene.set_profile(true)
	assert(scene.heading.text.contains("NOCHE"))
	scene.set_profile(false)
	assert(scene.heading.text.contains("DÍA"))
	baseline.free()
	scene.queue_free()
	await process_frame
	print("PASS: twelve gallery-only proposals, A geometry/scale preserved, emissive trails, no colliders, no cached-game material mutation, day/night")
	quit(0)
