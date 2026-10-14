extends SceneTree
## Baseline visuals plus preserved warnings; no new art style assertions.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(BeeShotStyles.STYLES[&"stinger"]["rim"] == Color(0.6, 0.2, 0.95))
	assert(BeeShotStyles.STYLES[&"acid"]["rim"] == Color(0.55, 0.95, 0.1))
	assert(BeeShotStyles.STYLES[&"pebble"]["shape"] == &"rock")
	var expected := {&"stinger": 0.12, &"acid": 0.13, &"web": 0.16, &"pebble": 0.14, &"bubble": 0.24, &"spore": 0.15, &"pellet": 0.1, &"seed": 0.12, &"stone": 0.18, &"mud": 0.15, &"bile": 0.16}
	for style in expected:
		assert(is_equal_approx(BeeShotStyles.STYLES[style]["hit_radius"], expected[style]))
		var body := BeeShotStyles.build(style)
		assert(body.find_child("DangerBorder", true, false) == null)
		body.free()
	var host := Node3D.new()
	root.add_child(host)
	var beam := BeeAttackVisuals.line(host, Vector3.ZERO, Vector3.RIGHT * 3, 0.06, Color(0.95, 0.95, 0.9, 0.9))
	assert(beam.get_child_count() == 0 and is_equal_approx((beam.mesh as BoxMesh).size.y, 0.06))
	var warning := BeeAttackVisuals.line(host, Vector3.ZERO, Vector3.RIGHT * 3, 0.06, Color(1, 0.62, 0.2, 0.4))
	assert(warning.has_node("ReadabilityEdge"))
	BeeAttackVisuals.restore_active_line(warning, Color(0.95, 0.95, 0.9, 0.9), 0.06)
	assert(warning.get_child_count() == 0 and is_equal_approx((warning.mesh as BoxMesh).size.y, 0.06))
	var mortar_warning := BeeAttackVisuals.ring(host, Vector3.ZERO, 1.0, 0.18, Color(0.2, 0.95, 1, 0.8), true)
	assert(mortar_warning.has_node("ReadabilityEdge") and is_equal_approx(mortar_warning.mesh.material.albedo_color.a, 0.9))
	var pool := BeeAttackVisuals.ground_disc(host, Vector3.ZERO, 0.7, Color(0.2, 0.95, 1, 0.55), false)
	assert(pool.get_child_count() == 0 and is_equal_approx(pool.mesh.material.albedo_color.a, 0.55))
	var sphere := BeeAttackVisuals.sphere(host, Vector3.ZERO, 0.22, AlienMortarShell.COLOR)
	assert(sphere.get_child_count() == 0 and sphere.mesh.material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL)
	assert(not sphere.mesh.material.disable_fog)
	host.free()
	var gallery: Node = load("res://tools/galeria_disparos.tscn").instantiate()
	root.add_child(gallery)
	await process_frame
	assert(gallery.ready_for_review and gallery.samples.size() == 27)
	for sample in gallery.samples:
		assert(sample.find_children("*", "DamageHitbox3D", true, false).is_empty())
	gallery.set_profile(true)
	assert(gallery.heading.text.contains("NOCHE"))
	gallery.set_profile(false)
	assert(gallery.heading.text.contains("DÍA"))
	gallery.queue_free()
	await process_frame
	print("PASS restored shots, original collision radii, active materials, preserved warnings, 27-sample gallery/day/night")
	quit(0)
