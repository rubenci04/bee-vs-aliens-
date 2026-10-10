extends "res://scripts/art/future_biomes_lab.gd"
## Uses the same camera, lighting, Style C, cleanup and release helpers as V01.
const NEW_IDS := ["controlled_firefly", "controlled_flying_ladybird", "controlled_owl", "controlled_manta_ray"]
const NEW_NAMES := ["LUCIÉRNAGA", "MARIQUITA EN VUELO", "BÚHO", "MANTARRAYA"]

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
		button.text = ["A · Aire", "M · Mar", "E · Estudio"][i]
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
	var model := (load("res://scenes/art_labs/assets_v03/"+id+".tscn") as PackedScene).instantiate() as Node3D
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
		0: _air()
		1: _marine()
		2: _studio()

func _air() -> void:
	title.text = "BEE ALIEN   /   AIRE · TANDA 03"
	subtitle.text = "Luciérnaga y mariquita voladoras · Búho gigante · Luz natural amarilla"
	environment.environment.background_color = Color("45554a")
	shape(Vector3(7,3,-8),Vector3(2.3,2.3,.6),Color("9c9d7b"),true)
	for i in 5:
		shape(Vector3(-10+i*5,-1,-6),Vector3(.7,8,.6),Color("3c4b3b"),true)
	for i in 10:
		shape(Vector3(-11+i*2.7,-4.7+sin(i)*.3,-3),Vector3(2.3,.8,.7),Color("2d4231"),true)
	var firefly := asset("controlled_firefly",Vector3(-5,1.0,1),2.0)
	floaters.append(firefly)
	var ladybird := asset("controlled_flying_ladybird",Vector3(-1.1,-1.4,1),2.0)
	floaters.append(ladybird)
	var owl := asset("controlled_owl",Vector3(4,-.7,.7),2.7)
	floaters.append(owl)
	bee_anchor(Vector3(-5.8,-1.6,2))
	for i in 20:
		shape(Vector3(sin(i*15.7)*9.8,-3.5+fmod(i*2.13,7),-2),Vector3.ONE*.016,Color("bbb575"),true)

func _marine() -> void:
	title.text = "BEE ALIEN   /   MAR · TANDA 03"
	subtitle.text = "Mantarraya controlada · Aletas naturales y cola larga · L: liberar"
	environment.environment.background_color = Color("354e57")
	var water := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(36,20)
	water.mesh = quad
	water.position = Vector3(0,0,-7)
	var material := ShaderMaterial.new()
	material.shader = WATER
	material.set_shader_parameter("deep_color",Color("243c47"))
	material.set_shader_parameter("surface_color",Color("456566"))
	material.set_shader_parameter("reflection_color",Color("7b8880"))
	water.material_override = material
	stage.add_child(water)
	shape(Vector3(0,-4.1,-4),Vector3(19,.55,.8),Color("66634d"),true)
	for i in 7:
		shape(Vector3(-11+i*3.7,-3.6,-3),Vector3(1.0,.42,.55),Color("555847"),true)
	var ray := asset("controlled_manta_ray",Vector3(-.5,-.5,1),2.6)
	ray.rotation.x = deg_to_rad(16)
	floaters.append(ray)
	var distant := asset("controlled_manta_ray",Vector3(-5.8,1.45,-2),1.1)
	distant.rotation = Vector3(deg_to_rad(15),deg_to_rad(-30),0)
	floaters.append(distant)
	for i in 20:
		shape(Vector3(sin(i*9.7)*10,-3.3+fmod(i*1.83,6.5),-2),Vector3.ONE*.02,Color("9eab9b"),true)

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO · TANDA 03"
	subtitle.text = "Cuatro criaturas liberables · H: ficha limpia sin texto ni interfaz"
	environment.environment.background_color = Color("777970")
	camera.size = 10.8
	asset("controlled_firefly",Vector3(-3.8,1.4,0),3.0)
	asset("controlled_flying_ladybird",Vector3(3.6,1.4,0),2.8)
	asset("controlled_owl",Vector3(-3.6,-2.5,0),2.2)
	asset("controlled_manta_ray",Vector3(1.9,-2.6,0),1.9)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var model := stage.get_child(0) as Node3D
	if id == "controlled_firefly" or id == "controlled_flying_ladybird":
		model.scale = Vector3.ONE*2.8
	elif id == "controlled_owl":
		model.scale = Vector3.ONE*2.1
		model.position.y = -.65
	elif id == "controlled_manta_ray":
		model.scale = Vector3.ONE*1.9
		model.position.x = -.75
		if three_quarter:
			model.rotation.x += deg_to_rad(20)

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,not controlled,three_quarter)
	ui.visible = true
	title.text = "BEE ALIEN   /   " + NEW_NAMES[NEW_IDS.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · L: quitar el receptor · H: ficha limpia"

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_A: show_page(0)
		KEY_M: show_page(1)
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


