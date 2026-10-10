extends Node3D
## Small isolated art gallery. Does not load gameplay or change the main scene.
const ASSET_DIR := "res://scenes/art_labs/assets/"
const HEALTH_BAR := preload("res://scenes/ui/future_health_bar.tscn")
const WATER := preload("res://assets/style/future_lake_water.gdshader")
const IDS := ["controlled_mosquito", "controlled_perch", "orbital_skimmer", "lotus_lily_pad", "cattails_cluster", "warm_asteroid"]
var stage: Node3D
var camera: Camera3D
var environment: WorldEnvironment
var ui: CanvasLayer
var title: Label
var subtitle: Label
var page := 0
var controlled := true
var animating := true
var elapsed := 0.0
var floaters: Array[Node3D] = []
var creature_mode := false
var inspected_id := ""
var angled := false

func _ready() -> void:
	stage = Node3D.new()
	stage.name = "Stage"
	add_child(stage)
	environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff0d4")
	environment.environment.ambient_light_energy = 0.55
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, -35, -12)
	sun.light_color = Color("fff2d8")
	sun.light_energy = 1.0
	add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0, 20)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 11.5
	camera.current = true
	add_child(camera)
	_make_ui()
	show_page(0)

func _make_ui() -> void:
	ui = CanvasLayer.new()
	ui.name = "GalleryUI"
	add_child(ui)
	var backdrop := Panel.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	backdrop.offset_bottom = 186
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08,0.11,0.13,0.78)
	backdrop.add_theme_stylebox_override("panel",bg)
	ui.add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	ui.add_child(margin)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("faf0d5"))
	stack.add_child(title)
	subtitle = Label.new()
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("e1ddc5"))
	stack.add_child(subtitle)
	var bar := HBoxContainer.new()
	bar.position = Vector2(28, 108)
	bar.add_theme_constant_override("separation", 8)
	ui.add_child(bar)
	for i in 3:
		var button := Button.new()
		button.text = ["1 · Lago", "2 · Espacio", "3 · Estudio"][i]
		button.pressed.connect(show_page.bind(i))
		bar.add_child(button)
	var liberate := Button.new()
	liberate.text = "L · Poner / quitar control"
	liberate.pressed.connect(toggle_control)
	bar.add_child(liberate)
	var picker := OptionButton.new()
	picker.add_item("Ver una pieza…")
	for asset_title in ["Mosquito", "Perca", "Dron orbital", "Nenúfar", "Totoras", "Asteroide"]:
		picker.add_item(asset_title)
	picker.item_selected.connect(func(index: int):
		if index > 0:
			inspect_asset(IDS[index-1], false)
	)
	bar.add_child(picker)
	var tip := Label.new()
	tip.text = "4–9: piezas   ·   V: lateral / 3⁄4   ·   H: ocultar interfaz   ·   P: pausa   ·   Flechas: cambiar vista"
	tip.position = Vector2(28, 152)
	tip.add_theme_font_size_override("font_size", 14)
	ui.add_child(tip)
	var hud_panel := PanelContainer.new()
	hud_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hud_panel.offset_left = 18
	hud_panel.offset_top = -184
	hud_panel.offset_right = 350
	hud_panel.offset_bottom = -18
	hud_panel.add_theme_stylebox_override("panel",bg)
	ui.add_child(hud_panel)
	var hud_margin := MarginContainer.new()
	for key in ["margin_left","margin_top","margin_right","margin_bottom"]:
		hud_margin.add_theme_constant_override(key,10)
	hud_panel.add_child(hud_margin)
	var hud := VBoxContainer.new()
	hud_margin.add_child(hud)
	for is_alien in [false, true]:
		var label := Label.new()
		label.text = "BEE / miel" if not is_alien else "DISPOSITIVO / control"
		label.add_theme_font_size_override("font_size", 12)
		hud.add_child(label)
		var health := HEALTH_BAR.instantiate()
		health.alien_device = is_alien
		health.ratio = 0.76 if not is_alien else 0.48
		hud.add_child(health)

func _clear() -> void:
	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()
	floaters.clear()
	elapsed = 0.0

