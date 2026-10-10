extends "res://scripts/art/future_biomes_lab.gd"
## Uses the same camera, lighting, Style C, cleanup and release helpers as V01.
const NEW_IDS := ["controlled_octopus", "controlled_gull", "coastal_buoy"]
const NEW_NAMES := ["PULPO", "GAVIOTA", "BOYA COSTERA"]

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
		button.text = ["C · Costa", "M · Submarino", "E · Estudio"][i]
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
	tip.text = "1–3: piezas   ·   V: lateral / 3⁄4   ·   H: ocultar interfaz   ·   P: pausa   ·   Flechas: cambiar vista"
	tip.position = Vector2(28,152)
	tip.add_theme_font_size_override("font_size",14)
	ui.add_child(tip)

func asset(id: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	if not NEW_IDS.has(id):
		return super.asset(id,pos,factor)
	var model := (load("res://scenes/art_labs/assets_v05/"+id+".tscn") as PackedScene).instantiate() as Node3D
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
		1: _underwater()
		2: _studio()

func _coast() -> void:
	title.text = "BEE ALIEN   /   COSTA · TANDA 05"
	subtitle.text = "Gaviota de alas largas · Boya humana · Bee como referencia de escala"
	environment.environment.background_color = Color("9ca58e")
	shape(Vector3(0,-.7,-8),Vector3(18,2,.2),Color("758c83"))
	shape(Vector3(0,-3.5,-6),Vector3(18,1.0,.3),Color("546e67"))
	for i in 5:
		shape(Vector3(-10+i*5,-1.4,-7),Vector3(3.5,.10,.15),Color("a5af98"),true)
	shape(Vector3(-8,-3.6,-3),Vector3(3.8,.7,.8),Color("8c8260"),true)
	var gull := asset("controlled_gull",Vector3(-2.3,-.50,1),3.5)
	floaters.append(gull)
	var buoy := asset("coastal_buoy",Vector3(4.8,-1.90,1),2.3)
	buoy.rotation.z = deg_to_rad(-8)
	floaters.append(buoy)
	bee_anchor(Vector3(-5.7,-1.4,2))
	for i in 14:
		shape(Vector3(sin(i*12.7)*9.5,-2.9+fmod(i*1.23,5.7),-2),Vector3.ONE*.013,Color("ddd1a0"),true)

func _underwater() -> void:
	title.text = "BEE ALIEN   /   SUBMARINO · TANDA 05"
	subtitle.text = "Pulpo de ocho brazos · Receptor externo sobre el manto · L: liberar sin ocultar anatomía"
	environment.environment.background_color = Color("3f5e60")
	var water := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(36,20)
	water.mesh = quad
	water.position = Vector3(0,0,-8)
	var material := ShaderMaterial.new()
	material.shader = WATER
	material.set_shader_parameter("deep_color",Color("304d53"))
	material.set_shader_parameter("surface_color",Color("526e68"))
	material.set_shader_parameter("reflection_color",Color("8c9c86"))
	water.material_override = material
	stage.add_child(water)
	shape(Vector3(0,-4.5,-4),Vector3(18,.65,.8),Color("867b56"),true)
	for i in 6:
		shape(Vector3(-10+i*4,-3.7,-3),Vector3(1.25,.65,.5),Color("696e52"),true)
	for i in 7:
		var stem := shape(Vector3(-8+i*.5,-2.8,-3),Vector3(.11,1.1,.08),Color("63774e"),true)
		stem.rotation.z = deg_to_rad(-14+i*5)
	var octopus := asset("controlled_octopus",Vector3(0,.2,1),2.7)
	floaters.append(octopus)
	asset("coastal_buoy",Vector3(6.2,1.4,-1),1.5)
	for i in 20:
		shape(Vector3(sin(i*8.7)*9.5,-3.5+fmod(i*1.71,6.5),-2),Vector3.ONE*.02,Color("b5b89a"),true)

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO · TANDA 05"
	subtitle.text = "Pulpo, gaviota y boya costera · H: ficha limpia sin texto, interfaz ni entorno"
	environment.environment.background_color = Color("777970")
	camera.size = 10.8
	asset("controlled_octopus",Vector3(-3.5,.1,0),2.5)
	asset("controlled_gull",Vector3(3.6,.6,0),2.55)
	var buoy := asset("coastal_buoy",Vector3(4.0,-2.3,0),1.55)
	buoy.rotation.z = deg_to_rad(-8)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var model := stage.get_child(0) as Node3D
	match id:
		"controlled_octopus":
			model.scale = Vector3.ONE*1.6
			model.position.y = .30
		"controlled_gull":
			model.scale = Vector3.ONE*2.2
			model.position = Vector3(-.35,-.55,0)
		"coastal_buoy":
			model.scale = Vector3.ONE*2.0
			model.position.y = .65

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,not controlled,three_quarter)
	ui.visible = true
	title.text = "BEE ALIEN   /   " + NEW_NAMES[NEW_IDS.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · L: quitar receptor · H: ficha limpia"
	if id == "coastal_buoy":
		subtitle.text = "Objeto humano sin control ni emisión · V: lateral / 3⁄4 · H: ficha limpia"

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_C: show_page(0)
		KEY_M: show_page(1)
		KEY_E: show_page(2)
		KEY_1, KEY_2, KEY_3: inspect_asset(NEW_IDS[event.keycode-KEY_1],false)
		KEY_V:
			if not inspected_id.is_empty():
				inspect_asset(inspected_id,not angled)
		KEY_LEFT: show_page(page-1)
		KEY_RIGHT: show_page(page+1)
		KEY_L: toggle_control()
		KEY_H: ui.visible = not ui.visible
		KEY_P: animating = not animating

