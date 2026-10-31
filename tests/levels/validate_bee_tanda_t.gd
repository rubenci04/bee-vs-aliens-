extends SceneTree
## Tanda T: arranque y ritmo. Sin sólidos invisibles en el arranque, bombas llenas, potenciadores en su lugar (triple
## antes de cada grupo de moscas, primera bomba temprana, una sola recarga antes de la tarántula), tres flores de polen,
## hilos de la tarántula en el techo y música de zona / vuelta al tema del nivel.
const FIX := preload("res://scripts/game/bee_flow_fix_settings.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func frames(n: int) -> void:
	for i in n: await physics_frame

func pickups(stage: Node, kind: int) -> Array[float]:
	var xs: Array[float] = []
	for p: BeePowerupPickup in stage.find_children("*", "BeePowerupPickup", true, false):
		if p.kind == kind and not p.is_queued_for_deletion():
			xs.append(p.global_position.x)
	xs.sort()
	return xs

func run() -> void:
	root.size = Vector2i(1280, 720)
	check(FIX.ENABLED, "Los arreglos de la Tanda T vienen encendidos")
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.wave.set_physics_process(false)
	var bee := stage.bee

	# 1. Ningún sólido sin dibujo en el plano de vuelo del arranque: Bee cruza X=41 y X=55 volando bajo.
	for solid_name in FIX.INVISIBLE_SOLIDS:
		for shape: CollisionShape3D in stage.get_node(str(solid_name)).find_children("*", "CollisionShape3D", false, false):
			check(shape.disabled, "%s/%s ya no choca" % [solid_name, shape.name])
	var moments := stage.get_node("DirectorMoments") as BeeLevel01Moments
	check(moments.impact_surfaces.is_empty(), "El tronco invisible tampoco frena disparos")
	bee.health.damage_blocked = true
	stage.set_physics_process(false)
	bee.flight_min = Vector2(-20, 0.7)
	bee.flight_max = Vector2(400, 7.2)
	bee.global_position = Vector3(38.0, 2.2, 0.0) # Sobre la caja visible de X=43 (1,6 m); antes la botella invisible tapaba hasta 3,9 m.
	var reached := false
	for i in 300:
		bee.velocity = Vector3(bee.horizontal_speed, 0.0, 0.0)
		bee.move_and_slide()
		await physics_frame
		if bee.global_position.x >= 58.0:
			reached = true
			break
	check(reached and bee.global_position.y < 2.5, "Bee pasa volando bajo de X=38 a X=58 sin chocar (llegó a %.1f, altura %.2f)" % [bee.global_position.x, bee.global_position.y])
	stage.set_physics_process(true)

	# 2. Bombas llenas al empezar.
	check(bee.bomb_charges == bee.max_bomb_charges, "La barra de bombas arranca llena (%d/%d)" % [bee.bomb_charges, bee.max_bomb_charges])

	# 3. Potenciadores.
	var spreads := pickups(stage, BeePowerupPickup.Kind.SPREAD)
	var bombs := pickups(stage, BeePowerupPickup.Kind.BOMB)
	for group_x in [1.5, 100.0, 138.0, 198.0]: # Grupos de moscas: arranque, moscas verdes, zona de la nube, serie de moscas verdes.
		var before := spreads.filter(func(x: float): return x <= group_x + 8.0 and x >= group_x - 16.0)
		check(not before.is_empty(), "Hay un triple justo antes de las moscas de X=%.0f" % group_x)
	check(not bombs.is_empty() and bombs[0] <= 100.0, "La primera bomba aparece temprano (X=%.0f)" % (bombs[0] if not bombs.is_empty() else -1.0))
	var preboss := bombs.filter(func(x: float): return x > 270.0)
	check(preboss.size() == 1, "Antes de la tarántula hay una sola recarga de bombas (hay %d)" % preboss.size())

	# 4. Tres flores de polen distintas, todas sueltan polen; el tallo de las nuevas no es cian.
	var garden := stage.get_node("GardenMushrooms") as BeeLevel01GardenMushrooms
	var kinds := {}
	for m in garden.mushrooms:
		if m.kind in BeeGardenMushroom.POLLEN_KINDS:
			kinds[m.kind] = true
	check(kinds.size() == FIX.POLLEN_FLOWER_CYCLE.size(), "Hay %d tipos de flor de polen (%s)" % [kinds.size(), str(kinds.keys())])
	for m in garden.mushrooms:
		if m.kind == &"flower_purple":
			for mesh: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
				for s in mesh.mesh.get_surface_count():
					var material := mesh.get_active_material(s) as ShaderMaterial
					if material != null and material.get_shader_parameter("albedo") is Color:
						check(not BeeToonStyle.is_cyan(material.get_shader_parameter("albedo")), "El tallo de la flor violeta no es cian")
			var drops_before := stage.find_children("*", "BeePollenPickup", true, false).size()
			m.health.take_damage(9999)
			await frames(3)
			check(stage.find_children("*", "BeePollenPickup", true, false).size() > drops_before, "La flor violeta suelta polen")
			break

	# 5. Tarántula en el techo: hilos visibles que suben más arriba del borde de la pantalla.
	stage.distance = 340.0
	stage._update_camera_and_bounds()
	stage.wave._start_tarantula()
	var spider := stage.wave.tarantula as TarantulaBoss01
	spider.set_physics_process(false)
	var silk := spider.get_node_or_null("CeilingSilk")
	check(silk != null, "La tarántula tiene hilos de techo")
	if silk != null:
		spider.mode = &"ceiling"
		spider._flip = PI
		spider.global_position = Vector3(stage.distance, spider._ceiling_y(), 0.0)
		spider._apply_pose()
		for i in 30: await process_frame
		var strands: Array = silk.strands
		check(strands.size() == FIX.CEILING_SILK_LEG_X.size() and (strands[0] as MeshInstance3D).visible, "Los hilos se ven en el techo")
		var top_end := (strands[0] as MeshInstance3D).global_position.y + 0.5 * (strands[0] as MeshInstance3D).scale.x
		check(top_end >= BeeLevel01Framing.top_y(), "El hilo llega hasta arriba del borde de la pantalla (%.2f vs %.2f)" % [top_end, BeeLevel01Framing.top_y()])
		spider.mode = &"ground"
		await create_timer(0.6, true, false, true).timeout
		check(not (strands[0] as MeshInstance3D).visible, "En el suelo no hay hilos de techo")

	# 6. Música: zona -> tema de acción fuerte; despejada / robot vencido -> tema del nivel.
	var manager := root.get_node_or_null("MusicManager")
	if manager != null:
		BeeMusic.zone()
		check(manager.current_track == &"zone", "En la zona suena el tema de acción fuerte")
		BeeMusic.back_to_level()
		check(manager.current_track == &"level", "Al despejar vuelve el tema del nivel")
	else:
		print("TANDA_T sin MusicManager: la parte de música no se pudo medir")

	print("TANDA_T failures=", failures)
	quit(1 if failures else 0)