func asset(id: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	var model := (load(ASSET_DIR + id + ".tscn") as PackedScene).instantiate() as Node3D
	model.name = id
	stage.add_child(model)
	model.position = pos
	model.scale = Vector3.ONE * factor
	model.controlled = controlled
	return model

func matte(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func shape(pos: Vector3, dimensions: Vector3, color: Color, round_shape := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	if round_shape:
		var sphere := SphereMesh.new()
		sphere.radius = 1
		sphere.height = 2
		node.mesh = sphere
	else:
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * 2
		node.mesh = cube
	node.material_override = matte(color)
	stage.add_child(node)
	node.position = pos
	node.scale = dimensions
	return node

func bee_anchor(pos: Vector3) -> void:
	# Original project visual, without loading player physics, audio or gameplay.
	var bee := (load("res://assets/models/bee_prototype/bee_alien_visual.glb") as PackedScene).instantiate() as Node3D
	bee.name = "BeeScaleReference"
	stage.add_child(bee)
	bee.position = pos
	bee.rotation.y = -PI * .5
	bee.scale = Vector3.ONE * .8
	BeeToonStyle.apply(bee,true,BeeToonStyle.OUTLINE_BEE)

func show_page(index: int) -> void:
	_clear()
	page = posmod(index, 3)
	creature_mode = false
	inspected_id = ""
	camera.size = 11.5
	camera.position = Vector3(0, 0, 20)
	camera.rotation = Vector3.ZERO
	ui.visible = true
	match page:
		0: _lake()
		1: _space()
		2: _studio()

func _lake() -> void:
	title.text = "BEE ALIEN   /   EL ESTANQUE"
	subtitle.text = "POC de arte 01 · Mosquito + perca · Nenúfar + totoras"
	environment.environment.background_color = Color("899b78")
	shape(Vector3(0,-3,-7),Vector3(22,4,1),Color("78896a"),true)
	shape(Vector3(5,-2.1,-5),Vector3(10,2.6,1),Color("647a55"),true)
	shape(Vector3(-8,-2,-4),Vector3(9,2.3,1),Color("526b45"),true)
	var water := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(38,6)
	water.mesh = quad
	water.position = Vector3(0,-4.5,-.6)
	var wm := ShaderMaterial.new()
	wm.shader = WATER
	water.material_override = wm
	stage.add_child(water)
	asset("cattails_cluster",Vector3(-7.8,-2.5,0),2.6)
	asset("cattails_cluster",Vector3(7.6,-2.5,-2),1.8)
	var pad := asset("lotus_lily_pad",Vector3(-2.5,-1.4,.1),2.6)
	pad.rotation.x = deg_to_rad(23)
	var small_pad := asset("lotus_lily_pad",Vector3(5,-1.55,-1),1.5)
	small_pad.rotation.x = deg_to_rad(19)
	var mosquito := asset("controlled_mosquito",Vector3(.1,1.5,1),1.75)
	floaters.append(mosquito)
	bee_anchor(Vector3(-3.1,.5,2))
	var fish := asset("controlled_perch",Vector3(3.2,-3.0,1),1.9)
	floaters.append(fish)
	# Dust/pollen is warm and non-emissive. No neon nature.
	for i in 20:
		var x := sin(i*7.17)*8.8
		var y := -.4 + fmod(i*1.31,4.8)
		shape(Vector3(x,y,-2),Vector3.ONE*.015,Color("c6bb77"),true)

func _space() -> void:
	title.text = "BEE ALIEN   /   ÓRBITA"
	subtitle.text = "POC de arte 01 · Interceptor grafito · Roca cálida sin emisión"
	environment.environment.background_color = Color("222c3b")
	shape(Vector3(6.8,2.6,-8),Vector3(3.6,3.6,.8),Color("645d54"),true)
	shape(Vector3(7.0,2.5,-7),Vector3(3.25,3.25,.8),Color("77705e"),true)
	for i in 56:
		shape(Vector3(sin(i*19.9)*11,cos(i*7.13)*5.6,-5),Vector3.ONE*(.014+fmod(i*.013,.018)),Color("aea897"),true)
	asset("warm_asteroid",Vector3(-5,-2,0),1.75)
	var rock := asset("warm_asteroid",Vector3(5,-2.4,-2),1.2)
	rock.rotation.z = .65
	var drone := asset("orbital_skimmer",Vector3(.4,.5,1),2.4)
	floaters.append(drone)
	bee_anchor(Vector3(-3.8,.6,2))
	var escort := asset("orbital_skimmer",Vector3(5,1,-1),1.1)
	floaters.append(escort)

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO"
	subtitle.text = "Silueta lateral · L: fauna liberada · H: ficha limpia sin texto ni UI"
	environment.environment.background_color = Color("777970")
	asset("controlled_mosquito",Vector3(-5,0,0),2.0)
	asset("controlled_perch",Vector3(0,0,0),1.75)
	asset("orbital_skimmer",Vector3(5,0,0),2.0)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	_clear()
	creature_mode = true
	inspected_id = id
	angled = three_quarter
	ui.visible = false
	environment.environment.background_color = Color("777970")
	camera.size = 4.7 if id != "cattails_cluster" else 5.0
	camera.position = Vector3(0,0,20)
	camera.rotation = Vector3.ZERO
	var model := asset(id,Vector3.ZERO,1.6)
	model.controlled = not liberated
	if id == "cattails_cluster":
		model.position.y = -2
	elif id == "lotus_lily_pad":
		model.rotation.x = deg_to_rad(45)
	if three_quarter:
		model.rotation.y = deg_to_rad(-30)
		model.rotation.x += deg_to_rad(10)

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id, not controlled, three_quarter)
	ui.visible = true
	var index := IDS.find(id)
	title.text = "BEE ALIEN   /   " + ["MOSQUITO", "PERCA", "DRON ORBITAL", "NENÚFAR", "TOTORAS", "ASTEROIDE"][index]
	subtitle.text = "V: lateral / 3⁄4 · L: quitar control · H: ficha limpia"

func toggle_control() -> void:
	controlled = not controlled
	for child in stage.get_children():
		if child.get_script() == preload("res://scripts/art/future_asset_visual.gd"):
			child.controlled = controlled

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: show_page(0)
		KEY_2: show_page(1)
		KEY_3: show_page(2)
		KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			inspect_asset(IDS[event.keycode-KEY_4],false)
		KEY_V:
			if not inspected_id.is_empty():
				inspect_asset(inspected_id,not angled)
		KEY_LEFT: show_page(page-1)
		KEY_RIGHT: show_page(page+1)
		KEY_L: toggle_control()
		KEY_H: ui.visible = not ui.visible
		KEY_P: animating = not animating

func _process(delta: float) -> void:
	if not animating or creature_mode:
		return
	elapsed += delta
	for i in floaters.size():
		var node := floaters[i]
		if not node.has_meta("rest_y"):
			node.set_meta("rest_y",node.position.y)
		node.position.y = float(node.get_meta("rest_y")) + sin(elapsed*1.6+i)*.08
