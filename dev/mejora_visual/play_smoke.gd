extends SceneTree
## Prueba de humo con ventana: recorre el nivel entero con la cámara 2.5D y el mundo prendidos, mira que nada rompa.
## Bot que vuela en el tercio izquierdo, usa bombas, enjambre y pirueta. Bee no muere. Llega al robot, lo vence, llega a la tarántula y la vence.
## Mide cuánto duró cada tramo y lista errores en consola (los revisa quien lo corre).
const LEVEL := "res://scenes/levels/bee_level_01_vertical_slice.tscn"
const SPEED := 4.0
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var stage = load(LEVEL).instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8:
		await physics_frame
	var bee = stage.bee
	bee.health.damage_blocked = true
	var wave = stage.wave
	Engine.time_scale = SPEED
	var t := 0.0
	var marks := {}
	var last_zone := -1
	var guard := 0
	var stuck := 0.0
	var last_x := 0.0
	while guard < 60 * 300:
		await physics_frame
		guard += 1
		if paused:
			continue
		Engine.time_scale = SPEED
		t += SPEED / 60.0
		var half: float = BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(stage.get_viewport()))
		bee.global_position.x = stage.distance - half * (0.55 + 0.2 * sin(t * 0.5))
		bee.global_position.y = 3.2 + sin(t * 0.8) * 1.6
		if int(t * 12) % 2 == 0:
			bee.fire()
		if int(t * 4) % 40 == 0 and bee.bomb_charges > 0 and not is_instance_valid(bee.active_bomb):
			bee.use_bomb()
		var zone: int = preload("res://scripts/game/bee_world_settings.gd").zone_at(stage.distance)
		if zone != last_zone:
			print("ZONA ", zone, " x=", int(stage.distance), " t=", int(t))
			last_zone = zone
		if absf(stage.distance - last_x) > 0.01:
			last_x = stage.distance
			stuck = 0.0
		stuck += SPEED / 60.0
		if stuck > 3.0 and int(t * 10) % 3 == 0:
			for target in get_nodes_in_group("bee_auto_aim_targets"):
				var body := target as Node3D
				if body == null or absf(body.global_position.x - stage.distance) > half + 3.0:
					continue
				var health = body.get_node_or_null("HealthComponent")
				if health == null and body.get_parent() != null:
					health = body.get_parent().get_node_or_null("HealthComponent")
				if health is HealthComponent:
					health.take_damage(10)
		if is_instance_valid(wave.miniboss) and not marks.has("robot"):
			marks["robot"] = t
			print("ROBOT t=", int(t), " x=", int(stage.distance))
		if is_instance_valid(wave.miniboss):
			wave.miniboss.health.take_damage(4)
		if is_instance_valid(wave.tarantula) and not marks.has("tarantula"):
			marks["tarantula"] = t
			print("TARANTULA t=", int(t), " x=", int(stage.distance))
		if is_instance_valid(wave.tarantula) and wave.tarantula.health.current_health > 0:
			wave.tarantula.health.take_damage(2)
		if stage.has_node("ResultsScreen"):
			print("RESULTADOS t=", int(t), " liberados=", wave.liberated_count, " webs=", marks.get("webs", 0))
			break
		if is_instance_valid(wave.tarantula):
			marks["webs"] = wave.tarantula.sticky_webs_placed
	print("FIN guard=", guard, " x=", int(stage.distance), " marks=", marks, " time_scale=", Engine.time_scale)
	Engine.time_scale = 1.0
	quit(0)
