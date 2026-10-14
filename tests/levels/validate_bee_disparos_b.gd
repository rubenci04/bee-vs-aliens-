extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var selected := {&"pebble": 0.14, &"seed": 0.12, &"stone": 0.18, &"mud": 0.15, &"pellet": 0.10, &"bubble": 0.24}
	assert(BeeShotStyles.FACETED.COLORS.size() == 6)
	for style in selected:
		var shot := preload("res://scenes/projectiles/toon/alien_bolt.tscn").instantiate() as AlienEnemyProjectile
		shot.damage = 5
		shot.speed = 13.0
		shot.gravity = 1.0
		root.add_child(shot)
		shot.set_physics_process(false)
		BeeShotStyles.dress(shot, style)
		assert(shot.damage == 5 and shot.speed == 13.0 and shot.gravity == 1.0)
		assert(is_equal_approx((shot.hitbox.get_node("CollisionShape3D").shape as SphereShape3D).radius, selected[style]))
		var body := shot.get_node("StyledShot/Body") as Node3D
		assert(body.has_node("SoftHalo"))
		assert(body.find_child("DangerBorder", true, false) == null)
		var solid := body.get_child(0) as MeshInstance3D
		assert(solid.mesh is ArrayMesh and solid.material_override.emission_enabled or style == &"bubble")
		var tail := shot.get_node("StyledTrail") as CPUParticles3D
		assert(tail.mesh.material.albedo_color.is_equal_approx(Color(BeeShotStyles.FACETED.COLORS[style], 0.55)))
		shot.free()
	# Unselected families keep exactly the original geometry and material colours.
	for style in [&"stinger", &"acid", &"web", &"spore", &"bile"]:
		var active := BeeShotStyles.build(style)
		var old := BeeShotStyles.build_original(style)
		assert(active.scale == old.scale)
		for mesh: MeshInstance3D in old.find_children("*", "MeshInstance3D", true, false):
			var copy := active.get_node(old.get_path_to(mesh)) as MeshInstance3D
			assert(mesh.mesh.get_faces() == copy.mesh.get_faces())
			assert(mesh.mesh.surface_get_material(0).albedo_color == copy.mesh.surface_get_material(0).albedo_color)
		active.free()
		old.free()
	var seed := BeeShotStyles.build(&"seed")
	var halo := seed.get_node("Body/SoftHalo") as MeshInstance3D
	assert(is_equal_approx(halo.material_override.albedo_color.a, 0.28))
	assert(halo.mesh.get_aabb().size.y > 0.65)
	seed.free()
	var gallery: Node = load("res://tools/galeria_final.tscn").instantiate()
	root.add_child(gallery)
	await process_frame
	assert(gallery.samples.size() == 6)
	for sample in gallery.samples:
		var shot := sample.get_child(0) as AlienEnemyProjectile
		assert(shot != null and shot.has_node("StyledShot/Body/SoftHalo"))
	gallery.set_profile(true)
	assert(gallery.heading.text.contains("NOCHE"))
	gallery.queue_free()
	await process_frame
	print("PASS: six B styles, original collision/damage/speed/gravity, untouched unselected meshes, reinforced seed halo, actual-projectile gallery")
	quit(0)
