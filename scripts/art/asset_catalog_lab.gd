extends "res://scripts/art/future_biomes_lab.gd"
## Reusable isolated catalog for small art batches. Never loads gameplay.
@export var catalog_title := "BEE ALIEN / CATÁLOGO"
@export var asset_folder := "swarm_lite_v01"
@export var asset_ids: PackedStringArray = []
@export var asset_names: PackedStringArray = []
@export var factors: PackedFloat32Array = []
@export var offsets: PackedFloat32Array = []
@export var single_camera_size := 4.7
@export var removable_control := true

func _make_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var panel := Panel.new()
	panel.size = Vector2(1440,178)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.07,.09,.10,.85)
	panel.add_theme_stylebox_override("panel",style)
	ui.add_child(panel)
	title = Label.new()
	title.position = Vector2(28,22)
	title.add_theme_font_size_override("font_size",27)
	ui.add_child(title)
	subtitle = Label.new()
	subtitle.position = Vector2(28,61)
	subtitle.add_theme_font_size_override("font_size",16)
	ui.add_child(subtitle)
	var row := HBoxContainer.new()
	row.position = Vector2(28,105)
	ui.add_child(row)
	var studio := Button.new()
	studio.text = "E · Estudio"
	studio.pressed.connect(show_page.bind(0))
	row.add_child(studio)
	for i in asset_ids.size():
		var button := Button.new()
		button.text = str(i+1)+" · "+asset_names[i]
		button.pressed.connect(inspect_asset.bind(asset_ids[i],false))
		row.add_child(button)
	var tip := Label.new()
	tip.position = Vector2(28,149)
	tip.text = "V: lateral / 3⁄4   ·   H: ocultar interfaz" + ("   ·   L: liberar" if removable_control else "")
	ui.add_child(tip)

func asset(id: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	var visual := (load("res://scenes/art_labs/"+asset_folder+"/"+id+".tscn") as PackedScene).instantiate() as Node3D
	stage.add_child(visual)
	visual.name = id
	visual.position = pos
	visual.scale = Vector3.ONE*factor
	visual.controlled = controlled
	return visual

func show_page(_index: int) -> void:
	_clear()
	creature_mode = false
	inspected_id = ""
	camera.size = 10.8
	ui.visible = true
	environment.environment.background_color = Color("777970")
	title.text = catalog_title
	subtitle.text = "Estudio neutro · Seleccionar pieza · H: ficha limpia" + (" · L: retirar tecnología" if removable_control else "")
	for i in asset_ids.size():
		var x := -4.0 if i%2==0 else 4.0
		var y := .35 if i<2 else -3.1
		if asset_ids.size()==1:
			x = 0.0
			y = 0.0
		asset(asset_ids[i],Vector3(x,y+offsets[i],0),factors[i])

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	var index := asset_ids.find(id)
	var model := stage.get_child(0) as Node3D
	model.scale = Vector3.ONE*factors[index]
	model.position.y = offsets[index]
	camera.size = single_camera_size

func inspect_asset(id: String, three_quarter: bool) -> void:
	show_single(id,not controlled,three_quarter)
	ui.visible = true
	title.text = catalog_title+" / "+asset_names[asset_ids.find(id)]
	subtitle.text = "V: lateral / 3⁄4 · H: ficha limpia" + (" · L: liberar" if removable_control else "")

func toggle_control() -> void:
	if not removable_control:
		return
	controlled = not controlled
	for child in stage.get_children():
		if child.has_method("release_control"):
			child.controlled = controlled

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode>=KEY_1 and event.keycode<KEY_1+asset_ids.size():
		inspect_asset(asset_ids[event.keycode-KEY_1],false)
	match event.keycode:
		KEY_E: show_page(0)
		KEY_L: toggle_control()
		KEY_H: ui.visible = not ui.visible
		KEY_V:
			if not inspected_id.is_empty(): inspect_asset(inspected_id,not angled)
		KEY_ESCAPE: get_tree().change_scene_to_file("res://scenes/art_labs/art_delivery_hub_v01.tscn")
