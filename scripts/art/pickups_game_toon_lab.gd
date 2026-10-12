extends "res://scripts/art/future_biomes_lab.gd"
const ITEM_IDS := ["pollen","spread","bomb","healing"]
const ITEM_NAMES := ["Polen","Spread","Bomba","Curación"]
var bee: BeePlayer
var pickups: Array[Area3D] = []
var feedback: Label
func _make_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var panel := Panel.new()
	panel.size = Vector2(1440,180)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(.07,.09,.08,.9)
	panel.add_theme_stylebox_override("panel",background)
	ui.add_child(panel)
	title = Label.new()
	title.position = Vector2(28,22)
	title.text = "BEE ALIEN / ÍTEMS TOON · PRUEBA DE RECOGIDA"
	title.add_theme_font_size_override("font_size",27)
	ui.add_child(title)
	subtitle = Label.new()
	subtitle.position = Vector2(28,62)
	ui.add_child(subtitle)
	var row := HBoxContainer.new()
	row.position = Vector2(28,98)
	row.add_theme_constant_override("separation",12)
	ui.add_child(row)
	for i in 4:
		var button := Button.new()
		button.text = str(i+1)+" · Recoger "+ITEM_NAMES[i]
		button.pressed.connect(collect_item.bind(i))
		row.add_child(button)
	var reset := Button.new()
	reset.text = "R · Reiniciar prueba"
	reset.pressed.connect(show_page.bind(0))
	row.add_child(reset)
	feedback = Label.new()
	feedback.position = Vector2(28,144)
	ui.add_child(feedback)
func show_page(_index: int) -> void:
	_clear()
	pickups.clear()
	camera.size = 10.8
	environment.environment.background_color = Color("777970")
	bee = load("res://scenes/bee_prototype/bee_player.tscn").instantiate()
	stage.add_child(bee)
	bee.set_physics_process(false)
	bee.position = Vector3(-6.8,-1.5,1)
	bee.collision_layer = 0
	bee.collision_mask = 0
	bee.health.take_damage(40)
	for i in 4:
		var pickup = load("res://scenes/items/toon/"+ITEM_IDS[i]+".tscn").instantiate()
		stage.add_child(pickup)
		pickup.position = Vector3(-3.5 if i%2==0 else 3.5,.25 if i<2 else -3.0,0)
		pickup.scale = Vector3.ONE*2.1
		pickup.monitoring = false
		pickups.append(pickup)
	feedback.text = "Bee inicia con 60 de vida · 1–4: recoger · R: reiniciar · H: ocultar UI · Esc: colección"
	refresh()
func collect_item(index: int) -> void:
	if not is_instance_valid(pickups[index]) or pickups[index].is_queued_for_deletion():
		return
	var accepted: bool = pickups[index].collect(bee)
	feedback.text = ITEM_NAMES[index]+(" recogido" if accepted else " queda disponible: capacidad completa")
	refresh()
func refresh() -> void:
	subtitle.text = "Vida %d/%d · Spread %d ráfagas · Bombas %d/%d"%[bee.health.current_health,bee.health.max_health,bee.spread_ammo,bee.bomb_charges,bee.max_bomb_charges]
func _process(_delta: float) -> void:
	pass
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode>=KEY_1 and event.keycode<=KEY_4:
		collect_item(event.keycode-KEY_1)
	match event.keycode:
		KEY_R: show_page(0)
		KEY_H: ui.visible = not ui.visible
		KEY_ESCAPE: get_tree().change_scene_to_file("res://scenes/art_labs/art_delivery_hub_v01.tscn")
