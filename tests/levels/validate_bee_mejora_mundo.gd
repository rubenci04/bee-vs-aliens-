extends SceneTree
# Mejora visual: el mundo por zonas se construye bien y es solo presentación. También: el liberado queda opaco (bug de las siluetas negras),
# Bee a 1,40 sin agrandar su hurtbox, pirueta con respiro y robot de ojo amarillo.
const W := preload("res://scripts/game/bee_world_settings.gd")
const HERO := preload("res://scripts/game/bee_hero_look_settings.gd")
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const RELEASE := preload("res://scripts/vfx/bee_release_animation.gd")

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
	check(not W.world_active(), "sin ventana el mundo no se construye: los tests miden el jardín de siempre")
	W.force_in_headless = true
	var stage = LEVEL.instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 6:
		await physics_frame
	var world := stage.get_node_or_null("World") as BeeLevel01World
	check(world != null, "el mundo se construye con force_in_headless")
	check(world.tufts.size() > 8, "hay pasto")
	check(world.life_meshes.size() > 10, "hay decorado horneado")
	check(world.find_children("*", "CollisionShape3D", true, false).is_empty(), "el mundo no tiene colisiones")
	check(world.find_children("*", "Area3D", true, false).is_empty(), "el mundo no tiene áreas")
	check(world.find_children("*", "PhysicsBody3D", true, false).is_empty(), "el mundo no tiene cuerpos")
	var progression := stage.get_node("LightProgression") as BeeLevel01LightProgression
	check(progression.external_light, "la luz la maneja el mundo")
	# Nada alto en la banda del plano de vuelo: lo que está cerca en profundidad no tapa a Bee.
	for mesh in world.life_meshes:
		var box: AABB = mesh.mesh.get_aabb()
		if str(mesh.name).begins_with("Canopy"):
			check(box.position.y > BeeLevel01Framing.top_y() - 3.0, "el techo de hojas queda arriba de la zona de vuelo")
	# Cada zona se ve distinta: cielo y suelo cambian en el recorrido.
	var seen := {}
	for x in [20.0, 130.0, 230.0, 280.0, 315.0, 350.0]:
		seen[str(W.light_at(x)["sky_top"])] = true
	check(seen.size() == 6, "seis cielos distintos a lo largo del nivel")
	check(W.zone_at(10.0) == 0 and W.zone_at(100.0) == 1 and W.zone_at(200.0) == 2 and W.zone_at(280.0) == 3 and W.zone_at(320.0) == 4, "zonas en orden")
	# Decisiones ya tomadas.
	check(is_equal_approx(HERO.BEE_VISUAL_SCALE, 1.4), "Bee se dibuja a 1,40")
	check(is_equal_approx(stage.bee.get_node("VisualRoot").scale.x, 1.4), "Bee en el nivel a 1,40")
	check(stage.bee.roll_cooldown > stage.bee.roll_duration and stage.bee.roll_cooldown <= 0.7, "pirueta casi siempre disponible, pero con respiro")
	# Bug de las siluetas negras: el material del liberado no pasa al paso transparente.
	var release = RELEASE.new()
	var material := ShaderMaterial.new()
	material.shader = BeeToonStyle.TOON
	material.next_pass = BeeToonStyle.shared_outline(BeeToonStyle.OUTLINE_ACTOR)
	var faded: ShaderMaterial = release.fade_material(material)
	check(not "ALPHA = liberation_alpha" in faded.shader.code, "el cuerpo del liberado sigue opaco (ALPHA dibujaba el contorno encima)")
	check("discard" in faded.shader.code, "el desvanecido es por puntos")
	check(not "ALPHA = liberation_alpha" in (faded.next_pass as ShaderMaterial).shader.code, "el contorno del liberado sigue opaco")
	release.free()
	# El ojo del robot es amarillo y encendido.
	var robot = preload("res://scenes/levels/walker_miniboss.tscn").instantiate()
	stage.add_child(robot)
	await physics_frame
	var eye_ok := false
	for mesh: MeshInstance3D in robot.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.mesh.surface_get_material(surface)
			if source != null and source.resource_name == "Eye":
				var active := mesh.get_active_material(surface) as ShaderMaterial
				var color: Color = active.get_shader_parameter("albedo")
				eye_ok = color.r > 0.9 and color.g > 0.7 and color.b < 0.3 and float(active.get_shader_parameter("emission_energy")) > 1.0
	check(eye_ok, "el ojo del robot es amarillo y brilla")
	W.force_in_headless = false
	if failures == 0:
		print("PASS validate_bee_mejora_mundo")
	quit(1 if failures > 0 else 0)
