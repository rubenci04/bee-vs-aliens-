extends Node3D
## Tanda 3c. Gallery-only material copies and proposed shapes, never used by the game.
## F6: 1 day, 2 end-of-level nightfall, E export both PNGs. No gameplay changes.
const EMISSION_GAIN := 0.8
const ALBEDO_GAIN := 0.35
const HALO_ALPHA := 0.10
const TRAIL_ALPHA := 0.55
const B_RADII := {&"pebble": 0.16, &"seed": 0.18, &"stone": 0.23, &"mud": 0.20, &"pellet": 0.19, &"bubble": 0.42}
const COLORS := {&"pebble": Color("ef16cf"), &"seed": Color("d70c43"), &"stone": Color("135fff"), &"mud": Color("dfef16"), &"pellet": Color("00eaff"), &"bubble": Color("00d9f5")}
const CORE_COLORS := {&"stone": Color("69ceff"), &"mud": Color("f7ffd0")}
const HALO_COLORS := {&"seed": Color("fff0d5")}
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUTPUT_SIZE := Vector2i(1600, 2100)
const COLUMNS := 2
const CELL_SIZE := Vector2i(770, 310)
const DETAIL_CAMERA_SIZE := 2.2
const DAY_PROGRESS := 0.0
const NIGHT_PROGRESS := 310.0 # The game's existing nightfall profile, not an invented darker palette.
const SAMPLE_SPACING := 12.0
const PREVIEW_SPEED := 1.8 # Slow inspection motion only; game velocities are untouched.
const SAMPLES := [
	["Hormiga · Ant · A", "pebble_A", "A: Piedra original ~0,43 m"],
	["Hormiga · Ant · B", "pebble_B", "B: Dardo corto facetado 0,60 m"],
	["Mariquita · Ladybird · A", "seed_A", "A: Semilla original ~0,47 m"],
	["Mariquita · Ladybird · B", "seed_B", "B: Semilla angular 0,56 m"],
	["Escarabajo · StagBeetle · A", "stone_A", "A: Piedra original ~0,49 m"],
	["Escarabajo · StagBeetle · B", "stone_B", "B: Cristal hexagonal 0,56 m"],
	["Gusano B · WormB · A", "mud_A", "A: Glóbulo original ~0,50 m"],
	["Gusano B · WormB · B", "mud_B", "B: Gota facetada 0,62 m"],
	["Mosca común · FlyCommon · A", "pellet_A", "A: Bolita original Ø0,26 m"],
	["Mosca común · FlyCommon · B", "pellet_B", "B: Perdigón facetado Ø0,38 m"],
	["Caracol · Snail · A", "bubble_A", "A: Burbuja original Ø0,78 m"],
	["Caracol · Snail · B", "bubble_B", "B: Burbuja facetada Ø0,84 m"],
]
var stage: BeeShmupStage
var surface: SubViewport
var heading: Label
var samples: Array[Node3D] = []
var centers: Array[Vector3] = []
var clock := 0.0
var exporting := false
var ready_for_review := false
var gallery_font: SystemFont

func _ready() -> void:
	gallery_font = SystemFont.new()
	gallery_font.font_names = PackedStringArray(["Arial", "DejaVu Sans"])
	stage = LEVEL.instantiate() as BeeShmupStage
	add_child(stage)
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	stage.camera.clear_current()
	for child in stage.get_children():
		if child is CanvasLayer:
			child.visible = false
		elif child is Node3D and child.name not in ["Scenery", "VisualTarget01", "Sun", "Ground", "GroundExtension", "AssetDressing", "DomesticGarden", "LiveGarden"]:
			child.hide()
	# Quiet gallery: scenery stays, live combat/ambient particles do not run.
	for audio in stage.find_children("*", "AudioStreamPlayer3D", true, false):
		audio.stop()
	surface = SubViewport.new()
	surface.size = OUTPUT_SIZE
	surface.disable_3d = true
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(surface)
	var canvas := ColorRect.new()
	canvas.color = Color("101722")
	canvas.size = Vector2(OUTPUT_SIZE)
	surface.add_child(canvas)
	heading = _label(canvas, "", Vector2(20, 12), 30)
	_label(canvas, "TANDA 3c · SOLO PROPUESTAS · A: forma/tamaño actual + luz · B: forma facetada · juego intacto", Vector2(20, 52), 21)
	_label(canvas, "1: DÍA   2: NOCHE   E: exportar ambas imágenes · movimiento lento para inspeccionar estelas", Vector2(20, 82), 19)
	for i in SAMPLES.size():
		_build_cell(canvas, i)
	var display := TextureRect.new()
	display.texture = surface.get_texture()
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var ui := CanvasLayer.new()
	add_child(ui)
	ui.add_child(display)
	set_profile(false)
	ready_for_review = true
	if "--export-gallery" in OS.get_cmdline_user_args():
		await export_both()
		get_tree().quit()

