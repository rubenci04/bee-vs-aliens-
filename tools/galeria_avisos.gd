extends Node
## Isolated visual review. Not referenced by gameplay scenes or input.
const DATA := preload("res://tools/galeria_avisos_catalogo.gd")
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const CELL := Vector2i(500, 280)
const ROW := Vector2i(1500, 400)
const ORANGE := Color(1, 0.55, 0.15, 0.8)
const CYAN := Color(0.15, 0.9, 1, 0.85)
const MAGENTA := Color(0.95, 0.18, 0.65, 0.85)
const RAYS := ["ray", "sector", "redsector", "ufo", "ufobands"]
var stage: BeeShmupStage
var heading: Label
var details: Label
var views: Array[SubViewport] = []
var roots: Array[Node3D] = []
var fills: Array[MeshInstance3D] = []
var cues: Array[Node3D] = []
var dotted: Array[Node3D] = []
var index := 0
var night := false
var clock := 0.0
var exporting := false

func _ready() -> void:
	if get_viewport() is Window:
		(get_viewport() as Window).size = ROW
	stage = LEVEL.instantiate()
	add_child(stage)
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	stage.camera.clear_current()
	stage.get_node("LiveReadability").set_modes(0, 0, 0, 0)
	for child in stage.get_children():
		if child is CanvasLayer:
			child.hide()
		elif child is Node3D and child.name not in ["Scenery", "VisualTarget01", "Sun", "Ground", "GroundExtension", "AssetDressing", "DomesticGarden", "LiveGarden"]:
			child.hide()
	for ui in stage.find_children("*", "CanvasLayer", true, false):
		ui.hide()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var backdrop := ColorRect.new()
	backdrop.color = Color("101722")
	backdrop.size = Vector2(ROW)
	canvas.add_child(backdrop)
	heading = label(backdrop, "", Vector2(14, 8), 23)
	details = label(backdrop, "", Vector2(14, 39), 17)
	for column in 3:
		label(backdrop, ["ACTUAL · material y forma del código", "A · marca local mínima", "B · marca + anticipación del emisor"][column], Vector2(column * CELL.x + 12, 65), 18)
		var view := SubViewport.new()
		view.size = CELL
		view.world_3d = stage.get_viewport().world_3d
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(view)
		views.append(view)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 11.5
		camera.position = Vector3(80, 4.3, 17)
		camera.cull_mask = 1 | (1 << (20 + column))
		camera.environment = (stage.get_node("WorldEnvironment") as WorldEnvironment).environment
		view.add_child(camera)
		camera.current = true
		var texture := TextureRect.new()
		texture.texture = view.get_texture()
		texture.position = Vector2(column * CELL.x, 90)
		texture.size = Vector2(CELL)
		backdrop.add_child(texture)
	label(backdrop, "←/→: aviso   1: día   2: noche   E: exportar · Emisor esquemático; propuestas de 0,75 s, sin daño ni colisión", Vector2(14, 374), 16)
	show_case(0)
	if "--export-gallery" in OS.get_cmdline_user_args():
		await export_both()
		get_tree().quit()

