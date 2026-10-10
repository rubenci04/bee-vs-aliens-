extends "res://scripts/art/future_biomes_lab.gd"
## Uses the same camera, lighting, Style C, cleanup and release helpers as V01.
const NEW_IDS := ["garden_sapling", "flowering_shrub", "empty_drink_can", "wrapped_candy"]
const NEW_NAMES := ["ÁRBOL JOVEN", "ARBUSTO FLORAL", "LATA VACÍA", "CARAMELO ENVUELTO"]

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
		button.text = ["J · Jardín", "S · Suelo", "E · Estudio"][i]
		button.pressed.connect(show_page.bind(i))
		row.add_child(button)
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
	tip.text = "1–4: piezas   ·   V: lateral / 3⁄4   ·   H: ocultar interfaz   ·   Flechas: cambiar vista"
	tip.position = Vector2(28,152)
	tip.add_theme_font_size_override("font_size",14)
	ui.add_child(tip)

func asset(id: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	if not NEW_IDS.has(id):
		return super.asset(id,pos,factor)
	var model := (load("res://scenes/art_labs/assets_v06/"+id+".tscn") as PackedScene).instantiate() as Node3D
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
		0: _garden()
		1: _ground()
		2: _studio()

func _garden() -> void:
	title.text = "BEE ALIEN   /   JARDÍN · TANDA 06"
	subtitle.text = "Árbol joven de copa suave · Arbusto con margaritas · Escala diminuta de Bee"
	environment.environment.background_color = Color("929577")
	for i in 5:
		shape(Vector3(-10+i*5.5,-.3,-8),Vector3(2.8,4.8,.6),Color("7d8664"),true)
	shape(Vector3(0,-4.3,-5),Vector3(17,.8,.8),Color("766747"),true)
	shape(Vector3(0,-3.8,-3),Vector3(17,.22,.4),Color("596641"),true)
	asset("garden_sapling",Vector3(-4.5,-3.6,0),2.15)
	asset("flowering_shrub",Vector3(2.5,-3.65,1),2.4)
	asset("flowering_shrub",Vector3(6.3,-3.65,-.5),1.15)
	bee_anchor(Vector3(-.6,-.25,2))
	for i in 22:
		shape(Vector3(sin(i*12.7)*9.5,-3.4+fmod(i*1.13,6),-2),Vector3.ONE*.016,Color("d6c28d"),true)

func _ground() -> void:
	title.text = "BEE ALIEN   /   SUELO RESIDENCIAL · TANDA 06"
	subtitle.text = "Lata vacía con abertura y anilla · Caramelo envuelto · Objetos humanos sin marcas"
	environment.environment.background_color = Color("a19b7e")
	shape(Vector3(0,-3.2,-6),Vector3(18,.7,.5),Color("8c7b57"))
	for i in 7:
		shape(Vector3(-12+i*4,-.6,-8),Vector3(.65,5,.2),Color("858872"))
	asset("empty_drink_can",Vector3(-3.2,-2.5,1),4.5)
	asset("wrapped_candy",Vector3(3.8,-2.5,1),3.0)
	asset("flowering_shrub",Vector3(7.2,-2.5,-1),1.1)
	bee_anchor(Vector3(1.2,.1,2))
	for i in 10:
		shape(Vector3(-10+i*2.4,-2.6,-3),Vector3(.12,.45,.06),Color("627244"),true)

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO · TANDA 06"
	subtitle.text = "Vegetación y objetos de suelo · H: fichas limpias sin texto, interfaz ni entorno"
	environment.environment.background_color = Color("777970")
	camera.size = 10.8
	asset("garden_sapling",Vector3(-3.8,-.5,0),1.2)
	asset("flowering_shrub",Vector3(3.7,.3,0),1.8)
	asset("empty_drink_can",Vector3(-3.8,-3.8,0),2.6)
	asset("wrapped_candy",Vector3(3.7,-2.9,0),2.5)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var model := stage.get_child(0) as Node3D
	match id:
		"garden_sapling":
			model.scale = Vector3.ONE*1.25
			model.position.y = -1.95
		"flowering_shrub":
			model.scale = Vector3.ONE*3.0
			model.position.y = -1.65
		"empty_drink_can":
			model.scale = Vector3.ONE*3.8
			model.position.y = -1.5
			if three_quarter:
				model.rotation.y = deg_to_rad(30)
		"wrapped_candy":
			model.scale = Vector3.ONE*3.8
			model.position.y = -.70

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,false,three_quarter)
	ui.visible = true
	title.text = "BEE ALIEN   /   " + NEW_NAMES[NEW_IDS.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · H: ficha limpia · Pieza de entorno sin emisión"

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_J: show_page(0)
		KEY_S: show_page(1)
		KEY_E: show_page(2)
		KEY_1, KEY_2, KEY_3, KEY_4: inspect_asset(NEW_IDS[event.keycode-KEY_1],false)
		KEY_V:
			if not inspected_id.is_empty():
				inspect_asset(inspected_id,not angled)
		KEY_LEFT: show_page(page-1)
		KEY_RIGHT: show_page(page+1)
		KEY_H: ui.visible = not ui.visible

