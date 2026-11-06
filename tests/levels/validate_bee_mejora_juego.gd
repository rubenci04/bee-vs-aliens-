extends SceneTree
# Mejora visual · jugabilidad: telarañas fijas que atrapan (con aviso, nunca encima de Bee), más arañas y avispas en la tarántula sin tocar su
# vida ni su daño por golpe, bandadas de moscas de poca vida y puntería que no salta entre un enemigo de arriba y uno de abajo.
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok:
		return
	failures += 1
	push_error(message)
	print("FAIL: ", message)

func run() -> void:
	var stage = LEVEL.instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 6:
		await physics_frame
	var bee: BeePlayer = stage.bee
	bee.health.damage_blocked = true
	bee.set_physics_process(false)
	var wave: BeeLevel01Controller = stage.wave

	# --- Reglas de la tarántula: más presión, misma vida y mismo daño por golpe. ---
	check(TarantulaBoss01.SPIDER_WAVE_SIZE.has(TarantulaBoss01.State.PHASE_3), "también hay arañas colgando en la fase 3")
	check(TarantulaBoss01.WASP_PHASES.size() >= 3, "avispas en tres fases")
	var nets := 0
	for move in TarantulaBoss01.PATTERNS[TarantulaBoss01.State.PHASE_3]:
		if move == &"net":
			nets += 1
	check(nets >= 5, "más redes que atrapan por fase (%d)" % nets)

	# --- Telaraña fija: durante el aviso no atrapa, armada sí; rodar la rompe sin quedar atrapada. ---
	stage.distance = 340.5
	stage._update_camera_and_bounds()
	wave._start_tarantula()
	var spider: TarantulaBoss01 = wave.tarantula
	spider.set_physics_process(false)
	spider._web_immune_left = 0.0
	bee.global_position = Vector3(340.0, 3.5, 0.0)
	var web := TarantulaWebNet.place_sticky(stage, spider, bee, bee.global_position)
	check(web.is_in_group("tarantula_sticky_webs"), "la telaraña se registra")
	for i in 10:
		await physics_frame
	check(not bee.web_locked, "mientras se arma no atrapa")
	for i in int(TarantulaWebNet.STICKY_WARNING * 60.0) + 4:
		await physics_frame
	check(bee.web_locked and web.trapping, "armada, atrapa a Bee")
	web.release()
	check(not bee.web_locked, "al soltarse Bee queda libre")
	await physics_frame
	spider._web_immune_left = 0.0
	var second := TarantulaWebNet.place_sticky(stage, spider, bee, bee.global_position)
	second._life = TarantulaWebNet.STICKY_WARNING + 0.1
	bee.is_rolling = true
	for i in 3:
		await physics_frame
	check(not bee.web_locked and not is_instance_valid(second), "rodar la rompe sin quedar atrapada")
	bee.is_rolling = false
	# Nunca nace encima de Bee y hay un tope por fase.
	for node in get_nodes_in_group("tarantula_sticky_webs"):
		node.queue_free()
	await physics_frame
	spider.state = TarantulaBoss01.State.PHASE_2
	spider._sticky_timer = 0.0
	spider._update_sticky_webs(0.016)
	var placed := get_nodes_in_group("tarantula_sticky_webs")
	check(placed.size() == 1, "la tarántula pone telarañas")
	check((placed[0] as Node3D).global_position.distance_to(bee.global_position) >= TarantulaBoss01.STICKY_WEB_MIN_FROM_BEE, "nunca encima de Bee")
	for i in 10:
		spider._sticky_timer = 0.0
		spider._update_sticky_webs(0.016)
	check(get_nodes_in_group("tarantula_sticky_webs").size() <= int(TarantulaBoss01.STICKY_WEB_MAX[TarantulaBoss01.State.PHASE_2]), "tope de telarañas por fase")
	spider.queue_free()
	for node in get_nodes_in_group("tarantula_sticky_webs"):
		node.queue_free()
	await physics_frame

	# --- Bandadas en la tabla, y de poca vida. ---
	var flocks := 0
	for event in BeeLevel01Controller.EVENTS_ROSTER:
		if bool(event.get("flock", false)):
			flocks += 1
			check(event["units"].size() >= 5, "una bandada son muchas moscas")
	check(flocks >= 4, "un pico de acción por acto (%d)" % flocks)

	# --- Puntería: con uno arriba y otro abajo, no salta y respeta el blanco actual. ---
	var make_target := func(at: Vector3) -> Node3D:
		var target := StaticBody3D.new()
		target.add_to_group("bee_auto_aim_targets")
		stage.add_child(target)
		target.global_position = at
		return target
	for node in get_nodes_in_group("bee_auto_aim_targets"):
		node.remove_from_group("bee_auto_aim_targets")
	stage.distance = 100.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(97.0, 3.0, 0.0)
	var settings := preload("res://scripts/game/bee_shooting_settings.gd")
	check(settings.SMART_AIM_ENABLED and settings.SMART_AIM_CONE > 80.0, "cono de búsqueda más abierto")
	wave.set_physics_process(false)
	await physics_frame
	var upper: Node3D = make_target.call(Vector3(100.0, 5.4, 0.0))
	var lower: Node3D = make_target.call(Vector3(100.0, 0.9, 0.0))
	await physics_frame
	check(bee.refresh_auto_aim() == lower, "sin moverse elige al más cercano (el de abajo está a %.2f)" % bee.global_position.distance_to(lower.global_position))
	lower.global_position = Vector3(100.0, 0.75, 0.0) # El de abajo queda apenas más lejos que el de arriba.
	upper.global_position = Vector3(100.0, 5.2, 0.0)
	check(bee.refresh_auto_aim() == lower, "el blanco actual se mantiene: no salta por una diferencia mínima")
	Input.action_press("move_forward")
	var picked_up := bee.refresh_auto_aim()
	Input.action_release("move_forward")
	check(picked_up == upper, "si el jugador sube, prefiere al enemigo de arriba")
	Input.action_press("move_back")
	var picked_down := bee.refresh_auto_aim()
	Input.action_release("move_back")
	check(picked_down == lower, "si el jugador baja, prefiere al enemigo de abajo")
	upper.queue_free()
	lower.queue_free()
	var steep: Node3D = make_target.call(Vector3(97.9, 6.2, 0.0))
	await physics_frame
	check(bee.refresh_auto_aim() == steep, "un enemigo casi encima de Bee también cuenta")
	if failures == 0:
		print("PASS validate_bee_mejora_juego")
	quit(1 if failures > 0 else 0)
