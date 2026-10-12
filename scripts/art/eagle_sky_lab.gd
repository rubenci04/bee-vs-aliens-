extends "res://scripts/art/asset_catalog_lab.gd"
## Small sky-level art POC, isolated from gameplay and its enemy scripts.
var sky_mode := false
var eagle: Node3D
var preview_time := 0.0
var diving := false

func _make_ui() -> void:
	super._make_ui()
	var sky := Button.new()
	sky.position = Vector2(350,105)
	sky.text = "G · Cielo / vuelo"
	sky.pressed.connect(show_sky)
	ui.add_child(sky)

func show_page(index: int) -> void:
	sky_mode = false
	super.show_page(index)
	freeze_studio()

func show_single(id: String, liberated := false, three_quarter := false) -> void:
	sky_mode = false
	super.show_single(id,liberated,three_quarter)
	freeze_studio()

func freeze_studio() -> void:
	for child in stage.get_children():
		if child.has_method("seek"):
			child.animate_wings = false
			child.set_flight_pose(1)
			child.seek(0.0)

func show_sky() -> void:
	_clear()
	sky_mode = true
	creature_mode = false
	inspected_id = ""
	preview_time = 0.0
	diving = false
	camera.size = 11.5
	ui.visible = true
	environment.environment.background_color = Color("b9c5b3")
	title.text = "BEE ALIEN / AMENAZA DEL CIELO"
	subtitle.text = "G: reiniciar vuelo · D: picado · P: pausa · L: liberar · E: estudio · H: ocultar interfaz"
	# Atmospheric layers use muted, non-emissive natural colours.
	shape(Vector3(0,-5.0,-8),Vector3(22,3.6,1),Color("98a587"),true)
	shape(Vector3(-7,-5.3,-6),Vector3(9,3.4,1),Color("7f9274"),true)
	shape(Vector3(8,-5.7,-4),Vector3(10,3.4,1),Color("697e60"),true)
	for placement in [Vector3(-7,2.5,-6),Vector3(6,3,-6),Vector3(0,-2.5,-5)]:
		var cloud := (load("res://scenes/art_labs/assets_v07/sky_cloud.tscn") as PackedScene).instantiate() as Node3D
		stage.add_child(cloud)
		cloud.position = placement
		cloud.scale = Vector3.ONE*2.6
	eagle = asset("controlled_eagle_flight",Vector3(3,0.6,0),2.05)
	eagle.animate_wings = false
	var bee := (load("res://assets/models/shared/bee/bee_mid_poly.glb") as PackedScene).instantiate() as Node3D
	stage.add_child(bee)
	bee.name = "BeeScaleReference"
	bee.position = Vector3(-5,-0.5,1)
	bee.scale = Vector3.ONE*0.55
	bee.rotation.y = -PI*0.5
	BeeToonStyle.apply(bee,true,BeeToonStyle.OUTLINE_BEE)
	seek_preview(0.0)

func start_dive() -> void:
	if not sky_mode:
		show_sky()
	diving = true
	preview_time = 0.0
	seek_preview(0.0)

func seek_preview(seconds: float) -> void:
	preview_time = seconds
	if not sky_mode or not is_instance_valid(eagle):
		return
	if diving:
		# Tell: 0–0.65 s, dive: 0.65–1.65 s, recovery: 1.65–3 s.
		var t := fposmod(seconds,3.0)
		if t < 0.65:
			eagle.position = Vector3(3,0.6+sin(t/0.65*PI)*0.35,0)
			eagle.rotation.z = 0.08*sin(t/0.65*PI)
			eagle.set_flight_pose(1)
		elif t < 1.65:
			var amount := smoothstep(0.65,1.65,t)
			eagle.position = Vector3(3,0.6,0).lerp(Vector3(-3,-1.3,0),amount)
			eagle.rotation.z = 0.3
			eagle.set_flight_pose(2)
		else:
			var amount := smoothstep(1.65,3.0,t)
			eagle.position = Vector3(-3,-1.3,0).lerp(Vector3(3,0.6,0),amount)
			eagle.position.y += sin(amount*PI)*0.7
			eagle.rotation.z = lerpf(0.3,0.0,amount)
			eagle.set_flight_pose(0)
	else:
		eagle.position = Vector3(3+sin(seconds*0.5)*0.4,0.6+sin(seconds*1.2)*0.25,0)
		eagle.rotation.z = sin(seconds*0.7)*0.025
		eagle.set_flight_pose(0 if fposmod(seconds,6.0)<3.0 else 1)
	eagle.seek(seconds)

func _process(delta: float) -> void:
	if sky_mode and animating:
		seek_preview(preview_time+delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G: show_sky()
			KEY_D: start_dive()
			KEY_P: animating = not animating
	super._unhandled_key_input(event)
