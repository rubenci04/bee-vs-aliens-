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

func projectiles() -> Array:
	return stage.get_children().filter(func(node): return node is BeeEnergyProjectile and not node.is_queued_for_deletion())

func run() -> void:
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	var original_hp := bee.health.current_health
	for state in [[0.0, 0.0, &"base", 36.0], [0.0, 6.0, &"double", 48.0], [20.0, 0.0, &"triple", 60.0], [20.0, 6.0, &"triple_double", 72.0]]:
		for shot in projectiles():
			shot.free()
		bee.spread_ammo = state[0]
		bee.honey_left = state[1]
		check(bee.weapon_mode() == state[2], "Existing power-up combination resolves its configured mode")
		var first := bee.fire()
		var shots := projectiles()
		var profile := bee.weapon_profile()
		check(shots.size() == profile["damage"].size(), "Same volley count for tap and held mode")
		var total := 0
		for shot: BeeEnergyProjectile in shots:
			total += shot.damage
			check(shot.speed == 14.0 and shot.hitbox.damage == shot.damage, "Configured speed/damage reaches the physical projectile")
			check(is_equal_approx(shot.hitbox.get_node("CollisionShape3D").shape.radius, 0.15), "Existing hitbox scale unchanged")
			check(is_equal_approx(shot.get_node("PlasmaBall").scale.x, SETTINGS.SHOT_VISUAL_LENGTH), "Longer plasma only scales visual node")
			check(is_equal_approx(shot.trail.lifetime, SETTINGS.SHOT_TRAIL_SECONDS), "Actual game trail uses configured duration")
		check(is_equal_approx(total / float(profile["interval"]), state[3]), "Real volley produces audited nominal DPS")
		check(first.damage == 3, "Center shot never becomes weaker than Base")
		Input.action_press("throw_orange")
		bee._fire_cooldown = 0.0
		var count := bee.shots_fired
		bee._try_input_fire()
		for tick in 120:
			bee._update_sustained_fire(1.0 / 60.0)
		check(bee.shots_fired - count == 25, "Every mode fires immediately plus 24 rounds in two seconds")
		Input.action_release("throw_orange")
		count = bee.shots_fired
		bee._update_sustained_fire(1.0)
		check(bee.shots_fired == count, "Release stops every mode")
	bee.spread_ammo = 0.0
	bee.honey_left = 0.0
	check(bee.weapon_mode() == &"base" and bee.health.current_health == original_hp, "Expiration returns to Base without changing Bee HP")
	# Physical enemy impact: use the real projectile/hit signal and verify the extra spark.
	for shot in projectiles():
		shot.free()
	var victim := preload("res://scenes/bee_prototype/wasp_enemy.tscn").instantiate() as Node3D
	stage.add_child(victim)
	victim.call("activate", bee)
	victim.set_physics_process(false)
	victim.global_position = bee.firing_origin() + Vector3(1.0, 0, 0)
	var hp := int(victim.get_node("HealthComponent").current_health)
	bee.set_aim_point(victim.global_position)
	var hit := bee.fire()
	var hurt := victim.get_node("Hurtbox3D") as DamageHurtbox3D
	hit.hitbox.hit_confirmed.emit(hurt, 3)
	check(int(victim.get_node("HealthComponent").current_health) == hp, "Visual impact callback never applies extra damage")
	var spark_found := false
	for vfx in get_nodes_in_group("bee_combat_vfx"):
		if vfx.kind == &"bee_spark":
			spark_found = true
	check(spark_found, "Existing spark effect appears on enemy impact")
	var crosshair := stage.get_node("CanvasLayer/Crosshair") as BeeLevel01Crosshair
	bee.aim_assist_target = victim
	bee.aim_debug_enabled = false
	check(SETTINGS.AIM_ASSIST_TARGET_MARKER and crosshair.target_marker_screen_point().is_finite(), "Discreet target marker exists even with F4 off")
	victim.get_node("HealthComponent").damage_blocked = true
	check(not crosshair.target_marker_screen_point().is_finite(), "Marker excludes invulnerable target")
	# Existing small enemies used to force every non-Spread hit to at least 10.
	# The explicit weapon profile must also control the real damage, not just the exported value.
	victim.get_node("HealthComponent").damage_blocked = false
	victim.set_meta("small_enemy_base_hit_damage", 10)
	hurt.weak_point = null
	hurt.damage_multiplier = 1.0
	var configured := bee.fire()
	var before_hp := int(victim.get_node("HealthComponent").current_health)
	check(hurt.receive_hit(configured.hitbox) == 3 and int(victim.get_node("HealthComponent").current_health) == before_hp - 3, "Explicit profile overrides historical 10-damage floor without changing enemy HP")
	stage.wave._spawn({"family": "FlyCommon", "slot": 0, "event": 904, "hard": false})
	var fly := stage.wave.active_units.back() as Node3D
	preload("res://tests/levels/bee_teleport_fixture.gd").finish(fly)
	fly.set_physics_process(false)
	var fly_health := fly.get_node("HealthComponent") as HealthComponent
	var fly_hp := int(BeeGameSettings.ENEMY_HEALTH.COMMON_HP["FlyCommon"])
	check(fly_health.max_health == fly_hp, "Real Normal roster FlyCommon uses the health table")
	var body := fly.get("body_hurtbox") as DamageHurtbox3D
	check(body != null, "Real fly has its existing body damage area")
	for impact in ceili(float(fly_hp)/3):
		var body_shot := bee.fire()
		body_shot.hitbox.ignores_weak_points = true # Isolate body damage from the existing 2x implant reward.
		body.receive_hit(body_shot.hitbox)
		check(fly_health.current_health == maxi(0, fly_hp - 3 * (impact + 1)), "Real fly receives exactly configured body damage until liberation")
	print("TANDA4C_OK real modes/DPS, 12Hz all modes/release, hitbox/HP invariant, longer plasma/trail, impact spark without extra damage, target marker without F4")
	quit(0)
