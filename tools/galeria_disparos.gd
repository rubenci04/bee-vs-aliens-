extends Node3D
## Inspection only. Real factories, original mesh scale, shared Level 01 scenery/light.
## F6: 1 day, 2 end-of-level nightfall, E export both PNGs. No gameplay changes.
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUTPUT_SIZE := Vector2i(2000, 2080)
const COLUMNS := 4
const CELL_SIZE := Vector2i(480, 272)
const DETAIL_CAMERA_SIZE := 2.2
const DAY_PROGRESS := 0.0
const NIGHT_PROGRESS := 310.0 # The game's existing nightfall profile, not an invented darker palette.
const SAMPLE_SPACING := 12.0
const PREVIEW_SPEED := 1.8 # Slow inspection motion only; game velocities are untouched.
const SAMPLES := [
	["Avispa · Wasp", "stinger", "Aguja violeta · largo total ~1,03 m"],
	["Mosca verde · FlyGreen", "acid", "Gota verde flúor · cuerpo Ø0,36 m"],
	["Mosca común · FlyCommon", "pellet", "Bolita casi negra · Ø0,26 m"],
	["Hormiga · Ant", "pebble", "Piedra naranja tostado · ~0,43 m"],
	["Mariquita · Ladybird", "seed", "Semilla roja · ~0,47 m"],
	["Escarabajo · StagBeetle", "stone", "Piedra gris marrón · ~0,49 m"],
	["Araña · Spider", "web", "Nudo blanco cruzado · ~0,81 m"],
	["Caracol · Snail", "bubble", "Burbuja verde pálido · Ø0,78 m"],
	["Gusano B · WormB", "mud", "Glóbulo marrón · ~0,50 m"],
	["Hongo · MushroomCannon", "spore", "Espora magenta con púas · ~0,62 m"],
	["Tortuga · Turtle (reservada)", "bile", "Bilis verde oliva · ~0,50 m"],
	["Orb genérico · AlienProjectile", "orb", "Cian / halo violeta · Ø0,52 m"],
	["UFO · orb grande (legado)", "boss_orb", "Mismo orb ×1,3 · Ø0,68 m"],
	["Gusano A · WormA", "worm_laser", "Tramo de rayo cian · ancho 0,196 m"],
	["Robot · WalkerMiniboss", "robot_laser", "Tramo de rayo cian pálido · 0,20 m"],
	["Robot / torreta · mortero", "mortar", "Esfera cian sombreada · Ø0,44 m"],
	["Mortero · charco activo", "pool", "Disco cian · r=0,70 m · cámara inclinada"],
	["Robot / tarántula · onda", "wave", "Cúpula cian · 0,99 × 1,30 m"],
	["Tarántula · red atrapante", "net", "Aro + hilos blancos · Ø0,76 m"],
	["Tarántula · hilo activo", "thread", "Tramo de seda blanca · ancho 0,06 m"],
	["Regadera · agua activa", "water", "Columna celeste · 1,10 × 8,50 m"],
	["Aviso de suelo · conservado", "warning", "Naranja / borde claro · Tanda 3"],
	["Regadera · aviso conservado", "water_warning", "Cian / borde claro · 1 s antes"],
	["UFO · UfoBossMine (legado)", "mine", "Mina magenta sombreada · Ø0,52 m"],
	["EyeDrone · láser (legado)", "eye_laser", "Tramo cian · ancho 0,10 m"],
	["UFO · columna (legado)", "ufo_beam", "Cian translúcido · 1,50 × 7,50 m"],
	["Polilla · MothBomb (legado)", "moth_bomb", "Modelo original · escala ×1,5"],
]
var stage: BeeShmupStage
var surface: SubViewport
var heading: Label
var samples: Array[Node3D] = []
var centers: Array[Vector3] = []
var clock := 0.0
var exporting := false
var ready_for_review := false

func _ready() -> void:
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
	_label(canvas, "Aspecto anterior a 8373f31 · cámaras ampliadas, escala 3D original · materiales y jardín reales del nivel 1", Vector2(20, 52), 21)
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
	parent.add_child(label)
	return label

func _build_cell(canvas: Control, index: int) -> void:
	var data: Array = SAMPLES[index]
	var origin := Vector2(20 + (index % COLUMNS) * 495, 126 + (index / COLUMNS) * 278)
	_label(canvas, data[0], origin, 22)
	var view := SubViewport.new()
	view.size = Vector2i(CELL_SIZE.x, 204)
	view.world_3d = get_viewport().world_3d
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var texture := TextureRect.new()
	texture.texture = view.get_texture()
	texture.position = origin + Vector2(0, 29)
	texture.size = Vector2(CELL_SIZE.x, 204)
	canvas.add_child(texture)
	_label(canvas, data[2], origin + Vector2(0, 236), 19)
	var sample := Node3D.new()
	add_child(sample)
	var ground: bool = data[1] in ["pool", "wave", "warning", "water_warning"]
	var center := Vector3(16.0 + index * SAMPLE_SPACING, 0.55 if ground else 2.4, 0)
	if data[1] == "water":
		center.y = BeeLevel01WateringEvent.COLUMN_TOP_Y * 0.5 + BeeLevel01WateringEvent.GROUND_Y
	sample.position = center
	_build_sample(sample, data[1])
	samples.append(sample)
	centers.append(center)
	var camera := Camera3D.new()
	view.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.0 if data[1] in ["water", "ufo_beam"] else DETAIL_CAMERA_SIZE
	camera.position = Vector3(center.x, center.y, stage.camera.global_position.z)
	camera.current = true
	if data[1] == "pool":
		# Inspect the original 2 cm flat disc from above; frontal gameplay view is nearly edge-on.
		camera.position.y += 5.0
		camera.look_at(center, Vector3.UP)

