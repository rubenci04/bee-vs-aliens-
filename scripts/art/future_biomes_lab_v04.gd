extends "res://scripts/art/future_biomes_lab.gd"
## Uses the same camera, lighting, Style C, cleanup and release helpers as V01.
const NEW_IDS := ["controlled_stick_insect", "controlled_pigeon", "controlled_mouse", "giant_bottle_cap"]
const NEW_NAMES := ["BICHO PALO", "PALOMA", "RATÓN", "TAPA DE BOTELLA"]

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
		button.text = ["F · Bosque", "R · Residencial", "E · Estudio"][i]
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
	var model := (load("res://scenes/art_labs/assets_v04/"+id+".tscn") as PackedScene).instantiate() as Node3D
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
		1: _residential()
		2: _studio()

func _forest() -> void:
	title.text = "BEE ALIEN   /   BOSQUE · TANDA 04"
	subtitle.text = "Bicho palo entre ramas · Fauna natural con control externo · Bee como referencia de escala"
	environment.environment.background_color = Color("62654a")
	for i in 6:
		shape(Vector3(-11+i*4.3,0,-7),Vector3(.55,8,.5),Color("535a3f"),true)
	for i in 10:
		shape(Vector3(-11+i*2.6,-4.7+sin(i)*.4,-5),Vector3(2.5,1.2,.6),Color("455337"),true)
	var branch := shape(Vector3(0,-2.3,-2),Vector3(12,.20,.3),Color("78613d"),true)
	branch.rotation.z = deg_to_rad(-4)
	for i in 8:
		var leaf := shape(Vector3(-8+i*2.4,-1.8+sin(i)*.4,-3),Vector3(.8,.24,.1),Color("6c7545"),true)
		leaf.rotation.z = deg_to_rad(28 if i%2==0 else -28)
	asset("controlled_stick_insect",Vector3(-.7,.3,1),3.5)
	asset("controlled_mouse",Vector3(3.3,-2.4,1),1.45)
	bee_anchor(Vector3(-5.3,-1.2,2))
	for i in 20:
		shape(Vector3(sin(i*13.5)*9.8,-3.8+fmod(i*1.23,7),-2),Vector3.ONE*.013,Color("c6bc8c"),true)

func _residential() -> void:
	title.text = "BEE ALIEN   /   JARDÍN RESIDENCIAL · TANDA 04"
	subtitle.text = "Paloma en vuelo · Ratón de suelo · Tapa gigante de pintura terracota, sin energía alienígena"
	environment.environment.background_color = Color("949782")
	# Soft, distant house blocks; review scenery, not additional exported models.
	shape(Vector3(-6,1,-8),Vector3(3.6,4,.4),Color("838470"))
	shape(Vector3(4,1,-8),Vector3(4.0,4,.4),Color("a19c83"))
	for i in 4:
		shape(Vector3(-8+i*4.8,1.4,-7),Vector3(.75,1.4,.15),Color("6e796a"))
	shape(Vector3(0,-4.0,-4),Vector3(15,.6,.8),Color("8b7f60"),true)
	var pigeon := asset("controlled_pigeon",Vector3(-2.9,-.4,1),3.0)
	floaters.append(pigeon)
	asset("controlled_mouse",Vector3(2.8,-2.5,1),2.4)
	var cap := asset("giant_bottle_cap",Vector3(-4.4,-2.8,.5),2.5)
	cap.rotation.x = deg_to_rad(28)
	bee_anchor(Vector3(-6.5,-1.5,2))
	for i in 10:
		shape(Vector3(-10+i*2.2,-3.4,-2),Vector3(.1,.4,.04),Color("687247"),true)

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO · TANDA 04"
	subtitle.text = "Tres animales liberables y un objeto humano · H: ficha limpia sin texto ni interfaz"
	environment.environment.background_color = Color("777970")
	camera.size = 10.8
	asset("controlled_stick_insect",Vector3(-3.4,1.0,0),2.4)
	asset("controlled_pigeon",Vector3(3.7,.45,0),2.2)
	asset("controlled_mouse",Vector3(-4.1,-2.7,0),2.2)
	var cap := asset("giant_bottle_cap",Vector3(3.7,-2.6,0),2.4)
	cap.rotation.x = deg_to_rad(28)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var model := stage.get_child(0) as Node3D
	match id:
		"controlled_stick_insect":
			model.scale = Vector3.ONE*2.45
			model.position.x = .65
		"controlled_pigeon":
			model.scale = Vector3.ONE*2.35
			model.position.y = -.9
		"controlled_mouse":
			model.scale = Vector3.ONE*2.5
			model.position.x = -1.25
		"giant_bottle_cap":
			model.scale = Vector3.ONE*3.8
			if three_quarter:
				model.rotation.x += deg_to_rad(25)

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,not controlled,three_quarter)
	ui.visible = true
	title.text = "BEE ALIEN   /   " + NEW_NAMES[NEW_IDS.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · L: quitar el receptor · H: ficha limpia"
	if id == "giant_bottle_cap":
		subtitle.text = "Objeto humano sin control alienígena · V: lateral / 3⁄4 · H: ficha limpia"

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F: show_page(0)
		KEY_R: show_page(1)
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

