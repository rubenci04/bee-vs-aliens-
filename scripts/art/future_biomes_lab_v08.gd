extends "res://scripts/art/future_biomes_lab.gd"
## Uses the same camera, lighting, Style C, cleanup and release helpers as V01.
const NEW_IDS := ["coastal_rowboat", "shore_wave_module", "shore_rock"]
const NEW_NAMES := ["BARCA DE REMOS", "OLA DE ORILLA", "ROCA CON MUSGO"]

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
		button.text = ["C · Costa", "O · Oleaje", "E · Estudio"][i]
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
	tip.text = "1–3: piezas   ·   V: lateral / 3⁄4   ·   H: ocultar interfaz   ·   P: pausa   ·   Flechas: cambiar vista"
	tip.position = Vector2(28,152)
	tip.add_theme_font_size_override("font_size",14)
	ui.add_child(tip)

func asset(id: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	if not NEW_IDS.has(id):
		return super.asset(id,pos,factor)
	var model := (load("res://scenes/art_labs/assets_v08/"+id+".tscn") as PackedScene).instantiate() as Node3D
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
		0: _coast()
		1: _waves()
		2: _studio()

func _water(pos: Vector3, size: Vector2) -> void:
	var water := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	water.mesh = quad
	water.position = pos
	var material := ShaderMaterial.new()
	material.shader = WATER
	material.set_shader_parameter("deep_color",Color("435e59"))
	material.set_shader_parameter("surface_color",Color("607e70"))
	material.set_shader_parameter("reflection_color",Color("adb69a"))
	water.material_override = material
	stage.add_child(water)

func _coast() -> void:
	title.text = "BEE ALIEN   /   COSTA · TANDA 08"
	subtitle.text = "Barca humana con casco hueco y remos · Ola de espuma crema · Roca con musgo"
	environment.environment.background_color = Color("a0ac97")
	shape(Vector3(0,-.6,-9),Vector3(18,1.1,.3),Color("7d9688"),true)
	shape(Vector3(-7,-.4,-8),Vector3(7,1.3,.3),Color("879b82"),true)
	_water(Vector3(0,-3.3,-4),Vector2(36,5.0))
	shape(Vector3(-9,-3.8,-2),Vector3(4.8,1.15,.7),Color("ac9a70"),true)
	var boat := asset("coastal_rowboat",Vector3(.8,-1.75,0),2.35)
	boat.rotation.x = deg_to_rad(12)
	floaters.append(boat)
	asset("shore_rock",Vector3(-6.6,-2.8,1),1.6)
	asset("shore_wave_module",Vector3(6.6,-3.7,1),1.2)
	bee_anchor(Vector3(-4.0,.5,2))
	for i in 14:
		shape(Vector3(sin(i*12.7)*9.5,-2.9+fmod(i*1.23,5.7),-2),Vector3.ONE*.012,Color("ddd1a0"),true)

func _waves() -> void:
	title.text = "BEE ALIEN   /   ORILLA Y OLEAJE · TANDA 08"
	subtitle.text = "Módulos sólidos de decoración · Repetición a varias escalas · Sin emisión ni simulación física"
	environment.environment.background_color = Color("9aa58d")
	_water(Vector3(0,-.8,-7),Vector2(36,13))
	shape(Vector3(0,-4.6,-3),Vector3(18,1,.6),Color("a59971"))
	asset("shore_wave_module",Vector3(-4.0,-2.9,0),2.4)
	asset("shore_wave_module",Vector3(3.5,-2.9,-1),1.6)
	asset("shore_wave_module",Vector3(7.2,-.7,-3),.8)
	asset("shore_rock",Vector3(4.8,-3.6,1),1.55)
	asset("shore_rock",Vector3(-8.2,-3.6,1),1.1)
	bee_anchor(Vector3(.5,.8,2))

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO · TANDA 08"
	subtitle.text = "Barca, ola y roca · H: fichas limpias sin texto, interfaz ni entorno"
	environment.environment.background_color = Color("777970")
	camera.size = 10.8
	var boat := asset("coastal_rowboat",Vector3(-.6,.5,0),2.1)
	boat.rotation.x = deg_to_rad(23)
	asset("shore_wave_module",Vector3(-3.7,-3.9,0),1.7)
	asset("shore_rock",Vector3(3.6,-3.7,0),1.8)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var model := stage.get_child(0) as Node3D
	match id:
		"coastal_rowboat":
			model.scale = Vector3.ONE*1.35
			model.position = Vector3(-.2,-.7,0)
			if three_quarter:
				model.rotation.x = deg_to_rad(30)
		"shore_wave_module":
			model.scale = Vector3.ONE*1.7
			model.position.y = -1.45
		"shore_rock":
			model.scale = Vector3.ONE*2.2
			model.position.y = -1.45

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,false,three_quarter)
	ui.visible = true
	title.text = "BEE ALIEN   /   " + NEW_NAMES[NEW_IDS.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · H: ficha limpia · Pieza de entorno sin emisión"

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_C: show_page(0)
		KEY_O: show_page(1)
		KEY_E: show_page(2)
		KEY_1, KEY_2, KEY_3: inspect_asset(NEW_IDS[event.keycode-KEY_1],false)
		KEY_V:
			if not inspected_id.is_empty():
				inspect_asset(inspected_id,not angled)
		KEY_LEFT: show_page(page-1)
		KEY_RIGHT: show_page(page+1)
		KEY_H: ui.visible = not ui.visible
		KEY_P: animating = not animating

