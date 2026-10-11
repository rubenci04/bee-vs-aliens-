extends "res://scripts/art/future_biomes_lab.gd"
## Standalone title POC. Explicit button opens the existing level; main scene unchanged.
var hero: Node3D
func show_page(_index: int) -> void:
	_clear()
	camera.size = 12
	environment.environment.background_color = Color("829368")
	shape(Vector3(0,-4,-8),Vector3(34,7,1),Color("72865b"),true)
	shape(Vector3(7,-3,-6),Vector3(19,4.4,1),Color("526e46"),true)
	shape(Vector3(-9,-3,-5),Vector3(15,5,1),Color("425b35"),true)
	for entry in [[Vector3(-10,-4,-1),3.8],[Vector3(9,-4,-3),4.0]]:
		var tree = load("res://scenes/art_labs/assets_v06/garden_sapling.tscn").instantiate()
		stage.add_child(tree)
		tree.position = entry[0]
		tree.scale = Vector3.ONE*entry[1]
	var shrub = load("res://scenes/art_labs/assets_v06/flowering_shrub.tscn").instantiate()
	stage.add_child(shrub)
	shrub.position = Vector3(5,-4.0,0)
	shrub.scale = Vector3.ONE*3.4
	hero = load("res://assets/style/models/bee_mid_poly.glb").instantiate()
	hero.name = "BeeTitleVisual"
	stage.add_child(hero)
	hero.position = Vector3(4.5,.3,2)
	hero.rotation.y = -PI*.5
	BeeToonStyle.apply(hero,true,BeeToonStyle.OUTLINE_BEE)
	for mesh: MeshInstance3D in hero.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_surface_override_material(surface) as ShaderMaterial
			var energy: Variant = material.get_shader_parameter("emission_energy")
			if energy!=null and float(energy)>0:
				var own := material.duplicate() as ShaderMaterial
				own.set_shader_parameter("emission_energy",.65)
				mesh.set_surface_override_material(surface,own)
	hero.scale = Vector3.ONE*3.1
	for i in 23:
		shape(Vector3(sin(i*7.17)*10,cos(i*1.31)*4,-2),Vector3.ONE*.018,Color("e9ce79"),true)
func _make_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(screen)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",76)
	margin.add_theme_constant_override("margin_top",48)
	margin.add_theme_constant_override("margin_bottom",48)
	margin.add_theme_constant_override("margin_right",40)
	screen.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",22)
	margin.add_child(stack)
	var caption := Label.new()
	caption.text = "UNA PEQUEÑA ABEJA · UN MUNDO ENORME"
	caption.add_theme_font_size_override("font_size",17)
	caption.add_theme_color_override("font_color",Color("f1e5c0"))
	caption.add_theme_constant_override("outline_size",3)
	caption.add_theme_color_override("font_outline_color",Color("292218"))
	stack.add_child(caption)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(spacer)
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = load("res://assets/ui/bee_alien_logo_v01.svg")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(650,245)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	stack.add_child(logo)
	var menu := VBoxContainer.new()
	menu.custom_minimum_size.x = 330
	menu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu.add_theme_constant_override("separation",12)
	stack.add_child(menu)
	for option in [["Jugar Nivel 01","res://scenes/levels/bee_level_01_vertical_slice.tscn"],["Colección de arte","res://scenes/art_labs/art_delivery_hub_v01.tscn"],["Salir",""]]:
		var button := Button.new()
		button.text = option[0]
		button.custom_minimum_size = Vector2(330,54)
		button.add_theme_font_size_override("font_size",21)
		for state in ["normal","hover","pressed","focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("443b26") if state=="normal" else Color("716033")
			style.border_color = Color("d7b55a")
			style.set_border_width_all(2)
			style.set_corner_radius_all(14)
			button.add_theme_stylebox_override(state,style)
		button.add_theme_color_override("font_color",Color("f4e4bc"))
		button.pressed.connect(navigate.bind(option[1]))
		menu.add_child(button)
	menu.get_child(0).call_deferred("grab_focus")
	var lower := Control.new()
	lower.custom_minimum_size.y = 40
	stack.add_child(lower)
	var footer := Label.new()
	footer.text = "BEE ALIEN"
	footer.add_theme_font_size_override("font_size",14)
	footer.add_theme_color_override("font_color",Color("d3d3a8"))
	stack.add_child(footer)
func navigate(path: String) -> void:
	if path.is_empty():
		get_tree().quit()
	else:
		get_tree().change_scene_to_file(path)
func _process(delta: float) -> void:
	if hero!=null and animating:
		elapsed += delta
		hero.position.y = .3+sin(elapsed*1.7)*.14
func _unhandled_key_input(_event: InputEvent) -> void:
	pass
