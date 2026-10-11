extends Control
const LABS := [
	["Fauna ligera · ~5.000 triángulos","swarm_lite_v01"],
	["Araña colgante y águila","future_biomes_v11"],
	["Polen, Spread, bomba y curación","pickups_toon_v01"],
	["Proyectiles y explosiones","projectiles_toon_v01"],
	["Mini-jefe del lago","lake_miniboss_v01"],
	["Nave nodriza","mothership_v01"],
	["Manguera, regadera, valla y casa","garden_backdrop_v01"],
	["Zapatero, ninfa y raíces del lago","lake_fauna_v01"],
	["Ítems toon · prueba de recogida","pickups_game_toon_v01"],
	["Disparos toon · impacto real","projectiles_game_toon_v01"],
	["Águila · vuelo y picado","eagle_sky_v01"],
	["Interceptor y bombardero alien","alien_ships_v02"],
	["Tronco, helecho y campanilla","forest_floor_v01"],
	["Piña y dos tipos de pino","pine_woods_v01"],
	["Botella, cerillos y envoltorio","ground_litter_v01"],
	["Cáscara de banana y lata de atún","ground_litter_v02"],
	["Estrellas, poste y casas","residential_sky_v01"],
]
func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("273526")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.name = "DeliveryScroll"
	scroll.follow_focus = true
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 16
	scroll.offset_right = -16
	scroll.offset_top = 16
	scroll.offset_bottom = -16
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",20)
	center.add_child(stack)
	var title := Label.new()
	title.text = "BEE ALIEN / COLECCIÓN DE ARTE"
	title.add_theme_font_size_override("font_size",30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",18)
	stack.add_child(grid)
	for entry in LABS:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(370,64)
		button.add_theme_font_size_override("font_size",19)
		button.pressed.connect(open_lab.bind(entry[1]))
		grid.add_child(button)
	var back := Button.new()
	back.text = "Volver al título"
	back.custom_minimum_size.y = 48
	back.pressed.connect(open_lab.bind("title_screen_v01"))
	stack.add_child(back)
	grid.get_child(0).grab_focus()
func open_lab(id: String) -> void:
	get_tree().change_scene_to_file("res://scenes/art_labs/"+id+".tscn")