func _build_sample(sample: Node3D, kind: String) -> void:
	if BeeShotStyles.has_style(StringName(kind)):
		BeeShotStyles.dress(sample, StringName(kind))
	elif kind in ["orb", "boss_orb"]:
		BeeShotPalette.dress_enemy(sample, 1.3 if kind == "boss_orb" else 1.0)
	elif kind in ["worm_laser", "robot_laser", "thread", "eye_laser"]:
		var color := Color(0.35, 1, 1, 0.95) if kind == "worm_laser" else BeeGameSettings.ROBOT_LASER_COLOR
		var width := 0.196 if kind == "worm_laser" else 0.2
		if kind == "eye_laser":
			color = EyeDroneEnemy.LASER_COLOR
			width = EyeDroneEnemy.LASER_WIDTH
		if kind == "thread":
			color = Color(0.95, 0.95, 0.9, 0.9)
			width = 0.06
		var line := BeeAttackVisuals.line(sample, Vector3.ZERO, Vector3.RIGHT * 3, width, color)
		line.top_level = false
		line.position = Vector3.ZERO
	elif kind in ["mortar", "mine"]:
		var ball := BeeAttackVisuals.sphere(sample, sample.global_position, 0.26 if kind == "mine" else AlienMortarShell.SHELL_RADIUS, UfoBossMine.COLOR if kind == "mine" else AlienMortarShell.COLOR)
		ball.top_level = false
		ball.position = Vector3.ZERO
	elif kind in ["pool", "warning", "water_warning"]:
		var color := Color(AlienMortarShell.COLOR, 0.55) if kind == "pool" else BeeGroundShockwave.WARNING_COLOR
		if kind == "water_warning":
			color = BeeLevel01WateringEvent.WARNING_COLOR
		var disc := BeeAttackVisuals.ground_disc(sample, sample.global_position, 0.7, color, kind != "pool")
		disc.top_level = false
		disc.position = Vector3(0, -0.35, 0)
		if kind == "water_warning":
			var stripe := BeeAttackVisuals.line(sample, Vector3.ZERO, Vector3.RIGHT * 1.6, 0.14, color, true)
			stripe.top_level = false
			stripe.position = Vector3(0, -0.15, 0.08)
	elif kind == "wave":
		var wave := BeeGroundShockwave.new()
		wave.process_mode = Node.PROCESS_MODE_DISABLED
		sample.add_child(wave)
		wave.position.y = -0.55
		wave._build()
	elif kind == "net":
		var net := TarantulaWebNet.new()
		net.process_mode = Node.PROCESS_MODE_DISABLED
		sample.add_child(net)
		net._build()
	elif kind == "water":
		var node := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = BeeLevel01WateringEvent.COLUMN_WIDTH * 0.45
		mesh.bottom_radius = BeeLevel01WateringEvent.COLUMN_WIDTH * 0.5
		mesh.height = BeeLevel01WateringEvent.COLUMN_TOP_Y
		mesh.radial_segments = 10
		mesh.material = BeeAttackVisuals.material(BeeLevel01WateringEvent.COLUMN_COLOR)
		node.mesh = mesh
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sample.add_child(node)
	elif kind == "ufo_beam":
		var node := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(UfoBoss01.BEAM_WIDTH, UfoBoss01.BEAM_TOP_Y - UfoBoss01.BEAM_GROUND_Y, 0.5)
		var factory := UfoBoss01.new()
		mesh.material = factory._unshaded(Color(0.3, 1, 1, 0.55))
		factory.free()
		node.mesh = mesh
		sample.add_child(node)
	elif kind == "moth_bomb":
		var model := AssetFauna.BOMB_MODEL.instantiate() as Node3D
		model.scale = Vector3.ONE * 1.5
		sample.add_child(model)

func set_profile(night: bool) -> void:
	stage.get_node("LightProgression").apply_distance(NIGHT_PROGRESS if night else DAY_PROGRESS)
	heading.text = "DISPAROS RESTAURADOS · " + ("NOCHE / ANOCHECER REAL DEL NIVEL" if night else "DÍA")

func _process(delta: float) -> void:
	if not ready_for_review:
		return
	clock += delta
	for i in samples.size():
		if BeeShotStyles.has_style(StringName(SAMPLES[i][1])) or SAMPLES[i][1] in ["orb", "boss_orb"]:
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
	for night in [false, true]:
		set_profile(night)
		clock = 0.0
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var path := "res://docs/galeria_disparos_%s.png" % ("noche" if night else "dia")
		var error := surface.get_texture().get_image().save_png(path)
		assert(error == OK, "No se pudo guardar " + path)
		print("GALERIA_EXPORTADA ", path)
	exporting = false
