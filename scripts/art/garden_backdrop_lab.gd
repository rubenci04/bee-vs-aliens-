extends "res://scripts/art/asset_catalog_lab.gd"
func _make_ui() -> void:
	super._make_ui()
	var preview := Button.new()
	preview.position = Vector2(1030,105)
	preview.text = "G · Escala en jardín"
	preview.pressed.connect(show_garden)
	ui.add_child(preview)
func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	if id=="garden_hose":
		stage.get_child(0).rotation.x = deg_to_rad(58)
		stage.get_child(0).position.x = .55
func show_page(index: int) -> void:
	super.show_page(index)
	stage.get_child(0).rotation.x = deg_to_rad(58)
func show_garden() -> void:
	_clear()
	inspected_id = ""
	camera.size = 12
	ui.visible = true
	title.text = "BEE ALIEN / JARDÍN A ESCALA HUMANA"
	subtitle.text = "G: composición · E: estudio · 1–4: piezas · H: vista limpia · Esc: colección"
	environment.environment.background_color = Color("a6b18a")
	shape(Vector3(0,-3.8,-7),Vector3(32,5,1),Color("829472"),true)
	shape(Vector3(0,-4.8,-3),Vector3(28,2,1),Color("617b47"),false)
	asset("garden_distant_house",Vector3(5,-2.0,-6),1.65)
	for x in [-8,-4,0,4,8]:
		asset("garden_fence_module",Vector3(x,-2.55,-3),2.2)
	var hose := asset("garden_hose",Vector3(-3.5,-2.8,1),2.1)
	hose.rotation.x = .26
	asset("garden_watering_can",Vector3(4,-3.06,1),3.3)
	var flowers = load("res://scenes/art_labs/assets_v06/flowering_shrub.tscn").instantiate()
	stage.add_child(flowers)
	flowers.position = Vector3(-8,-2.8,0)
	flowers.scale = Vector3.ONE*1.7
	bee_anchor(Vector3(-.8,.0,2))
func _unhandled_key_input(event: InputEvent) -> void:
	super._unhandled_key_input(event)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_G:
		show_garden()
