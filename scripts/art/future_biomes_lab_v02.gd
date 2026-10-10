extends "res://scripts/art/future_biomes_lab.gd"
## Uses the same camera, lighting, Style C, cleanup and release helpers as V01.
const NEW_IDS := ["controlled_stag_beetle", "controlled_woodland_snail", "alien_seed_carrier", "alien_signal_relay"]
const NEW_NAMES := ["ESCARABAJO CIERVO", "CARACOL DE BOSQUE", "NAVE DE CARGA", "REPETIDOR ALIENÍGENA"]

func _make_ui() -> void:
	ui = CanvasLayer.new()
	ui.name = "GalleryUI"
	add_child(ui)
	var backdrop := Panel.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	backdrop.offset_bottom = 186
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(.07,.09,.11,.82)
	backdrop.add_theme_stylebox_override("panel",bg)
	ui.add_child(backdrop)
	title = Label.new()
	title.position = Vector2(28,22)
	title.add_theme_font_size_override("font_size",27)
	title.add_theme_color_override("font_color",Color("faf0d5"))
	ui.add_child(title)
	subtitle = Label.new()
	subtitle.position = Vector2(28,61)
	subtitle.add_theme_font_size_override("font_size",16)
	subtitle.add_theme_color_override("font_color",Color("ded9c2"))
	ui.add_child(subtitle)
	var row := HBoxContainer.new()
	row.position = Vector2(28,104)
	row.add_theme_constant_override("separation",8)
	ui.add_child(row)
	for i in 3:
		var button := Button.new()
		button.text = ["F · Bosque", "O · Tecnología", "E · Estudio"][i]
		button.pressed.connect(show_page.bind(i))
		row.add_child(button)
	var release := Button.new()
	release.text = "L · Poner / quitar control"
	release.pressed.connect(toggle_control)
	row.add_child(release)
	var picker := OptionButton.new()
	picker.add_item("Ver una pieza…")
	for label in NEW_NAMES:
		picker.add_item(label.capitalize())
	picker.item_selected.connect(func(index: int):
		if index > 0:
			inspect_asset(NEW_IDS[index-1],false)
	)
	row.add_child(picker)
	var tip := Label.new()
	tip.text = "1–4: piezas   ·   V: lateral / 3⁄4   ·   H: ocultar interfaz   ·   P: pausa   ·   Flechas: cambiar vista"
	tip.position = Vector2(28,152)
	tip.add_theme_font_size_override("font_size",14)
	ui.add_child(tip)

func asset(id: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	if not NEW_IDS.has(id):
		return super.asset(id,pos,factor)
	var model := (load("res://scenes/art_labs/assets_v02/"+id+".tscn") as PackedScene).instantiate() as Node3D
	model.name = id
	stage.add_child(model)
	model.position = pos
	model.scale = Vector3.ONE*factor
	model.controlled = controlled
	return model

func show_page(index: int) -> void:
	_clear()
	page = posmod(index,3)
	creature_mode = false
	inspected_id = ""
	camera.size = 11.5
	camera.position = Vector3(0,0,20)
	camera.rotation = Vector3.ZERO
	ui.visible = true
	match page:
		0: _forest()
		1: _fleet()
		2: _studio()

func _forest() -> void:
	title.text = "BEE ALIEN   /   BOSQUE · TANDA 02"
	subtitle.text = "Escarabajo y caracol liberables · Vegetación natural · Repetidor portátil"
	environment.environment.background_color = Color("8c9270")
	# Atmospheric broad trunks and leaves are gallery dressing, not imported assets.
	for i in 5:
		var x := -10.0+i*4.8
		shape(Vector3(x,0,-7),Vector3(.9+i*.08,8,.5),Color("747d60"),true)
	for i in 4:
		var x := -8.0+i*5.4
		shape(Vector3(x,-1,-4),Vector3(.5,7,.6),Color("536045"),true)
	shape(Vector3(0,-3.8,-2),Vector3(16,2,.7),Color("5d6140"),true)
	shape(Vector3(0,-2.45,0),Vector3(15,.65,.4),Color("665139"),true)
	shape(Vector3(0,-1.99,.1),Vector3(16,.15,.5),Color("8a7947"),true)
	for i in 12:
		var x := -10.0+fmod(i*2.31,21.0)
		var leaf := shape(Vector3(x,3.8+sin(i)*.7,-3),Vector3(2.1,.58,.6),Color("526b3d"),true)
		leaf.rotation.z = sin(i*3.1)*.4
	asset("controlled_stag_beetle",Vector3(-3.8,-1.8,1),1.85)
	asset("controlled_woodland_snail",Vector3(3.2,-1.8,1),1.8)
	asset("alien_signal_relay",Vector3(.1,-1.8,.5),1.15)
	bee_anchor(Vector3(-1.2,1.0,2))
	for i in 22:
		shape(Vector3(sin(i*11.3)*8.8,-.5+fmod(i*1.73,4.1),-2),Vector3.ONE*.017,Color("cbbd7d"),true)

func _fleet() -> void:
	title.text = "BEE ALIEN   /   TECNOLOGÍA · TANDA 02"
	subtitle.text = "Nave de carga con dos módulos · Repetidor de control · Interceptor anterior como referencia"
	environment.environment.background_color = Color("222c3b")
	for i in 44:
		shape(Vector3(sin(i*19.9)*11,cos(i*7.13)*5.6,-6),Vector3.ONE*(.015+fmod(i*.013,.018)),Color("ada793"),true)
	var ship := asset("alien_seed_carrier",Vector3(-.6,-.3,1),2.3)
	floaters.append(ship)
	var small := asset("orbital_skimmer",Vector3(-5.8,.9,-1),1.2)
	floaters.append(small)
	asset("alien_signal_relay",Vector3(5,-1.6,1),2.7)
	bee_anchor(Vector3(-4,-1.7,2))

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO · TANDA 02"
	subtitle.text = "Cuatro siluetas laterales · H: ficha sin texto, interfaz ni entorno"
	environment.environment.background_color = Color("777970")
	camera.size = 10.2
	asset("controlled_stag_beetle",Vector3(-3,.75,0),1.85)
	asset("controlled_woodland_snail",Vector3(3,.3,0),1.85)
	asset("alien_seed_carrier",Vector3(-3,-2.3,0),1.85)
	asset("alien_signal_relay",Vector3(3,-3.4,0),2.7)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var model := stage.get_child(0) as Node3D
	if id == "controlled_stag_beetle":
		model.position = Vector3(.5,-.65,0)
	elif id == "controlled_woodland_snail":
		model.position.y = -1.0
	elif id == "alien_signal_relay":
		model.scale = Vector3.ONE*2.7
		model.position.y = -1.25

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,not controlled,three_quarter)
	ui.visible = true
	title.text = "BEE ALIEN   /   " + NEW_NAMES[NEW_IDS.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · L: liberar fauna · H: ficha limpia"

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F: show_page(0)
		KEY_O: show_page(1)
		KEY_E: show_page(2)
		KEY_1, KEY_2, KEY_3, KEY_4: inspect_asset(NEW_IDS[event.keycode-KEY_1],false)
		KEY_V:
			if not inspected_id.is_empty():
				inspect_asset(inspected_id,not angled)
		KEY_LEFT: show_page(page-1)
		KEY_RIGHT: show_page(page+1)
		KEY_L: toggle_control()
		KEY_H: ui.visible = not ui.visible
		KEY_P: animating = not animating
