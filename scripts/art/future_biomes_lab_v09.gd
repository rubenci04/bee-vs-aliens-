extends "res://scripts/art/future_biomes_lab.gd"
## Uses the same camera, lighting, Style C, cleanup and release helpers as V01.
const NEW_IDS := ["controlled_ant", "controlled_caterpillar", "amphibian_mount_study", "canonical_implant_kit"]
const NEW_NAMES := ["HORMIGA CONTROLADA", "ORUGA BLINDADA", "SAPO · ESTUDIO", "KIT DE IMPLANTES"]

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
		button.text = ["C · Hoja canónica", "S · Suelo", "E · Estudio"][i]
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
	var next := Button.new()
	next.text = "F · Aire / cañón"
	next.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/art_labs/future_biomes_v10.tscn"))
	row.add_child(next)
	var tip := Label.new()
	tip.text = "1–4: piezas   ·   V: lateral / 3⁄4   ·   H: ocultar interfaz   ·   P: pausa   ·   Flechas: cambiar vista"
	tip.position = Vector2(28,152)
	tip.add_theme_font_size_override("font_size",14)
	ui.add_child(tip)

func asset(id: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	if not NEW_IDS.has(id):
		return super.asset(id,pos,factor)
	var model := (load("res://scenes/art_labs/assets_v09/"+id+".tscn") as PackedScene).instantiate() as Node3D
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
		0: _canonical()
		1: _ground()
		2: _studio()

func mounted_host(id: String, variant: String, pos: Vector3, factor: float, mount_pos: Vector3, mount_scale: float) -> Node3D:
	# Read only V04 geometry; replace its old mount on this gallery instance only.
	var host := (load("res://scenes/art_labs/assets_v04/"+id+".tscn") as PackedScene).instantiate() as Node3D
	var old := host.find_child("AlienControlDevice",true,false)
	old.get_parent().remove_child(old)
	old.free()
	var kit := (load("res://assets/models/future_biomes_v09/canonical_implant_kit.glb") as PackedScene).instantiate()
	var mount := kit.find_child("Mount_"+variant,true,false) as Node3D
	mount.get_parent().remove_child(mount)
	mount.owner = null
	for descendant in mount.find_children("*","",true,false):
		descendant.owner = null
	mount.transform = Transform3D.IDENTITY
	mount.find_child("AlienControlDevice*",true,false).name = "AlienControlDevice"
	mount.position = mount_pos
	mount.scale = Vector3.ONE*mount_scale
	host.add_child(mount)
	kit.free()
	host.name = "CanonicalHost_"+variant
	stage.add_child(host)
	host.position = pos
	host.scale = Vector3.ONE*factor
	host.controlled = controlled
	return host

func _canonical() -> void:
	title.text = "BEE ALIEN   /   HOJA CANÓNICA · IMPLANTES"
	subtitle.text = "Insecto · Mamífero · Ave · Anfibio · Misma identidad, sujeciones adaptadas · L: liberar"
	environment.environment.background_color = Color("777970")
	camera.size = 10.8
	asset("controlled_ant",Vector3(-4.3,.1,0),2.0)
	mounted_host("controlled_mouse","mammal",Vector3(3.1,.75,0),2.0,Vector3(-.13,.27,0),.48)
	mounted_host("controlled_pigeon","bird",Vector3(-4.3,-3.1,0),2.0,Vector3(-.43,.43,.155),.40)
	asset("amphibian_mount_study",Vector3(3.5,-4.1,0),2.15)

func _ground() -> void:
	title.text = "BEE ALIEN   /   SUELO · HORMIGA Y ORUGA"
	subtitle.text = "Receptor dorsal común · Blindaje externo de la oruga · L: quitar toda la tecnología"
	environment.environment.background_color = Color("909679")
	shape(Vector3(0,-3.6,-5),Vector3(18,.8,.5),Color("796744"),true)
	shape(Vector3(0,-2.9,-4),Vector3(18,.15,.3),Color("5c6b3f"),true)
	for i in 5:
		shape(Vector3(-10+i*5,-.4,-8),Vector3(2.9,4.3,.4),Color("778467"),true)
	asset("controlled_ant",Vector3(-4.1,-2.7,0),2.8)
	asset("controlled_caterpillar",Vector3(3.3,-2.7,0),2.7)
	bee_anchor(Vector3(-.4,.5,2))

func _studio() -> void:
	title.text = "BEE ALIEN   /   ESTUDIO · TANDA 09"
	subtitle.text = "Hormiga, oruga blindada y estudio de sapo · 4: kit de monturas · H: ficha limpia"
	environment.environment.background_color = Color("777970")
	camera.size = 10.8
	asset("controlled_ant",Vector3(-4.0,.15,0),2.35)
	asset("controlled_caterpillar",Vector3(3.6,.15,0),2.5)
	asset("amphibian_mount_study",Vector3(-.3,-4.3,0),2.5)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var model := stage.get_child(0) as Node3D
	model.position.y = -.85
	if id == "amphibian_mount_study":
		model.position.y = -1.25
	elif id == "canonical_implant_kit":
		model.position.y = -.50

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,not controlled,three_quarter)
	ui.visible = true
	title.text = "BEE ALIEN   /   " + NEW_NAMES[NEW_IDS.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · L: quitar implante · H: ficha limpia"

func toggle_control() -> void:
	controlled = not controlled
	for child in stage.get_children():
		if child.has_method("release_control"):
			child.controlled = controlled

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_C: show_page(0)
		KEY_S: show_page(1)
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
		KEY_F: get_tree().change_scene_to_file("res://scenes/art_labs/future_biomes_v10.tscn")

