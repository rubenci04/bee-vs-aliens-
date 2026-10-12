extends "res://scripts/art/asset_catalog_lab.gd"
var effects: Array[Node3D] = []
func show_single(id: String, liberated := false, three_quarter := false) -> void:
	super.show_single(id,liberated,three_quarter)
	for fx in effects:
		fx.visible = false
		fx.playing = false
func show_page(index: int) -> void:
	super.show_page(index)
	for fx in effects:
		fx.play()
func _ready() -> void:
	super._ready()
	for i in 2:
		var fx = load("res://scenes/vfx/"+("alien" if i==1 else "bee")+"_toon_burst.tscn").instantiate()
		fx.autoplay = false
		fx.free_when_finished = false
		fx.position = Vector3(-4 if i==0 else 4,-2.8,0)
		fx.scale = Vector3.ONE*1.25
		add_child(fx)
		effects.append(fx)
		fx.play()
	subtitle.text = "Arriba: proyectiles · Abajo: explosiones · Espacio: repetir · H: ficha limpia"
func _process(delta: float) -> void:
	if not animating:
		return
	elapsed += delta
	if elapsed>1.2:
		elapsed = 0
		for fx in effects:
			if inspected_id.is_empty():
				fx.play()
func _unhandled_key_input(event: InputEvent) -> void:
	super._unhandled_key_input(event)
	if event is InputEventKey and event.pressed and event.keycode==KEY_SPACE and inspected_id.is_empty():
		for fx in effects:
			fx.play()
