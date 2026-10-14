extends Node3D
## Tanda 3d. Actual game projectile scene + actual style factory, with Level 01 lighting.
## F6: 1 day, 2 end-of-level nightfall, E export both PNGs. No gameplay changes.
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUTPUT_SIZE := Vector2i(1600, 1120)
const COLUMNS := 2
const CELL_SIZE := Vector2i(770, 310)
const DETAIL_CAMERA_SIZE := 2.2
const DAY_PROGRESS := 0.0
const NIGHT_PROGRESS := 310.0 # The game's existing nightfall profile, not an invented darker palette.
const SAMPLE_SPACING := 40.0
const PREVIEW_SPEED := 1.8 # Slow inspection motion only; game velocities are untouched.
const SAMPLES := [
	["Hormiga · Ant", "pebble", "Dardo facetado magenta · ~0,60 m"],
	["Mariquita · Ladybird", "seed", "Semilla carmesí · halo cálido reforzado"],
	["Escarabajo · StagBeetle", "stone", "Cristal azul eléctrico · ~0,56 m"],
	["Gusano B · WormB", "mud", "Gota facetada amarilla · ~0,62 m"],
	["Mosca común · FlyCommon", "pellet", "Perdigón cian · Ø0,38 m"],
	["Caracol · Snail", "bubble", "Burbuja facetada cian · Ø0,84 m"],
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
	gallery_font.font_names = PackedStringArray(["Consolas", "DejaVu Sans Mono"])
	stage = LEVEL.instantiate() as BeeShmupStage
	add_child(stage)
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	for node in stage.find_children("*", "", true, false):
		node.process_mode = Node.PROCESS_MODE_DISABLED
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
	_label(canvas, "TANDA 3d · OPCIÓN B APLICADA · proyectiles reales del juego · cámaras ampliadas · hitboxes intactas", Vector2(20, 52), 21)
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
	# A single font atlas size avoids Compatibility multi-viewport glyph corruption.
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_font_override("font", gallery_font)
	label.z_index = 10
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
	var center := Vector3(40.0 + index * SAMPLE_SPACING, 2.4, 0)
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
	var shot := preload("res://scenes/projectiles/toon/alien_bolt.tscn").instantiate() as AlienEnemyProjectile
	shot.set_meta("shot_style", StringName(kind))
	sample.add_child(shot)
	shot.set_physics_process(false) # Inspection only: do not fly away or cause damage.
	shot.hitbox.set_enabled(false)
	BeeShotStyles.dress(shot, StringName(kind))

func set_profile(night: bool) -> void:
	stage.get_node("LightProgression").apply_distance(NIGHT_PROGRESS if night else DAY_PROGRESS)
	heading.text = "DISPAROS FINALES DEL JUEGO · " + ("NOCHE / ANOCHECER REAL DEL NIVEL" if night else "DÍA")
	for label in surface.find_children("*", "Label", true, false):
		label.queue_redraw()

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
	# Re-export day last, once the font atlas and all six viewport textures are warm.
	for night in [false, true, false]:
		set_profile(night)
		clock = 0.0
		await get_tree().create_timer(1.2).timeout
		# Freeze completed 3D textures while the 2D labels finish their redraw.
		for view in get_children():
			if view is SubViewport and view != surface:
				view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		for label in surface.find_children("*", "Label", true, false):
			label.queue_redraw()
		for frame in 4:
			await RenderingServer.frame_post_draw
		var path := "res://docs/galeria_final_%s.png" % ("noche" if night else "dia")
		var error := surface.get_texture().get_image().save_png(path)
		assert(error == OK, "No se pudo guardar " + path)
		print("GALERIA_EXPORTADA ", path)
		for view in get_children():
			if view is SubViewport and view != surface:
				view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	exporting = false
