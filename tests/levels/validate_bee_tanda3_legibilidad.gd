extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	var plain := BeeShotPalette.plasma(true)
	var plain_core := plain.get_node("Core") as MeshInstance3D
	var plain_body := plain.get_node("Halo") as MeshInstance3D
	check(plain_core.position == Vector3.ZERO and plain_body.position == Vector3.ZERO, "Generic shot layers keep their restored positions")
	check(((plain.get_node("Outer") as MeshInstance3D).mesh as PrimitiveMesh).material.albedo_color.is_equal_approx(Color(BeeShotPalette.ENEMY_SHOT_RIM, BeeShotPalette.OUTER_ALPHA)), "Generic shot keeps its restored violet translucent rim")
	plain.free()
	# Rendering changes must keep the existing tuned shot radii, damage and movement.
	var radii := {&"stinger": 0.12, &"acid": 0.13, &"web": 0.16, &"pebble": 0.14, &"bubble": 0.24, &"spore": 0.15, &"pellet": 0.10, &"seed": 0.12, &"stone": 0.18, &"mud": 0.15, &"bile": 0.16}
	for style in radii:
		var shot := preload("res://scenes/projectiles/toon/alien_bolt.tscn").instantiate() as AlienEnemyProjectile
		shot.set_meta("shot_style", style)
		shot.damage = 5
		shot.speed = 13.0
		shot.gravity = 1.0
		shot.set_physics_process(false)
		root.add_child(shot)
		await process_frame
		check(shot.has_node(BeeShotStyles.PLASMA_NAME), "%s receives its restored family style" % style)
		var body := shot.get_node(BeeShotStyles.PLASMA_NAME) as Node3D
		check(body.find_children("DangerBorder", "MeshInstance3D", true, false).is_empty(), "%s has no T3 dark shell" % style)
		check(((body.get_node("Core") as MeshInstance3D).mesh as PrimitiveMesh).material.albedo_color.is_equal_approx(BeeShotStyles.CORE_COLOR), "%s keeps its original small cyan core" % style)
		check(is_equal_approx((shot.get_node("Hitbox3D/CollisionShape3D").shape as SphereShape3D).radius, radii[style]), "%s keeps its tuned collision radius" % style)
		check(shot.damage == 5 and shot.speed == 13.0 and shot.gravity == 1.0, "%s keeps damage, speed and gravity" % style)
		shot.free()
	var garden := stage.get_node("LivingGarden") as BeeLevel01LivingGarden
	var foreground := stage.get_node("Foreground") as BeeLevel01Foreground
	var fx := stage.get_node("AmbientFx") as BeeLevel01AmbientFx
	# Four nearby threats saturate the visual pressure without changing any gameplay node.
	var threats: Array[Node3D] = []
	for i in 4:
		var target := Node3D.new()
		stage.add_child(target)
		target.global_position = stage.camera.global_position
		target.add_to_group("bee_auto_aim_targets")
		threats.append(target)
	check(BeeGameSettings.presentation_combat_intensity(stage) == 1.0, "Nearby combat saturates environmental pressure")
	garden._process(1.0)
	foreground._process(1.0)
	fx._process(1.0)
	check(garden.leaves.amount == 2 and garden.pollen.amount == 8, "Combat reduces leaf and mote budgets")
	check(garden.leaves.global_position.z + garden.leaves.emission_box_extents.z < -5.0, "Combat leaves stay behind the action plane")
	check((garden.leaves.mesh.surface_get_material(0) as StandardMaterial3D).albedo_color.a <= 0.19, "Combat leaves are faint")
	check(fx.dew.amount_ratio < 0.2, "GPU ambience shares the combat budget")
	check(float((foreground.layers[0].multimesh.mesh.material as ShaderMaterial).get_shader_parameter("fade")) < 0.10, "Foreground grass fades during combat")
	for threat in threats:
		threat.free()
	garden.apply_combat_budget(0.0)
	check(garden.leaves.amount == 6 and garden.pollen.amount == 42, "Calm restores the full atmosphere")
	var light := stage.get_node("LightProgression") as BeeLevel01LightProgression
	var env := (stage.get_node("WorldEnvironment") as WorldEnvironment).environment
	light.apply_distance(0.0)
	var day_fog := env.fog_density
	check(env.adjustment_contrast > 1.0 and env.fog_sky_affect < 0.2, "Day gains contrast and loses the pale sky veil")
	light.apply_distance(290.0)
	check(env.fog_density > day_fog and is_equal_approx(env.adjustment_contrast, 1.0), "Dusk retains its established palette")
	var water := stage.get_node("WateringEvent") as BeeLevel01WateringEvent
	water._spawn_column(stage.camera.global_position.x)
	var column: Dictionary = water.columns.back()
	check((column["mark"] as Node).has_node("WarningBorder"), "Watering warning has a clear ground border")
	water._update_column(column, 0.99)
	check(not (column["hitbox"] as DamageHitbox3D).enabled, "Water remains harmless during its first warning second")
	water._update_column(column, 0.02)
	check((column["hitbox"] as DamageHitbox3D).enabled and (column["hitbox"] as DamageHitbox3D).damage == 5, "Water still deals five damage after the warning")
	water._clear()
	stage.queue_free()
	await process_frame
	print("TANDA3_LEGIBILIDAD failures=", failures)
	quit(1 if failures else 0)
