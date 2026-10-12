extends "res://scripts/art/asset_catalog_lab.gd"
func _make_ui() -> void:
	super._make_ui()
	var preview := Button.new()
	preview.position = Vector2(1050,105)
	preview.text = "O · Ver la orilla"
	preview.pressed.connect(show_lake)
	ui.add_child(preview)
func show_page(index: int) -> void:
	super.show_page(index)
	stage.get_child(2).position.x = 0
func show_lake() -> void:
	_clear()
	inspected_id = ""
	camera.size = 12
	ui.visible = true
	title.text = "BEE ALIEN / SUPERFICIE Y FONDO DEL LAGO"
	subtitle.text = "O: orilla · E: estudio · 1–3: piezas · L: liberar fauna · H: vista limpia · Esc: colección"
	environment.environment.background_color = Color("a4ae8a")
	shape(Vector3(0,-4,-7),Vector3(30,5,1),Color("879674"),true)
	var water := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(36,7)
	water.mesh = quad
	water.position = Vector3(0,-3.0,-.7)
	var material := ShaderMaterial.new()
	material.shader = WATER
	water.material_override = material
	stage.add_child(water)
	for x in [-8,8]:
		var reeds = load("res://scenes/art_labs/assets/cattails_cluster.tscn").instantiate()
		stage.add_child(reeds)
		reeds.position = Vector3(x,-.3,-2)
		reeds.scale = Vector3.ONE*2.2
	asset("controlled_water_strider",Vector3(-2.9,.86,1),2.0)
	asset("controlled_dragonfly_nymph",Vector3(-1.0,-2.3,1),2.2)
	asset("submerged_root_module",Vector3(4,-3.0,1),1.9)
	bee_anchor(Vector3(-6,2.0,2))
func _unhandled_key_input(event: InputEvent) -> void:
	super._unhandled_key_input(event)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_O:
		show_lake()
