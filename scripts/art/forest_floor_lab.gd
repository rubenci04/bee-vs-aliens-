extends "res://scripts/art/asset_catalog_lab.gd"

func show_page(_index: int) -> void:
	_clear()
	creature_mode = false
	inspected_id = ""
	camera.size = 10.8
	ui.visible = true
	environment.environment.background_color = Color("777970")
	title.text = catalog_title
	subtitle.text = "Estudio neutro · G: composición jardín · 1–3: inspeccionar · H: ficha limpia"
	for i in asset_ids.size():
		asset(asset_ids[i],Vector3((i-1)*5.5,-0.8 if i==0 else -1.7,0),factors[i])

func _make_ui() -> void:
	super._make_ui()
	var garden := Button.new()
	garden.text = "G · Composición jardín"
	garden.position = Vector2(690,105)
	garden.pressed.connect(show_garden)
	ui.add_child(garden)

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	# Catalog rows have individual offsets; studio centers each whole silhouette.
	stage.get_child(0).position.y = -1.0 if id=="hollow_fallen_log" else -1.7

func show_garden() -> void:
	_clear()
	creature_mode = false
	inspected_id = ""
	camera.size = 11.5
	ui.visible = true
	title.text = "BEE ALIEN / SUELO DEL JARDÍN Y BOSQUE"
	subtitle.text = "G: composición · E: estudio · 1–3: piezas · H: ocultar interfaz · Esc: colección"
	environment.environment.background_color = Color("9da981")
	shape(Vector3(0,-2.7,-7),Vector3(22,4.2,1),Color("8c9b72"),true)
	shape(Vector3(-7,-3.0,-5),Vector3(12,3.0,1),Color("6f8557"),true)
	shape(Vector3(7,-3.1,-3),Vector3(11,2.5,1),Color("5b7248"),true)
	shape(Vector3(0,-4.9,-0.5),Vector3(20,2,1),Color("77633f"))
	shape(Vector3(0,-3.0,-0.5),Vector3(20,0.16,1),Color("65733a"))
	asset("hollow_fallen_log",Vector3(-3,-2.88,0.2),2.65)
	asset("forest_fern",Vector3(4.5,-2.88,0),3.3)
	asset("garden_bellflower",Vector3(0.7,-2.88,-0.1),3.0)
	var distant_fern := asset("forest_fern",Vector3(-7.8,-2.88,-2),2.0)
	distant_fern.rotation.y = PI
	var bee := (load("res://assets/models/shared/bee/bee_mid_poly.glb") as PackedScene).instantiate() as Node3D
	stage.add_child(bee)
	bee.name = "BeeScaleReference"
	bee.position = Vector3(-0.9,0.1,1)
	bee.scale = Vector3.ONE*0.7
	bee.rotation.y = -PI*0.5
	BeeToonStyle.apply(bee,true,BeeToonStyle.OUTLINE_BEE)
	for i in 12:
		shape(Vector3(sin(i*6.31)*8,-1.5+fmod(i*1.77,4.4),-1),Vector3.ONE*0.018,Color("d2bc70"),true)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_G:
		show_garden()
	super._unhandled_key_input(event)
