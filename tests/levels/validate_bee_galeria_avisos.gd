extends SceneTree
const DATA := preload("res://tools/galeria_avisos_catalogo.gd")
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func run() -> void:
	var gallery := preload("res://tools/galeria_avisos.tscn").instantiate()
	root.add_child(gallery)
	await process_frame
	check(DATA.CASES.size() == 38, "Complete gallery has 38 visual warning variants")
	check(DATA.PROPOSAL_SECONDS >= 0.5 and DATA.PROPOSAL_SECONDS <= 1.0 and DATA.RAY_DOTTED_SECONDS <= 0.3, "Proposal timing bounds only, no gameplay timing mutation")
	var names := {}
	for index in DATA.CASES.size():
		var entry: Array = DATA.CASES[index]
		check(not names.has(entry[0]), "Each warning has a unique row")
		names[entry[0]] = true
		gallery.show_case(index)
		check(gallery.roots.size() == 3 and gallery.fills.size() >= 2 and gallery.cues.size() >= 2, "Every row contains original, minimal impact and impact+anticipation")
		for option in 3:
			var sample: Node3D = gallery.roots[option]
			check(sample.find_children("*", "CollisionShape3D", true, false).is_empty() and sample.find_children("*", "Area3D", true, false).is_empty(), "Gallery samples have no collisions or damaging areas")
			for mesh in sample.find_children("*", "MeshInstance3D", true, false):
				check(mesh.layers == 1 << (20 + option), "Each preview is isolated from the other two cameras")
		gallery.update_proposals(0.0)
		for dots in gallery.dotted:
			check(not dots.visible, "No long dotted ray during the early warning")
		gallery.update_proposals(0.9)
		for dots in gallery.dotted:
			check(dots.visible and entry[2] in gallery.RAYS, "Dotted trajectory only during final short interval, and only for rays")
	gallery.set_night(true)
	check(gallery.night and "NOCHE" in gallery.heading.text, "Night profile/labels available")
	gallery.set_night(false)
	check(not gallery.night and "DÍA" in gallery.heading.text, "Day profile/labels available")
	print("GALERIA_AVISOS_TEST_OK 38 original/A/B rows, no damage shapes, isolated cameras, fill+anticipation, bounded ray dots, day/night")
	quit(0)
