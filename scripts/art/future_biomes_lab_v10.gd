extends "res://scripts/art/future_biomes_lab.gd"
## Uses the same camera, lighting, Style C, cleanup and release helpers as V01.
const NEW_IDS := ["controlled_dragonfly", "controlled_bomb_moth", "controlled_mushroom_cannon", "moth_stationary_bomb"]
const NEW_NAMES := ["LIBÉLULA ALIEN", "POLILLA BOMBA", "HONGO CAÑÓN", "MINA DE POLILLA"]
var moving_actor: Node3D
var mines: Array[Node3D] = []
var drop_time := 0.0

func _clear() -> void:
	moving_actor = null
	mines.clear()
	drop_time = 0.0
	super._clear()

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
	for i in 4:
		var button := Button.new()
		button.text = ["A · Vuelo", "M · Minas", "T · Hongo", "E · Estudio"][i]
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
	var previous := Button.new()
	previous.text = "C · Implantes / suelo"
	previous.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/art_labs/future_biomes_v09.tscn"))
	row.add_child(previous)
	var tip := Label.new()
	tip.text = "1–4: piezas   ·   V: lateral / 3⁄4   ·   H: ocultar interfaz   ·   P: pausa   ·   Flechas: cambiar vista"
	tip.position = Vector2(28,152)
	tip.add_theme_font_size_override("font_size",14)
	ui.add_child(tip)

func asset(id: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	if not NEW_IDS.has(id):
		return super.asset(id,pos,factor)
	var model := (load("res://scenes/art_labs/assets_v10/"+id+".tscn") as PackedScene).instantiate() as Node3D
	model.name = id
	stage.add_child(model)
	model.position = pos
	model.scale = Vector3.ONE*factor
	model.controlled = controlled
	return model

func show_page(index: int) -> void:
	_clear()
	page = posmod(index,4)
	creature_mode = false
	inspected_id = ""
	camera.size = 11.5
	camera.position = Vector3(0,0,20)
	camera.rotation = Vector3.ZERO
	ui.visible = true
	match page:
		0: _air()
		1: _mines()
		2: _turret()
		3: _studio()

func _garden_background() -> void:
	environment.environment.background_color = Color("929b7c")
	for i in 5:
		shape(Vector3(-10+i*5,-.6,-8),Vector3(3.0,4.0,.4),Color("7c8b6c"),true)
	shape(Vector3(0,-4.4,-5),Vector3(18,.9,.5),Color("7d6d49"),true)
	shape(Vector3(0,-3.7,-4),Vector3(18,.16,.4),Color("617242"),true)

func _air() -> void:
	title.text = "BEE ALIEN   /   LIBÉLULA · VUELO ONDULADO"
	subtitle.text = "Cuatro alas, abdomen largo e implante canónico · Demostración visual sin daño ni colisiones"
	_garden_background()
	moving_actor = asset("controlled_dragonfly",Vector3(0,.3,0),2.25)
	bee_anchor(Vector3(-5.0,-.4,2))

func _spawn_mine(pos: Vector3) -> Node3D:
	if mines.size() >= 5:
		var oldest := mines.pop_front() as Node3D
		oldest.get_parent().remove_child(oldest)
		oldest.queue_free()
	var mine := asset("moth_stationary_bomb",pos,1.7)
	mine.set_meta("born",elapsed)
	mines.append(mine)
	return mine

func _mines() -> void:
	title.text = "BEE ALIEN   /   POLILLA BOMBA · MINAS SUSPENDIDAS"
	subtitle.text = "La polilla se desplaza; las minas quedan inmóviles · P: pausar · L: liberar · Demo sin explosiones"
	_garden_background()
	moving_actor = asset("controlled_bomb_moth",Vector3(1,.2,0),2.45)
	for pos in [Vector3(-5,-1.7,1),Vector3(-1,-1.2,1),Vector3(3.5,-1.9,1)]:
		_spawn_mine(pos)
	bee_anchor(Vector3(-6.5,.5,2))

func _turret() -> void:
	title.text = "BEE ALIEN   /   HONGO CAÑÓN · SUELO"
	subtitle.text = "Hongo natural + artillería externa cian · L: retirar cañón, montura y receptor"
	_garden_background()
	asset("controlled_mushroom_cannon",Vector3(3.0,-3.5,0),3.0)
	asset("controlled_mushroom_cannon",Vector3(-5.0,-3.5,-2),1.3)
	bee_anchor(Vector3(-2.8,.25,2))

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO · TANDA 10"
	subtitle.text = "Libélula, polilla, hongo cañón y mina separada · H: ficha limpia sin entorno ni texto"
	environment.environment.background_color = Color("777970")
	camera.size = 10.8
	asset("controlled_dragonfly",Vector3(-4.0,.3,0),2.0)
	asset("controlled_bomb_moth",Vector3(3.8,.1,0),2.15)
	asset("controlled_mushroom_cannon",Vector3(-3.6,-4.3,0),1.65)
	asset("moth_stationary_bomb",Vector3(3.8,-2.8,0),3.3)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var model := stage.get_child(0) as Node3D
	match id:
		"controlled_dragonfly":
			model.position = Vector3(-.55,-.35,0)
			model.scale = Vector3.ONE*2.0
		"controlled_bomb_moth":
			model.position.y = -.50
			model.scale = Vector3.ONE*2.1
		"controlled_mushroom_cannon":
			model.position.y = -1.60
			model.scale = Vector3.ONE*2.0
		"moth_stationary_bomb":
			model.scale = Vector3.ONE*6.5

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,not controlled,three_quarter)
	ui.visible = true
	title.text = "BEE ALIEN   /   " + NEW_NAMES[NEW_IDS.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · L: quitar tecnología · H: ficha limpia"

func toggle_control() -> void:
	controlled = not controlled
	for child in stage.get_children():
		if child.has_method("release_control"):
			child.controlled = controlled

func advance_demo(delta: float) -> void:
	# Presentation only: no projectiles, damage areas, physics or boss mine script.
	if creature_mode:
		return
	elapsed += delta
	if is_instance_valid(moving_actor):
		if page == 0:
			moving_actor.position = Vector3(11.0-fposmod(elapsed*2.4+11.0,22.0),.3+sin(elapsed*4.0)*.55,0)
		elif page == 1:
			moving_actor.position = Vector3(11.0-fposmod(elapsed*1.8+10.0,22.0),.2+sin(elapsed*1.7)*.12,0)
			drop_time += delta
			if controlled and drop_time >= 1.4:
				drop_time = 0.0
				var anchor := moving_actor.find_child("BombDropAnchor",true,false) as Node3D
				_spawn_mine(anchor.global_position)
	for mine in mines.duplicate():
		if elapsed-float(mine.get_meta("born")) > 5.0:
			mines.erase(mine)
			mine.get_parent().remove_child(mine)
			mine.queue_free()

func _process(delta: float) -> void:
	if animating:
		advance_demo(delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_A: show_page(0)
		KEY_M: show_page(1)
		KEY_T: show_page(2)
		KEY_E: show_page(3)
		KEY_1, KEY_2, KEY_3, KEY_4: inspect_asset(NEW_IDS[event.keycode-KEY_1],false)
		KEY_V:
			if not inspected_id.is_empty():
				inspect_asset(inspected_id,not angled)
		KEY_LEFT: show_page(page-1)
		KEY_RIGHT: show_page(page+1)
		KEY_L: toggle_control()
		KEY_H: ui.visible = not ui.visible
		KEY_P: animating = not animating
		KEY_C: get_tree().change_scene_to_file("res://scenes/art_labs/future_biomes_v09.tscn")

