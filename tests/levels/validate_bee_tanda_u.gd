extends SceneTree
## Tanda U: "Bee siente". Prioridad de caras, las piezas de la cara se mueven, invulnerabilidad de 0,35 s tras un golpe,
## retroceso alejándose del golpe, chispas con vida baja, festejo y tope de frases.
const S := preload("res://scripts/game/bee_expression_settings.gd")
const EXPRESSIONS := preload("res://scripts/bee_prototype/bee_expressions.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func frames(n: int) -> void:
	for i in n: await physics_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	# A. Prioridad: sorpresa > contenta > cansada > concentrada > neutra.
	check(EXPRESSIONS.choose(true, true, true, true) == &"surprised", "La sorpresa gana a todo")
	check(EXPRESSIONS.choose(false, true, true, true) == &"happy", "Contenta gana a cansada y concentrada")
	check(EXPRESSIONS.choose(false, false, true, true) == &"tired", "Cansada gana a concentrada")
	check(EXPRESSIONS.choose(false, false, false, true) == &"focused", "Concentrada gana a neutra")
	check(EXPRESSIONS.choose(false, false, false, false) == &"neutral", "Sin nada, neutra")

	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.wave.set_physics_process(false)
	stage.set_physics_process(false)
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.flight_min = Vector2(-20, 0.7)
	bee.flight_max = Vector2(400, 7.2)
	bee.global_position = Vector3(20.0, 4.0, 0.0)
	var visual := bee.get_node("VisualRoot/BeeVisual")
	var faces = visual.expressions
	check(faces.is_bound(), "Las piezas de la cara del modelo v02 están enganchadas (%d)" % faces.parts.size())
	var eye: MeshInstance3D = faces.parts["Eye_L"]["node"]
	var brow: MeshInstance3D = faces.parts["Brow_L"]["node"]
	var eye_rest: Transform3D = eye.transform
	var brow_rest: Transform3D = brow.transform
	faces.set_face_now(&"surprised")
	check(eye.transform.basis.get_scale().x > eye_rest.basis.get_scale().x * 1.2, "Sorpresa: ojos grandes")
	var brow_pivot: Vector3 = faces.parts["Brow_L"]["pivot"]
	check((brow.transform * brow_pivot).y > (brow_rest * brow_pivot).y, "Sorpresa: cejas arriba")
	faces.set_face_now(&"happy")
	check(eye.transform.basis.get_scale().y < eye_rest.basis.get_scale().y * 0.6, "Contenta: ojos entrecerrados")
	faces.set_face_now(&"neutral")
	check(eye.transform.is_equal_approx(eye_rest) and brow.transform.is_equal_approx(brow_rest), "Neutra vuelve a la pose del modelo")

	# Disparar: concentrada.
	bee.fire()
	check(visual.current_face() == &"focused", "Disparando, cara concentrada")

	# B. Golpe: sorpresa, invulnerabilidad 0,35 s para todo daño, retroceso alejándose del golpe.
	var reaction := stage.get_node("BeeHitReaction")
	bee.health.damage_blocked = false
	bee.health.invulnerable = false
	var shape := SphereShape3D.new()
	shape.radius = 0.2
	var shooter := Node3D.new()
	stage.add_child(shooter)
	var first := BeeAttackVisuals.hazard_area(stage, shooter, 5, shape)
	first.global_position = bee.global_position + Vector3(1.0, 0.0, 0.0) # Le pegan desde la derecha.
	first.set_enabled(true)
	var x_before := bee.global_position.x
	var hp := bee.health.current_health
	check(bee.hurtbox.receive_hit(first) > 0, "El primer golpe entra")
	check(visual.current_face() == &"surprised", "Al recibir el golpe, sorpresa")
	var second := BeeAttackVisuals.hazard_area(stage, shooter, 5, shape)
	second.set_enabled(true)
	check(bee.hurtbox.receive_hit(second) == 0 and bee.health.hit_protected, "Durante la invulnerabilidad un segundo golpe no entra")
	check(bee.health.take_damage(7) == 0, "La invulnerabilidad vale para TODO daño (también el directo)")
	await frames(int(ceil(S.KNOCKBACK_SECONDS * 60.0)) + 2) # Cuadros de física: el headless no sigue el reloj real.
	var pushed := x_before - bee.global_position.x
	check(pushed > S.KNOCKBACK_DISTANCE * 0.7 and pushed < S.KNOCKBACK_DISTANCE * 1.3, "Retroceso de ~%.2f m hacia la izquierda (fue %.3f)" % [S.KNOCKBACK_DISTANCE, pushed])
	await frames(int(ceil(S.HIT_INVULN_SECONDS * 60.0)))
	check(not bee.health.hit_protected, "A los %.2f s la invulnerabilidad termina" % S.HIT_INVULN_SECONDS)
	var third := BeeAttackVisuals.hazard_area(stage, shooter, 5, shape)
	third.set_enabled(true)
	check(bee.hurtbox.receive_hit(third) > 0 and bee.health.current_health == hp - 10, "Después vuelve a recibir daño (vida %d -> %d)" % [hp, bee.health.current_health])
	check(int(reaction.hits) == 2, "La reacción contó los golpes que entraron")
	await frames(int(ceil(S.HIT_INVULN_SECONDS * 60.0)) + 3)

	# C. Vida baja: cara cansada y chispas del implante cada LOW_HP_SPARK_EVERY s.
	bee.health.current_health = int(bee.health.max_health * 0.2)
	visual.surprise_left = 0.0
	visual.happy_left = 0.0
	visual.focus_left = 0.0
	check(visual.current_face() == &"tired", "Con vida baja, cara cansada")
	await frames(2)
	check(reaction.spark_clock > 0.0, "El implante chisporrotea con vida baja")

	# D. Zona despejada: festejo (cara contenta y vuelta) sin invulnerabilidad extra.
	preload("res://scripts/bee_prototype/bee_feelings.gd").zone_clear(self)
	check(visual.celebrate_left > 0.0 and visual.current_face() == &"happy", "Zona despejada: vuelta y cara contenta")
	check(not bee.health.hit_protected and not bee.health.invulnerable, "El festejo no da invulnerabilidad")

	# E. Frases: como mucho una cada BARK_MIN_GAP_SECONDS; los momentos "una vez" no se repiten.
	var barks := stage.get_node("BeeBarks")
	barks.since_last = INF
	barks.said_once.clear()
	barks.history.clear()
	check(barks.say("first_liberation", true), "Primera liberación: habla")
	check(not barks.say("zone_clear"), "Otra frase enseguida: no (tope de %.0f s)" % S.BARK_MIN_GAP_SECONDS)
	barks.since_last = S.BARK_MIN_GAP_SECONDS
	check(not barks.say("first_liberation", true), "La primera liberación habla una sola vez")
	check(barks.say("zone_clear"), "Pasado el tope, vuelve a hablar")
	var lines: Dictionary = barks.load_lines()
	for moment in ["first_liberation", "first_hit", "zone_clear", "low_health", "boss_robot", "boss_spider"]:
		check(lines.has(moment) and not (lines[moment] as Array).is_empty(), "El JSON tiene frases para %s" % moment)
		for text in lines.get(moment, []):
			check(str(text).split(" ", false).size() <= 3, "Frase de 1 a 3 palabras: '%s'" % text)
	S.BARKS_ENABLED = false
	barks.since_last = INF
	check(not barks.say("zone_clear"), "Con las frases apagadas no habla")
	S.BARKS_ENABLED = true

	print("TANDA_U failures=", failures)
	quit(1 if failures else 0)