func label(parent: Node, text: String, at: Vector2, size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.position = at
	node.add_theme_font_size_override("font_size", size)
	parent.add_child(node)
	return node

func apply_layers(node: Node, mask: int) -> void:
	if node is MeshInstance3D:
		node.layers = mask
	for child in node.get_children():
		apply_layers(child, mask)

func endpoints(entry: Array) -> Array[Vector3]:
	var length := float(entry[3])
	var half := length * 0.5
	var kind: String = entry[2]
	if kind == "ceiling":
		return [Vector3(74, 1.5, 0), Vector3(86, 8.3, 0)]
	if kind in ["mortar", "jump", "vertical", "spider", "water", "ufo", "dots"]:
		return [Vector3(85, length + 0.1, 0), Vector3(85, 0.1, 0)]
	var y := 0.55 if kind in ["lunge", "ground", "band", "redband"] else 4.0
	return [Vector3(80 - half, y + (2.5 if kind in ["diagonal", "ceiling"] else 0), 0), Vector3(80 + half, y - (2.5 if kind in ["diagonal", "ceiling"] else 0), 0)]

func raw_box(parent: Node3D, center: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = BeeAttackVisuals.material(color)
	mesh.mesh = box
	parent.add_child(mesh)
	mesh.global_position = center

func current_visual(parent: Node3D, entry: Array, from: Vector3, to: Vector3) -> void:
	var kind: String = entry[2]
	var width := float(entry[4])
	match kind:
		"band", "redband":
			var band := BeeGroundShockwave.warning_band(parent, from.x, to.x, width)
			if kind == "redband":
				band.mesh.material = BeeAttackVisuals.warning_material(Color(1, 0.3, 0.2, 0.72))
		"water", "ufo", "spider":
			var color := Color(0.02, 0.86, 1, 0.2) if kind == "water" else Color(0.2, 0.95, 1, 0.32)
			if kind == "ufo":
				color = Color(1, 0.6, 0.2, 0.2)
			raw_box(parent, (from + to) * 0.5, Vector3(width, float(entry[3]), 0.05 if kind != "ufo" else 0.5), color)
			if kind == "spider":
				BeeAttackVisuals.ring(parent, to, 0.55, 0.13 / 0.55, Color(0.2, 0.95, 1, 0.32))
			else:
				BeeAttackVisuals.ground_disc(parent, to, 1.21 if kind == "water" else 0.93, Color(0.02, 0.86, 1, 0.88) if kind == "water" else ORANGE, kind == "water")
			if kind == "water":
				BeeAttackVisuals.line(parent, to + Vector3(-0.8, 0.2, 0.08), to + Vector3(0.8, 0.2, 0.08), 0.14, Color(0.02, 0.86, 1, 0.88), true)
		"mortar", "jump":
			BeeAttackVisuals.line(parent, from, to, width, Color(1, 0.3, 0.2, 0.18) if kind == "jump" else Color(1, 0.62, 0.2, 0.3))
			BeeAttackVisuals.ground_disc(parent, to, 1.3 if kind == "jump" else 0.7, Color(0.05, 0.03, 0.02, 0.6))
		"sector", "redsector":
			for side in [-1, 1]:
				var angle := deg_to_rad(20.0 * side)
				BeeAttackVisuals.line(parent, from, from + Vector3(cos(angle), sin(angle), 0) * float(entry[3]), width if side == -1 or kind == "sector" else 0.025, BeeGameSettings.HOSTILE_CYAN if kind == "sector" else Color(1, 0.3, 0.3, 0.6))
		"dots":
			for y in [0.55, 1.1, 1.65, 3.85, 4.4, 4.95, 5.5]:
				BeeAttackVisuals.line(parent, Vector3(to.x, y - 0.18, 0), Vector3(to.x, y + 0.18, 0), width, Color(1, 0.62, 0.2, 0.55))
		"ufobands":
			for y in [0.65, 3.3, 6.65]:
				BeeAttackVisuals.line(parent, Vector3(from.x, y, 0), Vector3(to.x, y, 0), width, Color(0.2, 0.95, 1, 0.2))
		_:
			var color := ORANGE
			if kind == "ground": color = Color(1, 0.55, 0.15, 0.25)
			if entry[1] == "speeder_enemy.gd" and kind == "dash": color = Color(1, 0.45, 0.15, 0.5)
			if kind == "cyan": color = Color(0.3, 0.95, 1, 0.3)
			if kind == "silk": color = Color(0.96, 0.96, 0.9, 0.45)
			if kind in ["diagonal", "ceiling", "redaim"]: color = Color(1, 0.3, 0.2, 0.22 if kind != "redaim" else 0.75)
			if kind == "purple": color = Color(0.6, 0.25, 1, 0.3)
			if kind == "wasp": color = Color(1, 0.3, 0.1, 0.45)
			if kind == "classic": color = Color(1, 0.45, 0.15, 0.35)
			if kind in ["wasp", "classic"]:
				var line := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(from.distance_to(to), width, width)
				box.material = BeeAttackVisuals.material(color)
				line.mesh = box
				parent.add_child(line)
				line.global_position = (from + to) * 0.5
				line.rotation.z = atan2(to.y - from.y, to.x - from.x)
			else:
				BeeAttackVisuals.line(parent, from, to, width, color)
			if kind == "ceiling":
				BeeAttackVisuals.line(parent, to + Vector3(-1.8, 0, 0), to + Vector3(1.8, 0, 0), 0.3, Color(0.05, 0.02, 0.02, 0.6))
			elif kind == "diagonal":
				BeeAttackVisuals.ground_disc(parent, Vector3(to.x, 0.03, 0), 1.8, Color(0.05, 0.02, 0.02, 0.55))

func emitter(parent: Node3D, from: Vector3, anticipation: bool) -> void:
	var icon := BeeAttackVisuals.sphere(parent, from, 0.42, Color(0.48, 0.52, 0.58), false)
	icon.name = "EmisorEsquematico"
	if anticipation:
		icon.material_override = icon.mesh.material.duplicate()
		icon.material_override.emission_enabled = true
		icon.material_override.emission = CYAN
		cues.append(icon)
		var ring := BeeAttackVisuals.ring(parent, from, 0.6, 0.08, CYAN)
		cues.append(ring)

func marker(parent: Node3D, at: Vector3, color: Color, option: int) -> void:
	BeeAttackVisuals.ring(parent, at, DATA.IMPACT_RADIUS, 0.08, color)
	var fill := MeshInstance3D.new()
	fill.mesh = ImmediateMesh.new()
	fill.material_override = BeeAttackVisuals.material(Color(color, 0.24 if option == 1 else 0.36))
	parent.add_child(fill)
	fill.global_position = at + Vector3(0, 0, 0.01)
	fills.append(fill)

func build_case(entry: Array, option: int) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	var ends := endpoints(entry)
	emitter(root, ends[0], option == 2)
	if option == 0:
		current_visual(root, entry, ends[0], ends[1])
	else:
		var color := CYAN if option == 1 else MAGENTA
		marker(root, ends[1], color, option)
		# Distributed hazards need several local impact marks, not a misleading single safe-looking point.
		if entry[2] in ["band", "redband", "ufobands"]:
			for x in [-4.0, 0.0, 4.0]:
				marker(root, Vector3(80 + x, 0.45 if entry[2] != "ufobands" else 3.3, 0), color, option)
		if entry[2] in ["water", "ufo", "vertical", "mortar", "spider"]:
			marker(root, Vector3(ends[1].x, 3.5, 0), color, option)
		if entry[2] == "dots":
			for y in [1.2, 4.3, 5.5]: marker(root, Vector3(ends[1].x, y, 0), color, option)
		if entry[2] in ["sector", "redsector"]:
			for side in [-1, 1]:
				var angle := deg_to_rad(20.0 * side)
				marker(root, ends[0] + Vector3(cos(angle), sin(angle), 0) * float(entry[3]), color, option)
		if option == 2:
			var arrow := ends[0] + (ends[1] - ends[0]).normalized() * 0.9
			BeeAttackVisuals.line(root, arrow, arrow + (ends[1] - ends[0]).normalized() * 0.6, 0.08, CYAN)
		if entry[2] in RAYS:
			var dot_root := Node3D.new()
			root.add_child(dot_root)
			for step in 14:
				var start := ends[0].lerp(ends[1], float(step) / 14.0)
				BeeAttackVisuals.line(dot_root, start, start + (ends[1] - ends[0]).normalized() * 0.15, 0.02, Color(0.2, 0.95, 1, 0.4))
			dotted.append(dot_root)
	apply_layers(root, 1 << (20 + option))
	return root

func show_case(which: int) -> void:
	index = posmod(which, DATA.CASES.size())
	for node in roots:
		node.free()
	roots.clear()
	fills.clear()
	cues.clear()
	dotted.clear()
	var entry: Array = DATA.CASES[index]
	for view in views:
		view.get_camera_3d().size = maxf(11.5, float(entry[3]) / (float(CELL.x) / CELL.y) + 1.0)
	heading.text = "%02d/%02d · %s · %s · %s" % [index + 1, DATA.CASES.size(), entry[0], entry[7], "NOCHE" if night else "DÍA"]
	details.text = "%s · actual %.2f s; propuestas %.2f s · medidas variables: muestra representativa" % [entry[6], entry[5], DATA.PROPOSAL_SECONDS]
	for option in 3:
		roots.append(build_case(entry, option))
	update_proposals(0.7)

func update_proposals(progress: float) -> void:
	for fill in fills:
		var mesh := fill.mesh as ImmediateMesh
		mesh.clear_surfaces()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for step in 24:
			var angle_a := float(step) / 24 * TAU * maxf(progress, 0.001)
			var angle_b := float(step + 1) / 24 * TAU * maxf(progress, 0.001)
			mesh.surface_add_vertex(Vector3.ZERO)
			mesh.surface_add_vertex(Vector3(cos(angle_a), sin(angle_a), 0) * DATA.IMPACT_RADIUS)
			mesh.surface_add_vertex(Vector3(cos(angle_b), sin(angle_b), 0) * DATA.IMPACT_RADIUS)
		mesh.surface_end()
	for cue in cues:
		if not cue.has_meta("original_scale"):
			cue.set_meta("original_scale", cue.scale)
		cue.scale = cue.get_meta("original_scale") * (1.0 + DATA.ANTICIPATION_SCALE * progress)
		if cue is MeshInstance3D and cue.material_override is StandardMaterial3D:
			cue.material_override.emission_energy_multiplier = progress * 1.5
	for node in dotted:
		node.visible = (1.0 - progress) * DATA.PROPOSAL_SECONDS <= DATA.RAY_DOTTED_SECONDS

func _process(delta: float) -> void:
	if not exporting:
		clock += delta
		update_proposals(fmod(clock, DATA.PROPOSAL_SECONDS) / DATA.PROPOSAL_SECONDS)

func set_night(value: bool) -> void:
	night = value
	stage.get_node("LightProgression").apply_distance(310.0 if night else 80.0)
	show_case(index)

func _unhandled_key_input(event: InputEvent) -> void:
	if exporting or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_RIGHT: show_case(index + 1)
		KEY_LEFT: show_case(index - 1)
		KEY_1: set_night(false)
		KEY_2: set_night(true)
		KEY_E: await export_both()

func export_both() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("La exportación necesita GPU; la validación headless solo inspecciona geometría")
		return
	exporting = true
	for dark in [false, true]:
		set_night(dark)
		var result := Image.create(ROW.x, ROW.y * DATA.CASES.size(), false, Image.FORMAT_RGBA8)
		for sample in DATA.CASES.size():
			show_case(sample)
			update_proposals(0.7)
			for frame in 3: await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var picture := get_viewport().get_texture().get_image()
			picture.convert(Image.FORMAT_RGBA8)
			result.blit_rect(picture, Rect2i(Vector2i.ZERO, ROW), Vector2i(0, sample * ROW.y))
		var path := "res://docs/galeria_avisos_%s.png" % ("noche" if dark else "dia")
		assert(result.save_png(path) == OK)
		print("GALERIA_AVISOS_OK ", path)
	exporting = false
