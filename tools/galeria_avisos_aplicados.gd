extends "res://tools/galeria_avisos.gd"
const STYLE := preload("res://scripts/vfx/bee_warning_style.gd")
const EXCEPTIONS := ["Hormiga · embestida", "Tarántula · carga de suelo", "Robot · sector de láser", "Robot · morteros", "Robot · salto", "Tarántula · pisotón"]

func build_case(entry: Array, option: int) -> Node3D:
	STYLE.enabled = option > 0
	var sample := super.build_case(entry, 0)
	if entry[0] == EXCEPTIONS[5]:
		for node in sample.get_children():
			if node.name != "EmisorEsquematico": node.free()
	for node: MeshInstance3D in sample.find_children("*", "MeshInstance3D", true, false):
		if node.name == "EmisorEsquematico": continue
		if entry[2] == "sector": STYLE.dress(node, BeeGameSettings.HOSTILE_CYAN, 1.0, entry[5])
		if entry[2] == "jump" and node.mesh is BoxMesh: STYLE.dress(node, Color(1, 0.3, 0.2), 0.0, entry[5])
	if entry[0] == EXCEPTIONS[5]:
		var dome := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.1
		mesh.height = 2.2
		mesh.is_hemisphere = true
		mesh.material = BeeAttackVisuals.material(Color(0.9, 0.95, 1, 0.8))
		dome.mesh = mesh
		sample.add_child(dome)
		dome.global_position = Vector3(80, 0, 0)
		STYLE.dress(dome, Color(0.8, 0.9, 1), 5.0)
		BeeAttackVisuals.ring(sample, Vector3(80, 0.12, 0), 1.1, 0.08, ORANGE)
	if option == 2:
		for node: MeshInstance3D in sample.find_children("*", "MeshInstance3D", true, false):
			if node.material_override is ShaderMaterial and node.get_meta("warning_style_mode", -1) == 0.0:
				node.material_override.set_shader_parameter("opacity", STYLE.FINAL_ALPHA)
	apply_layers(sample, 1 << (20 + option))
	STYLE.enabled = true
	return sample

func export_both() -> void:
	exporting = true
	for label: Label in find_children("*", "Label", true, false):
		if label.text.begins_with("ACTUAL"): label.text = "ANTES · geometría original"
		elif label.text.begins_with("A ·"): label.text = "AHORA · fase inicial"
		elif label.text.begins_with("B ·"): label.text = "AHORA · últimos 0,3 s"
	for dark in [false, true]:
		set_night(dark)
		var result := Image.create(ROW.x, ROW.y * EXCEPTIONS.size(), false, Image.FORMAT_RGBA8)
		for row in EXCEPTIONS.size():
			for sample in DATA.CASES.size():
				if DATA.CASES[sample][0] == EXCEPTIONS[row]: show_case(sample)
			heading.text = "%s · %s · %s · ANTES / AHORA / ÚLTIMOS 0,3 s" % ["abcdef"[row], EXCEPTIONS[row] if row != 5 else "Domos de aviso · sin escudo", "NOCHE" if dark else "DÍA"]
			details.text = "Mismo tiempo y área de daño · inicio: alfa ≤0,30 · bandas: alfa 0,60 solo últimos 0,30 s; rayos punteados ≤0,35"
			if row == 5: details.text = "Domo alfa ≤0,25 · elipse ≤0,40 · la onda del jefe es un ataque activo; el domo del gusano anuncia la erupción"
			for frame in 2: await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var picture := get_viewport().get_texture().get_image()
			picture.convert(Image.FORMAT_RGBA8)
			result.blit_rect(picture, Rect2i(Vector2i.ZERO, ROW), Vector2i(0, row * ROW.y))
		assert(result.save_png("res://docs/galeria_avisos_%s.png" % ("noche" if dark else "dia")) == OK)
	print("T3H_GALERIA_OK")
	exporting = false
