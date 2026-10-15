extends SceneTree

# LOTE 14 · ETAPA 1: sustained fire (bursts of 3 / fan of 5 at 2.5 bursts/s), the 360-degree Sting (Z) and the single slow ladybird shot.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const ENEMY := preload("res://scenes/bee_prototype/wasp_enemy.tscn")


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func(): quit(1))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	var bee := stage.bee
	bee.health.damage_blocked = true
	(stage.wave as Node).set_physics_process(false) # No director: only what the test places.

	# --- Constants (configurable) -----------------------------------------------------------------------------------------
	check(is_equal_approx(bee.burst_rate, 2.5) and bee.burst_size == 3 and bee.spread_burst_size == 5, "Burst constants: 2.5/s, 3 shots, fan of 5")
	check(is_zero_approx(bee.melee_cooldown) and is_equal_approx(bee.melee_lunge_time, .22) and is_equal_approx(bee.melee_reach_factor, 1.6), "Sting constants: 0.9 s recharge, 0.2 s lunge, reach 1.6 Bee lengths")
	check(bee.melee_damage == 3 * bee.base_shot_damage, "Sting damage must be 3 base shots (%d)" % bee.melee_damage)

	# --- Sustained fire: Base ---------------------------------------------------------------------------------------------
	bee.set_physics_process(true)
	bee.global_position = Vector3(0, 3.4, 0)
	var shots_before := bee.shots_fired
	Input.action_press("throw_orange")
	await frames(3)
	check(bee.shots_fired == shots_before + 1, "A tap shoots one shot at once")
	Input.action_release("throw_orange")
	await frames(10)
	check(bee.burst_count == 0, "A quick tap never starts a burst")
	var shot_damage := {}
	Input.action_press("throw_orange")
	var t0 := bee.burst_shots
	var bursts0 := bee.burst_count
	await frames(120) # 2 s at 60 fps
	Input.action_release("throw_orange")
	var bursts := bee.burst_count - bursts0
	var burst_shots := bee.burst_shots - t0
	print("TANDA4A hold base: %d bursts, %d automatic shots in 2.0 s (interval %.4f s)" % [bursts, burst_shots, BeePlayer.SHOOTING.FIRE_INTERVAL])
	check(bursts == 0, "Continuous Base fire creates no bursts")
	check(burst_shots >= 23 and burst_shots <= 24, "Base fires ~12 evenly timed shots/s (%d in 2 s)" % burst_shots)
	var held_shots := bee.shots_fired
	await frames(40)
	check(bee.shots_fired == held_shots, "Releasing the button stops the fire")
	var base_dps_hold := float(BeePlayer.SHOOTING.WEAPON_MODES[&"base"]["damage"][0]) / BeePlayer.SHOOTING.FIRE_INTERVAL
	check(is_equal_approx(base_dps_hold, 36.0), "Base sustained DPS increases 20% to 36")

	# --- Sustained fire: Spread -------------------------------------------------------------------------------------------
	for node in stage.get_children():
		if node is BeeEnergyProjectile:
			node.queue_free()
	await frames(2)
	bee.collect_spread()
	var ammo := bee.spread_ammo
	Input.action_press("throw_orange")
	await frames(3)
	var ammo_after_tap := bee.spread_ammo
	await frames(4)
	var before_burst := bee.spread_ammo
	check(absf(ammo_after_tap - (ammo - 3.0 / 60.0)) < 0.04, "A Spread tap consumes time only")
	await frames(30)
	var pellets: Array = []
	for node in stage.get_children():
		if node is BeeEnergyProjectile:
			pellets.append(node)
	Input.action_release("throw_orange")
	check(bee.spread_ammo < before_burst, "Spread continues counting time during a burst (%d -> %d)" % [before_burst, bee.spread_ammo])
	var angles := {}
	for p in pellets:
		angles[snappedf(rad_to_deg(atan2((p as BeeEnergyProjectile).travel_direction.y, (p as BeeEnergyProjectile).travel_direction.x)), 1.0)] = true
	print("LOTE14 spread fan angles: ", angles.keys())
	check(angles.size() >= 3, "Spread sustained fire retains the same three-pellet fan (angles %s)" % str(angles.keys()))
	var spread_hold_dps := 5.0 / BeePlayer.SHOOTING.SPREAD_FIRE_INTERVAL
	check(is_equal_approx(spread_hold_dps, 60.0), "Triple nominal DPS is 60")
	bee.spread_ammo = 0
	for node in stage.get_children():
		if node is BeeEnergyProjectile:
			node.queue_free()

	# --- Sting: 360 degrees, nearest target -------------------------------------------------------------------------------
	bee.set_physics_process(true)
	var reach := bee.melee_reach()
	check(is_equal_approx(reach, 1.6 * BeePlayer.BEE_LENGTH), "Reach is 1.6 Bee lengths")
	var behind := ENEMY.instantiate() as WaspEnemy
	var front := ENEMY.instantiate() as WaspEnemy
	var far := ENEMY.instantiate() as WaspEnemy
	for w in [behind, front, far]:
		stage.add_child(w)
		(w as Node).set_physics_process(false)
	bee.global_position = Vector3(0, 3.4, 0)
	bee.facing_x = 1.0
	behind.global_position = bee.global_position + Vector3(-reach * 0.7, 0.1, 0)
	front.global_position = bee.global_position + Vector3(reach * 0.95, 0, 0)
	far.global_position = bee.global_position + Vector3(reach + 0.8, 0, 0)
	for w in [behind, front, far]:
		(w as WaspEnemy).activate(bee)
		(w as Node3D).add_to_group("bee_auto_aim_targets")
		(w as Node).set_physics_process(false)
	await frames(3)
	check(bee.nearest_melee_target() == behind, "The nearest enemy (behind Bee) is the sting target")
	var hp_behind := behind.health.current_health
	var x0 := bee.global_position.x
	check(bee.start_melee(), "Z accepted")
	check(not bee.start_melee(), "Z is on cooldown right after")
	await frames(5)
	check(bee.stinger == null and not bee.has_node("ChromeStinger"), "T4g has no chrome cone")
	await frames(14)
	check(bee.global_position.x < x0 - 0.3, "Bee lunges backwards towards the target (x %.2f -> %.2f)" % [x0, bee.global_position.x])
	check(behind.health.current_health == hp_behind - bee.melee_damage or behind.is_defeated(), "The enemy behind took the sting damage (%d -> %d)" % [hp_behind, behind.health.current_health])
	check(front.health.current_health == front.health.max_health and far.health.current_health == far.health.max_health, "Only the nearest enemy is hit")
	check(bee.facing_x < 0.0, "Bee turns towards the target")
	await frames(3)
	check(bee.melee_ready_ratio() == 1.0, "Sting has no charge meter")
	await frames(12)
	check(bee.melee_ready_ratio() >= 1.0, "Sting ready after 0.9 s (AGUIJÓN LISTO)")
	check(bee.stinger == null, "No stinger visual after the punch")
	# Nothing within reach: forward swing as before.
	behind.queue_free()
	front.global_position = bee.global_position + Vector3(reach + 1.5, 0, 0)
	bee.facing_x = 1.0
	await frames(2)
	check(bee.nearest_melee_target() == null, "Nothing in reach beyond %.2f m (got %s at %s, bee %s)" % [reach, str(bee.nearest_melee_target()), str(bee.nearest_melee_target().global_position) if bee.nearest_melee_target() else "-", str(bee.global_position)])
	check(bee.start_melee() and bee.melee_target == null, "With nothing in reach the sting is a forward swing")

	# --- Ladybird: ONE slow shot ------------------------------------------------------------------------------------------
	check(not ("Ladybird" in BeeImplantShooter.FAN_FAMILIES), "The ladybird no longer fans 3 shots")
	check(float(BeeImplantShooter.COOLDOWN_BY_FAMILY["Ladybird"]) >= 5.0, "The ladybird pauses longer between shots")
	check(float(BeeImplantShooter.SPEED_BY_FAMILY["Ladybird"]) < BeeImplantShooter.SHOT_SPEED, "The ladybird shot is slower")
	print("BEE_LOTE14_CONTROLS_V01_OK")
	quit(0)
