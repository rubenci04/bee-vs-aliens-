extends "res://tests/levels/bee_t7b_fixture.gd"
## Tanda X: momentos de los actos 2 (gotas de rocío) y 3 (cortadora), pantalla de resultados con Bee y estadísticas, y Bee
## volando en el título.
const M := preload("res://scripts/game/bee_moment_settings.gd")
const FLOW := preload("res://scripts/game/bee_flow_settings.gd")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var stage := await fixture()
	var bee := stage.bee
	var wave := stage.wave as BeeLevel01Controller

	# Los dos momentos están en la tabla, esperan el campo limpio y frenan eventos mientras duran.
	var rows := BeeLevel01Controller.EVENTS_ROSTER.filter(func(e): return str((e as Dictionary).get("moment", "")) in ["dew_drops", "lawnmower"])
	check(rows.size() == 2, "La tabla tiene los momentos de los actos 2 y 3")
	for row in rows:
		check(bool(row.get("clear", false)) and float(row.get("moment_seconds", 0.0)) > 0.0 and (row["units"] as Array).is_empty(), "El momento %s no trae enemigos y frena la tabla" % row["moment"])
	check(BeeLevel01Controller._moment_enabled(&"dew_drops") and BeeLevel01Controller._moment_enabled(&"lawnmower"), "Los dos momentos están prendidos")

	var pieces := stage.get_node("SetPieces")
	stage.set_physics_process(false)
	stage.distance = M.MOMENT_DEW_X
	stage._update_camera_and_bounds()

	# Acto 2: gotas con aviso (no lastiman mientras brillan colgadas), una sola vez.
	check(pieces.play(&"dew_drops") and not pieces.play(&"dew_drops"), "Las gotas arrancan y no se repiten")
	await frames(int(0.5 * 60.0))
	check(pieces.drops_spawned >= 1, "Caen gotas de rocío")
	var warned: Array = pieces._drops.filter(func(d): return float(d["warn_left"]) > 0.0)
	check(warned.all(func(d): return not (d["hitbox"] as DamageHitbox3D).enabled), "Mientras avisa, la gota no lastima")
	check(M.MOMENT_DEW_WARNING >= 0.4, "El aviso dura al menos 0,4 s")
	await frames(int(M.MOMENT_DEW_SECONDS * 60.0) + 30)
	check(pieces.running == &"" and pieces.drops_spawned >= int(M.MOMENT_DEW_SECONDS / M.MOMENT_DEW_EVERY) - 3, "A los %.0f s termina (%d gotas)" % [M.MOMENT_DEW_SECONDS, pieces.drops_spawned])

	# Acto 3: la cortadora; abajo lastima, arriba de la franja no.
	preload("res://scripts/game/bee_expression_settings.gd").HIT_REACTION_ENABLED = false
	stage.distance = M.MOMENT_MOWER_X
	stage._update_camera_and_bounds()
	bee.health.damage_blocked = false
	bee.health.current_health = bee.health.max_health
	bee.global_position = Vector3(stage.distance - 2.0, BeeLevel01Framing.top_y() - 0.6, 0.0)
	check(pieces.play(&"lawnmower") and is_instance_valid(pieces.mower), "La cortadora aparece al fondo")
	await frames(int((M.MOMENT_MOWER_WARNING + M.MOMENT_MOWER_PULSE * 2.0) * 60.0))
	check(bee.health.current_health == bee.health.max_health, "Volando alto, el pasto no la toca")
	bee.global_position.y = BeeLevel01Framing.bottom_y() + 0.8
	await frames(int(M.MOMENT_MOWER_PULSE * 2.0 * 60.0) + 10)
	check(bee.health.current_health < bee.health.max_health, "Volando bajo, el pasto la lastima")
	check(pieces.mower_pulses >= 2, "La cortadora sacude y tira pasto a pulsos")
	await frames(int(M.MOMENT_MOWER_SECONDS * 60.0))
	check(pieces.running == &"", "La cortadora se va")
	bee.health.damage_blocked = true
	preload("res://scripts/game/bee_expression_settings.gd").HIT_REACTION_ENABLED = true

	# Resultados: Bee girando, estadísticas de a una y el rango al final.
	var results = load("res://scenes/game/bee_results_screen.tscn").instantiate()
	results.released = 300
	results.total = 400
	results.score = 70000
	results.combo = 40
	results.seconds = 395.0
	results.bombs = 6
	results.swarms = 3
	results.hits = 21
	root.add_child(results)
	await process_frame
	var labels: Array = results.find_children("*", "Label", true, false)
	var texts: Array = labels.map(func(l): return (l as Label).text)
	for wanted in ["TIEMPO  6:35", "BOMBAS  6  ·  ENJAMBRES  3", "GOLPES RECIBIDOS  21", "MEJOR COMBO  ×40"]:
		check(texts.has(wanted), "La pantalla final muestra '%s'" % wanted)
	check(results.find_child("BeeView", true, false) != null, "Bee aparece girando en la pantalla final")
	var rank: Label = labels.filter(func(l): return (l as Label).text.begins_with("RANGO"))[0]
	check(is_equal_approx(rank.modulate.a, 0.0), "El rango todavía no se ve al abrir")
	await create_timer(FLOW.RESULTS_STAT_GAP * 9.0 + 1.0, true, false, true).timeout
	check(is_equal_approx(rank.modulate.a, 1.0), "El rango aparece al final")
	results.queue_free()

	# Título: Bee volando, no una imagen fija.
	var title = load("res://scenes/game/bee_title_screen.tscn").instantiate()
	root.add_child(title)
	await process_frame
	check(title.get_node_or_null("TitleBee") != null and title._title_bee != null, "El título tiene a Bee en 3D")
	var first: Vector3 = title._title_bee.position
	for i in 30: await process_frame
	check(not title._title_bee.position.is_equal_approx(first), "Bee vuela en el título")
	title.queue_free()

	print("TANDA_X failures=", failures)
	done()
