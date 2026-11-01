extends "res://tests/levels/bee_t7b_fixture.gd"
## Tanda W: el mundo responde. Polen cada 4 liberados, sin carteles flotantes, la vuelta alrededor de Bee al liberar,
## escenas cortas que pausan el juego, se saltean con cualquier botón y salen una sola vez por partida, y el cartel del jefe.
const RELEASE := preload("res://scripts/game/bee_release_settings.gd")
const STORY := preload("res://scripts/game/bee_story_settings.gd")
const BEATS := preload("res://scripts/levels/bee_story_beats.gd")

func pollen_count(stage: Node) -> int:
	return stage.find_children("*", "BeePollenPickup", true, false).filter(func(p): return not p.is_queued_for_deletion()).size()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var stage := await fixture()
	var bee := stage.bee

	# A. Polen: 1 de cada POLLEN_DROP_EVERY liberados deja un grano; ningún cartel flotante.
	BeeLiberation.liberations = 0
	var before := pollen_count(stage)
	for i in RELEASE.POLLEN_DROP_EVERY * 2:
		BeeLiberation.free_animal(stage, null, null, bee.global_position + Vector3(3.0 + i * 0.1, 1.0, 0.0))
	await frames(2)
	check(pollen_count(stage) - before == 2, "Con %d liberados caen 2 granos de polen (cayeron %d)" % [RELEASE.POLLEN_DROP_EVERY * 2, pollen_count(stage) - before])
	check(get_nodes_in_group("bee_liberated_text").is_empty() and BeeLiberation.max_texts() == 0, "Sin carteles LIBERADO flotantes: avisa el contador del HUD")

	# A. La vuelta: el liberado orbita a Bee y después se va; termina en LAP + LEAVE.
	var unit := Node3D.new()
	unit.name = "LapTestUnit"
	var model := MeshInstance3D.new()
	model.mesh = SphereMesh.new()
	unit.add_child(model)
	stage.add_child(unit)
	unit.global_position = bee.global_position + Vector3(3.0, 0.0, 0.0)
	var finished := [false]
	preload("res://scripts/vfx/bee_release_animation.gd").start_release(unit, model, func(): finished[0] = true)
	var orbit_distances: Array[float] = []
	var elapsed := 0.0
	while elapsed < RELEASE.LAP_SECONDS:
		await process_frame
		elapsed += stage.get_process_delta_time()
		if elapsed > RELEASE.LAP_SECONDS * 0.4 and is_instance_valid(unit):
			orbit_distances.append(unit.global_position.distance_to(bee.global_position + Vector3(0, RELEASE.LAP_HEIGHT, 0)))
	check(not orbit_distances.is_empty() and orbit_distances.max() < RELEASE.LAP_RADIUS * 1.25, "Durante la vuelta queda cerca de Bee (máx %.2f m)" % (orbit_distances.max() if not orbit_distances.is_empty() else -1.0))
	var waited := 0.0
	while waited < RELEASE.LEAVE_SECONDS + 0.5:
		await process_frame
		waited += stage.get_process_delta_time()
		if finished[0]: break
	check(finished[0], "Después de la vuelta se va y termina")

	# B. Escenas: pausan el juego, ponen barras, se saltean con un botón y salen una sola vez.
	var beats := stage.get_node("StoryBeats")
	check(beats != null, "El nivel tiene escenas cortas")
	check(beats.play(&"start") and paused and bool(beats.active), "La escena de arranque pausa el juego")
	await frames(2)
	for i in 20: await process_frame
	check((beats.get_node("StoryBars") as CanvasLayer).visible, "Barras negras arriba y abajo")
	await create_timer(STORY.SKIP_GRACE_SECONDS + 0.05, true, false, true).timeout
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	beats._input(key)
	check(not bool(beats.active) and not paused and bool(beats.skipped), "Cualquier botón la saltea y el juego sigue")
	check(not beats.play(&"start"), "La misma escena no se repite en la partida")
	# Reintento desde checkpoint: lo jugado se conserva; arranque nuevo: se borra.
	BEATS.attach(stage, false)
	check(stage.get_tree().get_meta(BEATS.PLAYED_META).has(&"start"), "Un reintento desde checkpoint no repite la escena")
	BEATS.attach(stage, true)
	check(not stage.get_tree().get_meta(BEATS.PLAYED_META).has(&"start"), "Un arranque nuevo la vuelve a mostrar")
	for extra in stage.get_children():
		if extra.name != "StoryBeats" and str(extra.name).begins_with("StoryBeats"):
			extra.queue_free()

	# Escena del robot: se termina sola en su duración y muestra el cartel del jefe.
	check(beats.play(&"robot") and paused, "La escena del robot pausa el juego")
	var fov_paused: float = stage.camera.fov
	await create_timer(STORY.ROBOT_SECONDS + 0.3, true, false, true).timeout
	check(not bool(beats.active) and not paused and not bool(beats.skipped), "La escena del robot termina sola en %.1f s" % STORY.ROBOT_SECONDS)
	var card := beats.get_node_or_null("BossCard")
	check(card != null, "Al terminar aparece el cartel del jefe")
	if card != null:
		var texts: Array = card.find_children("*", "Label", true, false).map(func(l): return (l as Label).text)
		check(texts.has(STORY.CARDS[&"robot"][0]), "El cartel dice %s" % STORY.CARDS[&"robot"][0])
	check(is_equal_approx(stage.camera.fov, fov_paused) or stage.camera.fov <= fov_paused * STORY.ROBOT_FOV_OPEN + 0.01, "La cámara vuelve a su apertura")

	print("TANDA_W failures=", failures)
	done()
