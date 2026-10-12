extends "res://scripts/art/future_biomes_lab.gd"
var targets: Array[Node3D] = []
var shots: Array[Node3D] = []
var effects: Array[BeeToonBurstVisual] = []
var clock := 0.0
func _make_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var panel := Panel.new()
	panel.size = Vector2(1440,160)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.07,.09,.10,.9)
	panel.add_theme_stylebox_override("panel",style)
	ui.add_child(panel)
	title = Label.new()
	title.position = Vector2(28,22)
	title.text = "BEE ALIEN / DISPAROS E IMPACTOS TOON"
	title.add_theme_font_size_override("font_size",27)
	ui.add_child(title)
	subtitle = Label.new()
	subtitle.position = Vector2(28,61)
	subtitle.text = "Arriba: Bee → objetivo alien · Centro: alien → objetivo cálido · Abajo: explosiones"
	ui.add_child(subtitle)
	var repeat := Button.new()
	repeat.position = Vector2(28,102)
	repeat.text = "Espacio · Repetir disparos y explosiones"
	repeat.pressed.connect(repeat_cycle)
	ui.add_child(repeat)
	var tip := Label.new()
	tip.position = Vector2(28,139)
	tip.text = "P: pausar / reanudar · H: ocultar interfaz · Esc: colección"
	ui.add_child(tip)
func show_page(_index: int) -> void:
	camera.size = 12
	environment.environment.background_color = Color("777970")
	targets.append(make_target(&"alien",Vector3(7,1.8,0)))
	targets.append(make_target(&"bee",Vector3(-7,-.4,0)))
	for allegiance in ["bee","alien"]:
		var fx = load("res://scenes/vfx/toon/"+allegiance+"_explosion.tscn").instantiate() as BeeToonBurstVisual
		fx.autoplay = false
		fx.free_when_finished = false
		stage.add_child(fx)
		fx.position = Vector3(-4 if allegiance=="bee" else 4,-3.5,0)
		effects.append(fx)
	repeat_cycle()
func make_target(team: StringName, position: Vector3) -> Node3D:
	var target := Node3D.new()
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	target.add_child(health)
	var hurtbox = load("res://scenes/components/hurtbox_3d.tscn").instantiate() as DamageHurtbox3D
	hurtbox.team_id = team
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = .48
	shape.shape = sphere
	hurtbox.add_child(shape)
	target.add_child(hurtbox)
	var shell := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 24
	mesh.rings = 12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("393d46") if team==&"alien" else Color("cf9c3c")
	mesh.material = material
	shell.mesh = mesh
	target.add_child(shell)
	stage.add_child(target)
	target.position = position
	BeeToonStyle.apply(target,true,BeeToonStyle.OUTLINE_PROP)
	return target
func repeat_cycle() -> void:
	for shot in shots:
		if is_instance_valid(shot):
			shot.queue_free()
	shots.clear()
	for target in targets:
		target.get_node("HealthComponent").current_health = 100
	for i in 2:
		var shot = load("res://scenes/projectiles/toon/"+("bee" if i==0 else "alien")+"_bolt.tscn").instantiate()
		shot.speed = 8.0
		shot.lifetime = 3.0
		stage.add_child(shot)
		shot.position = Vector3(-7 if i==0 else 7,1.8 if i==0 else -.4,0)
		shot.launch(Vector3.RIGHT if i==0 else Vector3.LEFT,self)
		shots.append(shot)
	for fx in effects:
		fx.play()
	clock = 0
func set_paused(paused: bool) -> void:
	animating = not paused
	for shot in shots:
		if is_instance_valid(shot):
			shot.set_physics_process(not paused)
			shot.get_node("ShortTrail").speed_scale = 0.0 if paused else 1.0
	for fx in effects:
		fx.set_process(not paused)
func _process(delta: float) -> void:
	if animating:
		clock += delta
		if clock>2.8:
			repeat_cycle()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_SPACE:
			set_paused(false)
			repeat_cycle()
		KEY_P: set_paused(animating)
		KEY_H: ui.visible = not ui.visible
		KEY_ESCAPE: get_tree().change_scene_to_file("res://scenes/art_labs/art_delivery_hub_v01.tscn")
