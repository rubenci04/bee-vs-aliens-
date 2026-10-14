extends SceneTree
const SETTINGS := preload("res://scripts/game/bee_shooting_settings.gd")
var stage: BeeShmupStage

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func target_at(at: Vector3, weak := false) -> Node3D:
	var target := Node3D.new()
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	target.add_child(health)
	var hurt := DamageHurtbox3D.new()
	hurt.name = "Hurtbox3D"
	hurt.team_id = &"alien"
	hurt.collision_layer = 2
	hurt.collision_mask = 0
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.02
	collider.shape = sphere
	hurt.add_child(collider)
	if weak:
		hurt.damage_multiplier = 2.0
	target.add_child(hurt)
	stage.add_child(target)
	target.global_position = at
	target.add_to_group("bee_auto_aim_targets")
	return target

func run() -> void:
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.global_position = Vector3(stage.camera.global_position.x - 2, 3.5, 0)
	bee.health.damage_blocked = true
	# Manual cone, nearest, priority, excluded invulnerable and off-screen targets.
	var origin := bee.firing_origin()
	bee.set_aim_point(origin + Vector3.RIGHT * 5)
	var near := target_at(origin + Vector3.RIGHT.rotated(Vector3.BACK, deg_to_rad(8.0)) * 2)
	var weak := target_at(origin + Vector3.RIGHT.rotated(Vector3.BACK, deg_to_rad(10.0)) * 3, true)
	var outside := target_at(origin + Vector3.RIGHT.rotated(Vector3.BACK, deg_to_rad(25.0)) * 1)
	var direction := bee.aim_direction()
	check(bee.aim_assist_target == weak, "Vulnerable implant takes priority inside the cone")
	check(absf(rad_to_deg(atan2(direction.y, direction.x)) - 5.0) < 0.1, "Soft correction is half of the 10-degree offset")
	(weak.get_node("HealthComponent") as HealthComponent).damage_blocked = true
	bee.aim_direction()
	check(bee.aim_assist_target == near, "Invulnerable targets are never assisted")
	weak.global_position.x += 100
	(weak.get_node("HealthComponent") as HealthComponent).damage_blocked = false
	bee.aim_direction()
	check(bee.aim_assist_target == near, "Off-screen target is never selected")
	near.position = origin + Vector3.RIGHT.rotated(Vector3.BACK, deg_to_rad(-8.0)) * 2
	check(bee.aim_direction().y < 0, "Lower target gets downward correction")
	for target in [near, weak, outside]:
		target.free()
	check(bee.aim_direction().is_equal_approx(Vector3.RIGHT), "Empty cone leaves manual aim untouched")
	# All devices use the same held action, RT mapping included.
	var rt := false
	for event in InputMap.action_get_events("throw_orange"):
		if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT:
			rt = true
	check(rt, "RT remains bound to the shared firing action")
	Input.action_press("throw_orange")
	bee._fire_cooldown = 0.0
	var before := bee.shots_fired
	bee._try_input_fire()
	for i in 120:
		bee._update_sustained_fire(1.0 / 60.0)
	check(bee.shots_fired - before == 16, "Immediate shot plus 15 uniform automatic rounds in two seconds")
	check(bee._burst_left == 0 and bee.burst_count == 0, "Automatic fire has no queued three-round bursts")
	Input.action_release("throw_orange")
	before = bee.shots_fired
	for i in 60:
		bee._update_sustained_fire(1.0 / 60.0)
	check(bee.shots_fired == before, "Release cancels fire immediately")
	# Reticle follows the actual corrected muzzle ray, with/without manual input.
	var crosshair := stage.get_node("CanvasLayer/Crosshair") as BeeLevel01Crosshair
	bee.clear_aim()
	bee.refresh_auto_aim()
	crosshair._process(0.0)
	check(crosshair.visible, "Idle reticle stays visible")
	var screen_origin := stage.camera.unproject_position(bee.firing_origin())
	var screen_ray := stage.camera.unproject_position(bee.firing_origin() + bee.aim_direction()) - screen_origin
	var reticle_ray := crosshair.aim_screen_point() - screen_origin
	check(absf(screen_ray.normalized().cross(reticle_ray.normalized())) < 0.01, "Reticle lies on the real firing direction")
	check(not bee.aim_debug_enabled, "Aim debug is off by default")
	var debug_key := InputEventKey.new()
	debug_key.keycode = SETTINGS.AIM_DEBUG_KEY
	debug_key.pressed = true
	bee._unhandled_input(debug_key)
	check(bee.aim_debug_enabled, "F4 enables cone/selected-target debug")
	bee._unhandled_input(debug_key)
	check(not bee.aim_debug_enabled, "F4 disables debug again")
	# Shape resources are per-instance: 0.12 -> 0.15 m, damage remains 10.
	var shot_scene := preload("res://scenes/levels/bee_level_toon_bolt.tscn")
	for i in 2:
		var shot := shot_scene.instantiate() as BeeEnergyProjectile
		check(is_equal_approx(shot.get_node("Hitbox3D/CollisionShape3D").shape.radius, 0.12), "Packed source collision stays 0.12")
		stage.add_child(shot)
		check(is_equal_approx(shot.hitbox.get_node("CollisionShape3D").shape.radius, 0.15), "Bee shot damage radius is enlarged exactly 25% once")
		check(shot.damage == 10, "Damage per normal projectile remains 10")
		shot.free()
	# Physical near miss that the old radius (0.12 + target 0.02 < 0.16) could not hit.
	for node in stage.get_children():
		if node is BeeEnergyProjectile:
			node.queue_free()
	await physics_frame
	var from := Vector3(stage.camera.global_position.x + 1.0, 3.5, 0)
	var grazing := target_at(from + Vector3(0.5, 0.16, 0))
	var enlarged := shot_scene.instantiate() as BeeEnergyProjectile
	stage.add_child(enlarged)
	enlarged.global_position = from
	enlarged.launch(Vector3.RIGHT, bee)
	for i in 8:
		await physics_frame
	check((grazing.get_node("HealthComponent") as HealthComponent).current_health == 90, "The 25% larger damage shape hits a real glancing overlap once for unchanged 10 damage")
	grazing.free()
	print("TANDA4A_OK manual cone/priority/visibility, uniform fire/release, RT mapping, idle real-direction reticle/F4, isolated +25% hitbox; DPS Base=30 Spread=50")
	quit(0)
