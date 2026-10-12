extends "res://scripts/art/future_biomes_lab.gd"
var boss: Node3D
func show_page(_index: int) -> void:
	_clear()
	camera.size = 12
	environment.environment.background_color = Color("a4ad89")
	title.text = "BEE ALIEN / MINI-JEFE DEL LAGO"
	subtitle.text = "Sapo original V09 · Anticipación + salto · POC visual, sin combate · L: liberar · P: pausa"
	shape(Vector3(0,-3.3,-7),Vector3(30,4,1),Color("8a9775"),true)
	shape(Vector3(5,-2.7,-5),Vector3(15,3.1,1),Color("6e855d"),true)
	shape(Vector3(-7,-2.8,-4),Vector3(13,3.0,1),Color("526e48"),true)
	var water := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(36,5)
	water.mesh = quad
	water.position = Vector3(0,-4.3,-.7)
	var wm := ShaderMaterial.new()
	wm.shader = WATER
	water.material_override = wm
	stage.add_child(water)
	asset("cattails_cluster",Vector3(-8,-2.5,-1),2.8)
	asset("cattails_cluster",Vector3(8,-2.5,-2),2.3)
	var pad := asset("lotus_lily_pad",Vector3(2.2,-2.15,0),4.0)
	pad.rotation.x = .28
	boss = load("res://scenes/levels/level_02_lake/lake_toad_miniboss_visual.tscn").instantiate()
	stage.add_child(boss)
	boss.position = Vector3(2.2,-2.1,1)
	boss.scale = Vector3.ONE*2.65
	bee_anchor(Vector3(-5.3,.05,2))
func _make_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var panel := Panel.new()
	panel.size = Vector2(1440,142)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(.07,.10,.09,.85)
	panel.add_theme_stylebox_override("panel",bg)
	ui.add_child(panel)
	title = Label.new()
	title.position = Vector2(28,25)
	title.add_theme_font_size_override("font_size",28)
	ui.add_child(title)
	subtitle = Label.new()
	subtitle.position = Vector2(28,70)
	ui.add_child(subtitle)
	var button := Button.new()
	button.position = Vector2(28,101)
	button.text = "L · Liberar / restaurar control"
	button.pressed.connect(toggle_control)
	ui.add_child(button)
func toggle_control() -> void:
	controlled = not controlled
	if controlled:
		boss.restore_control()
	else:
		boss.release_control()
func _process(_delta: float) -> void:
	if boss!=null:
		boss.preview_motion = animating and controlled
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_L: toggle_control()
		KEY_P: animating = not animating
		KEY_H: ui.visible = not ui.visible
		KEY_ESCAPE: get_tree().change_scene_to_file("res://scenes/art_labs/art_delivery_hub_v01.tscn")
