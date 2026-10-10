extends "res://scripts/art/future_biomes_lab.gd"
## Uses the same camera, lighting, Style C, cleanup and release helpers as V01.
const NEW_IDS := ["sky_cloud", "sky_sun", "sky_crescent_moon", "sky_star_cluster"]
const NEW_NAMES := ["NUBE", "SOL", "LUNA CRECIENTE", "ESTRELLAS"]
var drifting_clouds: Array[Node3D] = []

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
		button.text = ["D · Día", "N · Noche", "E · Estudio"][i]
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
	tip.text = "1–4: piezas   ·   V: lateral / 3⁄4   ·   H: ocultar interfaz   ·   P: pausa   ·   Flechas: cambiar vista"
	tip.position = Vector2(28,152)
	tip.add_theme_font_size_override("font_size",14)
	ui.add_child(tip)

func asset(id: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	if not NEW_IDS.has(id):
		return super.asset(id,pos,factor)
	var model := (load("res://scenes/art_labs/assets_v07/"+id+".tscn") as PackedScene).instantiate() as Node3D
	model.name = id
	stage.add_child(model)
	model.position = pos
	model.scale = Vector3.ONE*factor
	return model

func _lighting(night: bool) -> void:
	environment.environment.ambient_light_color = Color("d4ddcc") if night else Color("fff0d4")
	environment.environment.ambient_light_energy = .45 if night else .55
	var sun := find_children("*","DirectionalLight3D",false,false)[0] as DirectionalLight3D
	sun.light_color = Color("d7dfcf") if night else Color("fff2d8")
	sun.light_energy = .85 if night else 1.0

func show_page(index: int) -> void:
	drifting_clouds.clear()
	_clear()
	page = posmod(index,3)
	creature_mode = false
	inspected_id = ""
	camera.size = 11.5
	camera.position = Vector3(0,0,20)
	camera.rotation = Vector3.ZERO
	ui.visible = true
	_lighting(page==1)
	match page:
		0: _day()
		1: _night()
		2: _studio()

func _landscape(night: bool) -> void:
	var far_color := Color("414f43") if night else Color("7c8c66")
	var near_color := Color("293d32") if night else Color("566946")
	for i in 5:
		shape(Vector3(-11+i*6,-4.7,-8),Vector3(4.5,1.4,.5),far_color,true)
	shape(Vector3(0,-5.1,-3),Vector3(18,.7,.6),near_color,true)
	var tree := (load("res://scenes/art_labs/assets_v06/garden_sapling.tscn") as PackedScene).instantiate() as Node3D
	stage.add_child(tree)
	tree.position = Vector3(-7.0,-4.45,0)
	tree.scale = Vector3.ONE*1.25
	bee_anchor(Vector3(-3.7,-.7,2))

func _day() -> void:
	title.text = "BEE ALIEN   /   CIELO DE DÍA · TANDA 07"
	subtitle.text = "Nube continua de volumen suave · Sol cálido · Contorno fino para planos de fondo"
	environment.environment.background_color = Color("9bad9d")
	asset("sky_sun",Vector3(4.6,1.0,-7),2.1)
	var cloud := asset("sky_cloud",Vector3(-2.3,.1,-5),2.8)
	drifting_clouds.append(cloud)
	var small := asset("sky_cloud",Vector3(6,-1.2,-6),1.5)
	drifting_clouds.append(small)
	_landscape(false)

func _night() -> void:
	title.text = "BEE ALIEN   /   CIELO DE NOCHE · TANDA 07"
	subtitle.text = "Creciente sólido · Estrellas discretas · Nube teñida por instancia, sin energía alienígena"
	environment.environment.background_color = Color("293a40")
	asset("sky_crescent_moon",Vector3(4.8,1.0,-7),2.4)
	asset("sky_star_cluster",Vector3(-4.4,1.15,-7),2.4)
	asset("sky_star_cluster",Vector3(.3,-1.25,-7),1.6)
	asset("sky_star_cluster",Vector3(7.8,-2.0,-7),1.0)
	var cloud := asset("sky_cloud",Vector3(-.8,.2,-5),2.2)
	cloud.tint = Color(.43,.49,.48)
	drifting_clouds.append(cloud)
	_landscape(true)

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO · TANDA 07"
	subtitle.text = "Cuatro elementos de cielo · H: ficha limpia · Las escalas son de revisión artística"
	environment.environment.background_color = Color("777970")
	camera.size = 10.8
	asset("sky_cloud",Vector3(-3.8,1.0,0),2.3)
	asset("sky_sun",Vector3(3.8,1.25,0),1.8)
	asset("sky_crescent_moon",Vector3(-3.6,-2.5,0),2.0)
	asset("sky_star_cluster",Vector3(3.6,-2.65,0),2.3)

func show_single(id: String, _liberated := false, three_quarter := false) -> void:
	drifting_clouds.clear()
	_clear()
	_lighting(false)
	creature_mode = true
	inspected_id = id
	angled = three_quarter
	ui.visible = false
	environment.environment.background_color = Color("777970")
	camera.size = 4.7
	camera.position = Vector3(0,0,20)
	camera.rotation = Vector3.ZERO
	var model := asset(id,Vector3.ZERO,2.3)
	match id:
		"sky_cloud": model.position.y = -.5
		"sky_sun", "sky_crescent_moon": model.scale = Vector3.ONE*2.6
		"sky_star_cluster": model.scale = Vector3.ONE*2.9
	if three_quarter:
		model.rotation = Vector3(deg_to_rad(10),deg_to_rad(-30),0)

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,false,three_quarter)
	ui.visible = true
	title.text = "BEE ALIEN   /   " + NEW_NAMES[NEW_IDS.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · H: ficha limpia · Sin luz ni ciclo horario incorporado"

func _process(delta: float) -> void:
	if not animating or creature_mode:
		return
	elapsed += delta
	for i in drifting_clouds.size():
		var node := drifting_clouds[i]
		if not node.has_meta("rest_x"):
			node.set_meta("rest_x",node.position.x)
		node.position.x = float(node.get_meta("rest_x"))+sin(elapsed*.16+i)*.35

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_D: show_page(0)
		KEY_N: show_page(1)
		KEY_E: show_page(2)
		KEY_1, KEY_2, KEY_3, KEY_4: inspect_asset(NEW_IDS[event.keycode-KEY_1],false)
		KEY_V:
			if not inspected_id.is_empty():
				inspect_asset(inspected_id,not angled)
		KEY_LEFT: show_page(page-1)
		KEY_RIGHT: show_page(page+1)
		KEY_H: ui.visible = not ui.visible
		KEY_P: animating = not animating

