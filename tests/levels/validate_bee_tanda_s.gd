extends SceneTree
## Tanda S: "se ve a Bee". Escala visual vs hurtbox, margen de borde, aguja de bala, un solo aviso de liberación,
## teletransporte corto, sombra, pasillo limpio y que el interruptor HERO_LOOK_ENABLED vuelva al look anterior.
const HERO := preload("res://scripts/game/bee_hero_look_settings.gd")
const TELEPORT := preload("res://scripts/vfx/bee_enemy_teleport.gd")
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
	check(HERO.HERO_LOOK_ENABLED, "El look de heroína viene encendido")
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.wave.set_physics_process(false)
	var bee := stage.bee
	bee.health.damage_blocked = true

	# A. Escala visual 1.2; la hurtbox y el cuerpo no cambian.
	var visual_root := bee.get_node("VisualRoot") as Node3D
	check(is_equal_approx(visual_root.scale.x, HERO.BEE_VISUAL_SCALE), "Bee se dibuja a %.2f (es %.2f)" % [HERO.BEE_VISUAL_SCALE, visual_root.scale.x])
	var hurt_shape := (bee.hurtbox.get_node("CollisionShape3D") as CollisionShape3D)
	check(is_equal_approx(bee.hurtbox.scale.x, 1.0) and is_equal_approx(hurt_shape.global_transform.basis.get_scale().x, 1.0), "La hurtbox no crece con el dibujo")
	var reference: PackedScene = load("res://scenes/bee_prototype/bee_player.tscn")
	var plain := reference.instantiate()
	var plain_shape := plain.get_node("Hurtbox3D/CollisionShape3D") as CollisionShape3D
	check(plain_shape.shape.get_class() == hurt_shape.shape.get_class() and str(plain_shape.shape.get("radius")) == str(hurt_shape.shape.get("radius")) and str(plain_shape.shape.get("height")) == str(hurt_shape.shape.get("height")), "La forma de la hurtbox es la de la escena original")
	plain.free()
	# El punto de salida de la bala es el mismo que con la escala de antes.
	var visual := bee.get_node("VisualRoot/BeeVisual")
	var origin_big: Vector3 = visual.firing_origin(bee.global_position)
	visual_root.scale = Vector3.ONE * BeeGameSettings.BEE_VISUAL_SCALE
	var origin_plain: Vector3 = visual.firing_origin(bee.global_position)
	visual_root.scale = Vector3.ONE * HERO.BEE_VISUAL_SCALE
	check(origin_big.distance_to(origin_plain) < 0.01, "Las balas salen del mismo lugar (%.3f m de diferencia)" % origin_big.distance_to(origin_plain))

	# H. Margen de borde: el centro de Bee nunca a menos del 6 % del ancho visible.
	var aspect := BeeLevel01Framing.view_aspect(stage.get_viewport())
	var half := BeeLevel01Framing.half_width_min(aspect)
	bee.global_position = Vector3(stage.distance - 50.0, 4.0, 0.0)
	stage._update_camera_and_bounds()
	var left_margin := (bee.global_position.x - (stage.distance - half)) / (2.0 * half)
	check(left_margin >= HERO.BEE_SCREEN_MARGIN - 0.001, "Borde izquierdo: %.3f del ancho (mínimo %.2f)" % [left_margin, HERO.BEE_SCREEN_MARGIN])
	var right_margin := ((stage.distance + half) - bee.flight_max.x) / (2.0 * half)
	check(right_margin >= HERO.BEE_SCREEN_MARGIN - 0.001, "Borde derecho: %.3f del ancho (mínimo %.2f)" % [right_margin, HERO.BEE_SCREEN_MARGIN])

	# D. Bala: aguja fina (más larga que ancha), 60 % del brillo, oculta hasta salir de la silueta; daño, velocidad y hitbox iguales.
	bee.global_position = Vector3(stage.distance - 2.0, 4.0, 0.0)
	var shot := bee.fire() as BeeEnergyProjectile
	check(shot != null, "Bee dispara")
	if shot != null:
		var plasma := shot.get_node("PlasmaBall") as Node3D
		var halo := (plasma.get_node("Halo") as MeshInstance3D).mesh as SphereMesh
		check(is_equal_approx(halo.radius, BeeShotPalette.BEE_RADII.y * HERO.SHOT_THICKNESS), "Halo de la aguja más fino (%.3f m)" % halo.radius)
		var length := halo.radius * plasma.scale.x
		var width := halo.radius * plasma.scale.y
		check(length >= width * 2.0, "La aguja es alargada (%.3f x %.3f)" % [length, width])
		check(halo.radius * plasma.scale.y <= BeeShotPalette.BEE_RADII.y * 0.6, "La bala no tapa la silueta: alto %.3f m" % (halo.radius * plasma.scale.y))
		var halo_material := halo.material as StandardMaterial3D
		check(halo_material.albedo_color.a <= BeeShotPalette.HALO_ALPHA * 0.6 + 0.001, "Halo con 60 % del brillo de antes")
		check(not plasma.visible, "Recién disparada, la aguja todavía no se dibuja sobre Bee")
		check(shot.damage == 3 and is_equal_approx(shot.speed, 14.0), "Daño y velocidad de la bala Base sin cambios")
		check(is_equal_approx((shot.hitbox.get_node("CollisionShape3D").shape as SphereShape3D).radius, 0.15), "Hitbox de la bala sin cambios")
		await frames(6)
		if is_instance_valid(shot):
			check(plasma.visible, "Fuera de la silueta, la aguja se ve")

	# G. Un solo cartel de liberación; banner solo en hitos; el resto se cuenta en el HUD.
	var notices := stage.get_node("HUDNotices") if stage.has_node("HUDNotices") else preload("res://scripts/ui/bee_hud_notices.gd").for_host(stage)
	notices.pending.clear()
	notices.left = 0.0
	notices._process(0.01)
	for i in 4:
		BeeLiberation.float_text(stage, Vector3(stage.distance + float(i), 3.0, 0.0))
	check(get_nodes_in_group("bee_liberated_text").size() == 1, "Un solo LIBERADO flotante a la vez (hay %d)" % get_nodes_in_group("bee_liberated_text").size())
	check(not (notices.panel.visible and notices.active_kind == "liberated"), "Sin banner para 4 liberaciones")
	for i in 6:
		notices.note_liberated()
	check(notices.total_liberated == 10 and notices.active_kind == "liberated" and notices.label.text == HERO.MILESTONE_TEXT % 10, "El banner festeja el hito 10: '%s'" % notices.label.text)

	# E. Teletransporte: columna de un tercio de alto, más fina y tenue.
	check(is_equal_approx(TELEPORT.beam_height(), (BeeEncounterSettings_BEAM_TOP() - BeeEncounterSettings_GROUND_Y()) / 3.0), "Columna de 1/3 de alto")
	var dummy := Node3D.new()
	stage.add_child(dummy)
	dummy.global_position = Vector3(stage.distance + 3.0, 4.0, 0.0)
	var beam_effect := TELEPORT.begin(dummy, dummy.global_position, Callable())
	await frames(1)
	var beam := beam_effect.get_node("ArrivalBeam") as MeshInstance3D
	var cylinder := beam.mesh as CylinderMesh
	check(cylinder.top_radius <= 0.75 * HERO.BEAM_RADIUS_SCALE + 0.001 and (cylinder.material as StandardMaterial3D).albedo_color.a <= 0.22 * HERO.BEAM_ALPHA_SCALE + 0.001, "Columna más fina y menos opaca")
	check(absf(beam.global_position.y - 4.0) < 0.01, "La columna corta se centra en la altura de llegada")
	check(is_equal_approx(float(beam_effect.material.get_shader_parameter("density")), HERO.TELEPORT_PIXEL_DENSITY), "Nube de píxeles menos densa")
	beam_effect.force_finish()

	# C. Sombra de Bee en el suelo.
	var shadow := stage.get_node_or_null("BeeHeroShadow") as MeshInstance3D
	check(shadow != null and shadow.visible, "Bee tiene sombra en el suelo")
	if shadow != null:
		await frames(2)
		check(absf(shadow.global_position.x - bee.global_position.x) < 0.01 and shadow.global_position.y < 0.3, "La sombra sigue a Bee sobre el suelo")

	# F. Pasillo limpio: un prop delante de Bee se vuelve translúcido y después vuelve a su material.
	var corridor := stage.get_node_or_null("FlightCorridor")
	check(corridor != null and not corridor.candidates.is_empty(), "El pasillo limpio revisa decorado (%d piezas)" % (corridor.candidates.size() if corridor != null else 0))
	if corridor != null and not corridor.candidates.is_empty():
		# Busca una pieza que, con Bee en su X y a su altura (dentro del vuelo), de verdad la tape en pantalla.
		var prop: MeshInstance3D
		var box: AABB
		for candidate: MeshInstance3D in corridor.candidates:
			box = candidate.global_transform * candidate.get_aabb()
			stage.distance = box.get_center().x
			stage._update_camera_and_bounds()
			bee.global_position = Vector3(box.get_center().x, clampf(box.get_center().y, bee.flight_min.y, bee.flight_max.y), 0.0)
			var rect: Rect2 = corridor._screen_rect(stage.camera, box)
			if rect.has_point(stage.camera.unproject_position(bee.global_position)):
				prop = candidate
				break
		check(prop != null, "Hay al menos una pieza de decorado que puede tapar a Bee")
		if prop == null:
			print("TANDA_S failures=", failures)
			quit(1)
			return
		var before: Material = prop.get_active_material(0)
		corridor._clock = 0.0
		for i in 20: await process_frame
		var faded_material := prop.get_active_material(0) as ShaderMaterial
		check(corridor.faded.has(prop) and faded_material != null and faded_material.shader == corridor.FADE_SHADER, "El prop que tapa a Bee se vuelve translúcido")
		if faded_material != null and faded_material.shader == corridor.FADE_SHADER:
			check(absf(float(faded_material.get_shader_parameter("fade")) - HERO.CORRIDOR_ALPHA) < 0.02, "Queda al %d %% de opacidad" % int(HERO.CORRIDOR_ALPHA * 100))
		bee.global_position.x = box.get_center().x - 40.0
		stage.distance = bee.global_position.x
		stage._update_camera_and_bounds()
		corridor._clock = 0.0
		for i in 40: await process_frame
		check(not corridor.faded.has(prop) and prop.get_active_material(0) == before, "Sin nada detrás, vuelve a su material original")

	# Interruptor: apagado, todo vuelve al look de la Tanda R.
	HERO.HERO_LOOK_ENABLED = false
	visual.apply_model_version("v01")
	visual.apply_model_version("v02")
	check(is_equal_approx(visual_root.scale.x, BeeGameSettings.BEE_VISUAL_SCALE), "Con el interruptor apagado Bee vuelve a 1.0")
	check(BeeLiberation.max_texts() == BeeLiberation.MAX_TEXTS and is_equal_approx(BeeLevel01Framing.flight_right_offset(aspect), half * BeeLevel01Framing.PLAYABLE_WIDTH_FRACTION), "Apagado: carteles y bordes de antes")
	HERO.HERO_LOOK_ENABLED = true

	print("TANDA_S failures=", failures)
	quit(1 if failures else 0)

func BeeEncounterSettings_BEAM_TOP() -> float:
	return preload("res://scripts/game/bee_encounter_settings.gd").BEAM_TOP

func BeeEncounterSettings_GROUND_Y() -> float:
	return preload("res://scripts/game/bee_encounter_settings.gd").GROUND_Y