func _label(parent: Node, text: String, pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", gallery_font)
	parent.add_child(label)
	return label

func _build_cell(canvas: Control, index: int) -> void:
	var data: Array = SAMPLES[index]
	var origin := Vector2(20 + (index % COLUMNS) * 790, 126 + (index / COLUMNS) * 326)
	_label(canvas, data[0], origin, 22)
	var view := SubViewport.new()
	view.size = Vector2i(CELL_SIZE.x, 246)
	view.world_3d = get_viewport().world_3d
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var texture := TextureRect.new()
	texture.texture = view.get_texture()
	texture.position = origin + Vector2(0, 29)
	texture.size = Vector2(CELL_SIZE.x, 246)
	canvas.add_child(texture)
	_label(canvas, data[2], origin + Vector2(0, 280), 19)
	var sample := Node3D.new()
	add_child(sample)
	var center := Vector3(40.0 + floori(index / 2.0) * 40.0, 2.4, 0)
	sample.position = center
	_build_sample(sample, data[1])
	samples.append(sample)
	centers.append(center)
	var camera := Camera3D.new()
	view.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = DETAIL_CAMERA_SIZE
	camera.position = Vector3(center.x, center.y, stage.camera.global_position.z)
	camera.cull_mask = 1 | (1 << (index + 1))
	camera.current = true
	for visual in sample.find_children("*", "VisualInstance3D", true, false):
		visual.layers = 1 << (index + 1)

func _build_sample(sample: Node3D, kind: String) -> void:
	var parts := kind.split("_")
	var style := StringName(parts[0])
	var option := parts[1]
	var color: Color = COLORS[style]
	var body: Node3D
	if option == "A":
		body = BeeShotStyles.build(style)
		sample.add_child(body)
		# Own resources: never mutate cached game meshes/materials.
		for visual: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
			var old := visual.mesh.surface_get_material(0) as StandardMaterial3D
			var alpha := old.albedo_color.a
			var tint := color
			if visual.name in ["Core", "Highlight"]:
				tint = CORE_COLORS.get(style, color.lightened(0.32))
			if visual.name in ["Halo", "CoreHalo", "Glow", "Dust", "Fluff"]:
				tint = HALO_COLORS.get(style, color.lightened(0.45))
				alpha = HALO_ALPHA
			visual.mesh = visual.mesh.duplicate()
			visual.material_override = _emissive(Color(tint, alpha))
			if visual.name == "Core" and style in [&"stone", &"mud"]:
				visual.position.z = 0.17
	else:
		body = Node3D.new()
		sample.add_child(body)
		match style:
			&"pebble":
				var shaft := _piece(body, _faceted_sphere(B_RADII[style]), color)
				shaft.scale = Vector3(1.25, 0.8, 0.8)
				var cone := CylinderMesh.new()
				cone.top_radius = 0.0
				cone.bottom_radius = 0.16
				cone.height = 0.30
				cone.radial_segments = 4
				var tip := _piece(body, _flat(cone), color)
				tip.rotation.z = -PI * 0.5
				tip.position.x = 0.25
			&"seed":
				var seed := _piece(body, _faceted_sphere(B_RADII[style]), color)
				seed.scale = Vector3(1.55, 0.85, 0.8)
				var seam := _piece(body, _faceted_sphere(0.045), color.darkened(0.35))
				seam.position = Vector3(0, 0.07, 0.13)
			&"stone":
				var crystal := _piece(body, _faceted_sphere(B_RADII[style]), color)
				crystal.scale = Vector3(1.22, 0.85, 0.85)
			&"mud":
				_piece(body, _faceted_sphere(B_RADII[style]), color)
				var cone := CylinderMesh.new()
				cone.top_radius = 0.0
				cone.bottom_radius = 0.17
				cone.height = 0.32
				cone.radial_segments = 5
				var tip := _piece(body, _flat(cone), color)
				tip.rotation.z = PI * 0.5
				tip.position.x = -0.26
			&"pellet":
				_piece(body, _faceted_sphere(B_RADII[style]), color)
			&"bubble":
				_piece(body, _faceted_sphere(B_RADII[style]), Color(color, 0.24))
				var rim := TorusMesh.new()
				rim.inner_radius = 0.365
				rim.outer_radius = 0.42
				rim.rings = 10
				rim.ring_segments = 4
				var edge := _piece(body, _flat(rim), color)
				edge.rotation.x = PI * 0.5
				_piece(body, _faceted_sphere(0.13), color)
		if style in [&"stone", &"mud"]:
			var core := _piece(body, _faceted_sphere(0.07), CORE_COLORS[style])
			core.position.z = 0.18
	# Low-opacity light shell, never an opaque white disk or black outline.
	if option == "B" or style != &"bubble":
		var halo_radius := 0.25 if style != &"bubble" else 0.46
		var halo := _piece(body, _faceted_sphere(halo_radius), Color(HALO_COLORS.get(style, color.lightened(0.45)), HALO_ALPHA))
		halo.name = "SoftHalo"
	if style == &"bubble" and option == "A":
		# Saturated rim around the original translucent sphere; body dimensions unchanged.
		var rim := TorusMesh.new()
		rim.inner_radius = 0.36
		rim.outer_radius = 0.39
		var edge := _piece(body, rim, color)
		edge.rotation.x = PI * 0.5
	var tail := BeeShotStyles.trail(style)
	tail.mesh = tail.mesh.duplicate()
	tail.mesh.material = _emissive(Color(color, TRAIL_ALPHA))
	sample.add_child(tail)
	tail.emitting = true

func _emissive(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r * ALBEDO_GAIN, color.g * ALBEDO_GAIN, color.b * ALBEDO_GAIN, color.a)
	material.emission_enabled = true
	material.emission = Color(color, 1.0)
	material.emission_energy_multiplier = EMISSION_GAIN
	material.roughness = 1.0
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		material.emission_enabled = false
	return material

func _piece(parent: Node3D, mesh: Mesh, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _emissive(color)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)
	return visual

func _faceted_sphere(radius: float) -> ArrayMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	return _flat(mesh)

func _flat(mesh: Mesh) -> ArrayMesh:
	var vertices := mesh.get_faces()
	var normals := PackedVector3Array()
	for i in range(0, vertices.size(), 3):
		var normal := (vertices[i + 2] - vertices[i]).cross(vertices[i + 1] - vertices[i]).normalized()
		for j in 3:
			normals.append(normal)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

func set_profile(night: bool) -> void:
	stage.get_node("LightProgression").apply_distance(NIGHT_PROGRESS if night else DAY_PROGRESS)
	heading.text = "PROPUESTAS A / B · " + ("NOCHE / ANOCHECER REAL DEL NIVEL" if night else "DÍA")

func _process(delta: float) -> void:
	if not ready_for_review:
		return
	clock += delta
	for i in samples.size():
		samples[i].position.x = centers[i].x + fmod(clock * PREVIEW_SPEED, 1.4) - 0.7

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			set_profile(false)
		elif event.keycode == KEY_2:
			set_profile(true)
		elif event.keycode == KEY_E and not exporting:
			export_both()

func export_both() -> void:
	exporting = true
	# Re-export day last, once the font atlas and all 12 viewport textures are warm.
	for night in [false, true, false]:
		set_profile(night)
		clock = 0.0
		await get_tree().create_timer(1.2).timeout
		for frame in 4:
			await RenderingServer.frame_post_draw
		var path := "res://docs/galeria_propuestas_%s.png" % ("noche" if night else "dia")
		var error := surface.get_texture().get_image().save_png(path)
		assert(error == OK, "No se pudo guardar " + path)
		print("GALERIA_EXPORTADA ", path)
	exporting = false
