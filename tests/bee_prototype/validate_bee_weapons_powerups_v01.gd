extends SceneTree

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const PICKUP := preload("res://scenes/bee_prototype/bee_powerup_pickup.tscn")
const REVIEW := "res://dev/weapons_powerups_review/"
var stage: BeeShmupStage
var bee: BeePlayer
var hud: Control
## GARDEN IDENTITY 04: the run used to end with quit(0) even after a failed check (quit(1) only requests the exit),
## which hid a stale expectation since REBUILD 02. Any failure now keeps the exit code at 1.
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW + name + ".png") == OK, "Capture " + name)

func shots() -> Array[BeeEnergyProjectile]:
	var result: Array[BeeEnergyProjectile] = []
	for child in stage.get_children():
		if child is BeeEnergyProjectile and not child.is_queued_for_deletion():
			result.append(child)
	return result

func clear_shots() -> void:
	for shot in shots():
		shot.queue_free()
	await frames(2)

func touch_pickup(path: String) -> void:
	var pickup: BeePowerupPickup = stage.get_node(path)
	bee.global_position = pickup.global_position
	await frames(4)
	check(not stage.has_node(path), "Physical collection failed: " + path)

func enemy(scene: PackedScene, point: Vector3) -> Node3D:
	var unit := scene.instantiate() as Node3D
	stage.add_child(unit)
	unit.global_position = point
	check(unit.call("activate", bee), "Enemy activation failed")
	unit.set_physics_process(false) # Isolate weapon damage from unrelated attacks.
	return unit

func sample_performance(stress: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await frames(30)
	var started := Time.get_ticks_usec()
	var last := started
	var worst_ms := 0.0
	var peak_nodes := 0
	for i in 180:
		if stress and i % 18 == 0:
			bee.fire()
		if stress and i == 60:
			bee.use_bomb()
		await process_frame # Render sampling must not be capped by physics ticks.
		var now := Time.get_ticks_usec()
		worst_ms = maxf(worst_ms, float(now - last) / 1000.0)
		last = now
		peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("WEAPONS_PERFORMANCE stress=", stress, " frames=180 mean_fps=", 180000000.0 / float(last - started), " worst_ms=", worst_ms, " peak_nodes=", peak_nodes)

func run() -> void:
	create_timer(90.0, true, false, true).timeout.connect(func(): quit(1))
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	bee = stage.bee
	bee.set_physics_process(false)
	bee.flight_min = Vector2(-20, 0.7)
	bee.flight_max = Vector2(400, 7.2)
	hud = stage.get_node("CanvasLayer/WeaponsHUD")
	check(InputMap.has_action("bee_bomb"), "Bomb action missing")
	var mapped_c := false
	for event in InputMap.action_get_events("bee_bomb"):
		if event is InputEventKey and event.physical_keycode == KEY_C:
			mapped_c = true
	check(mapped_c and bee.bomb_charges == 1 and bee.spread_ammo == 0, "Initial kit/input wrong")
	check("BASE" in hud.get_node("State").text and "BOMB x1" in hud.get_node("State").text, "Initial HUD wrong")
	await capture("07_hud_base")
	var base := bee.fire()
	check(base != null and base.damage == 10 and base.hitbox.damage == 10 and shots().size() == 1, "Base shot altered")
	check(base.speed == 14.0 and base.lifetime == 1.4 and bee.shots_fired == 1, "Base cadence/projectile contract altered")
	check(base.travel_direction.is_equal_approx(Vector3.RIGHT), "Base direction wrong")
	await clear_shots()

	stage.camera.set_stage_x(22)
	bee.global_position = Vector3(19.5, 3.8, 0)
	await frames(3)
	await capture("01_spread_pickup")
	await touch_pickup("Powerups/SpreadFirst")
	check(bee.spread_ammo == 32 and "SPREAD x32" in hud.get_node("State").text, "Spread pickup/HUD wrong")
	check(hud.get_node("Hint").visible and "X — FIRE" in hud.get_node("Hint").text, "Spread hint missing")
	await capture("02_bee_spread")
	await capture("08_hud_spread_bomb")
	var aim_target := enemy(BeeLevel01Controller.WASP, Vector3(27, 5, 0))
	await frames(3)
	var direction := (aim_target.get_node("Hurtbox3D").global_position - bee.global_position).normalized() as Vector3
	var central := bee.fire()
	var burst := shots()
	check(burst.size() == 3 and bee.spread_ammo == 31, "Spread count/ammo wrong")
	check(central.travel_direction.is_equal_approx(direction), "Central lost auto-aim")
	for shot in burst:
		check(shot.damage == 8 and shot.hitbox.damage == 8, "Spread damage is not 80 percent")
		if shot != central:
			check(is_equal_approx(rad_to_deg(direction.angle_to(shot.travel_direction)), 14.0), "Spread angle wrong")
	var fixed := central.travel_direction
	aim_target.global_position.y = 6.5
	await frames(3)
	check(central.travel_direction.is_equal_approx(fixed), "Projectile became homing")
	await capture("03_triple_shot")
	await clear_shots()
	aim_target.global_position = Vector3(27, 5, 0)
	var spread_hp: int = aim_target.get_node("HealthComponent").current_health
	bee.fire()
	await frames(25)
	check(aim_target.get_node("HealthComponent").current_health == spread_hp - 8, "Spread central did not apply exactly 8 HP on real overlap")
	aim_target.queue_free()
	await clear_shots()
	check(bee.collect_spread() and bee.spread_ammo == 32, "Refill did not cap")
	for i in 32:
		bee.fire()
		await clear_shots()
	check(bee.spread_ammo == 0 and "BASE" in hud.get_node("State").text, "Ammo exhaustion failed")
	check(bee.fire().damage == 10 and shots().size() == 1, "No automatic return to Base")
	await clear_shots()

	stage.camera.set_stage_x(166)
	bee.global_position = Vector3(163.5, 3, 0)
	await frames(3)
	await capture("04_bomb_pickup")
	await touch_pickup("Powerups/BombFirst")
	check(bee.bomb_charges == 4 and "BOMB x4" in hud.get_node("State").text, "Bomb pickup/HUD wrong (LOTE 9: +3 per pickup, 1 -> 4)")
	check("C — USE" in hud.get_node("Hint").text, "Bomb hint missing")
	check(bee.collect_bomb() and bee.bomb_charges == 5 and not bee.collect_bomb(), "Charge cap failed (LOTE 9: cap 5)")
	var capped := PICKUP.instantiate() as BeePowerupPickup
	capped.kind = BeePowerupPickup.Kind.BOMB
	stage.add_child(capped)
	capped.global_position = bee.global_position + Vector3(2, 0, 0)
	check(not capped.collect(bee) and not capped.was_collected, "Full Bomb pickup should remain available")
	capped.queue_free()

	# Exercise actual C input, without an auto-aim target.
	bee.global_position = Vector3(166, 6, 0)
	bee.set_physics_process(true)
	await frames(2)
	Input.action_press("bee_bomb")
	await frames(2)
	Input.action_release("bee_bomb")
	check(bee.bomb_charges == 4 and "BOMB x4" in hud.get_node("State").text, "C/HUD did not consume exactly one (LOTE 9: 5 -> 4)")
	await capture("05_bomb_activation")
	bee.set_physics_process(false)
	await frames(25)

	# All seven enemy families, one crate, a far enemy, inactive enemy,
	# duplicate hurtbox and unrelated health recipient in the same query.
	bee.global_position = Vector3(198, 1.5, 0)
	stage.camera.set_stage_x(198)
	var units: Array[Node3D] = []
	var before_hp: Array[int] = []
	var scenes := [BeeLevel01Controller.WASP, BeeLevel01Controller.PROBE, BeeLevel01Controller.EYE, BeeLevel01Controller.TURRET, BeeLevel01Controller.SPEEDER, BeeLevel01Controller.ORGANIC, BeeLevel01Controller.WALKER]
	for i in scenes.size():
		var unit := enemy(scenes[i], Vector3(197 + i * 0.35, 2.2, 0))
		units.append(unit)
		before_hp.append(unit.get_node("HealthComponent").current_health)
	var duplicate := units[6].get_node("Hurtbox3D").duplicate() as DamageHurtbox3D
	units[6].add_child(duplicate)
	var far := enemy(BeeLevel01Controller.WASP, Vector3(204, 4, 0))
	var inactive := BeeLevel01Controller.WASP.instantiate() as WaspEnemy
	stage.add_child(inactive)
	inactive.global_position = bee.global_position
	# An unrelated object with Health/Hurtbox must not be damaged.
	var decoration := Node3D.new()
	var decorative_health := HealthComponent.new()
	decorative_health.name = "HealthComponent"
	decoration.add_child(decorative_health)
	var decorative_hurtbox := preload("res://scenes/components/hurtbox_3d.tscn").instantiate() as DamageHurtbox3D
	var collision := CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	decorative_hurtbox.add_child(collision)
	decoration.add_child(decorative_hurtbox)
	stage.add_child(decoration)
	decoration.global_position = bee.global_position
	var decorative_hp := decorative_health.current_health
	var human: GiantHumanCrossingHazard = stage.get_node("GiantHuman")
	var human_hits := human.hit_count
	var human_position := human.global_position
	human.global_position = bee.global_position # Within the discharge, still not a damage recipient.
	var scenery_count := stage.get_node("Scenery").get_child_count()
	var log_transform: Transform3D = stage.get_node("LogObstacle").transform
	var crate: DestructibleObstacle3D = stage.get_node("Destructibles/DefenseCrate")
	await frames(4)
	var own_hp := bee.health.current_health
	var bomb := bee.use_bomb()
	check(bomb != null and bomb.radius == 3.0 and bomb.damage == 32, "Bomb configuration wrong")
	await frames(5)
	for i in units.size():
		check(units[i].get_node("HealthComponent").current_health == maxi(0, before_hp[i] - 32), "Bomb damage/dedup failed for family " + str(i))
	check(units[6].get_node("HealthComponent").current_health > 0, "Walker killed by one Bomb")
	check(crate.is_destroyed and crate.collider.disabled, "Bomb did not destroy crate")
	check(bomb.damaged_entities == 8, "Bomb must hit 7 enemies + crate exactly once")
	check(far.health.current_health == 30 and inactive.health.current_health == 30, "Far/inactive enemy damaged")
	check(decorative_health.current_health == decorative_hp and bee.health.current_health == own_hp, "Bomb damaged an excluded recipient")
	check(human.hit_count == human_hits and stage.get_node("Scenery").get_child_count() == scenery_count and stage.get_node("LogObstacle").transform == log_transform, "Bomb changed human/rocks/log/decor")
	await capture("06_bomb_group")
	human.global_position = human_position
	bomb._discharge()
	await frames(6)
	check(units[6].get_node("HealthComponent").current_health == before_hp[6] - 32, "Repeated discharge damaged again")
	for unit in units:
		unit.queue_free()
	far.queue_free()
	inactive.queue_free()
	decoration.queue_free()
	await frames(25)
	bee.bomb_charges = 1 # LOTE 9: down to the last bomb (the cap is 5 now, the test used 3 before).
	check(bee.use_bomb() != null and bee.bomb_charges == 0 and bee.use_bomb() == null, "Empty charge handling failed")
	await frames(30)

	# Comparable local render samples: same three real active enemy AIs.
	bee.global_position = Vector3(222, 3.8, 0)
	stage.camera.set_stage_x(222)
	bee.hurtbox.monitorable = false # Performance is not a survival test.
	var stress_units: Array[Node3D] = []
	for i in 3:
		var unit := enemy(BeeLevel01Controller.PROBE, Vector3(226 + i, 4 + i * 0.6, 0))
		unit.set_physics_process(true)
		stress_units.append(unit)
	await sample_performance(false)
	bee.collect_spread()
	bee.collect_bomb()
	await sample_performance(true)
	for unit in stress_units:
		unit.queue_free()
	await clear_shots()
	var ammo := bee.spread_ammo
	var charges := bee.bomb_charges
	bee.health.take_damage(9999)
	check(bee.is_defeated and bee.fire() == null and bee.use_bomb() == null and not bee.collect_spread() and not bee.collect_bomb(), "Defeat allows weapons/pickups")
	check(bee.spread_ammo == ammo and bee.bomb_charges == charges, "Defeat attempt consumed ammo")
	stage.set_physics_process(true)
	Input.action_press("restart")
	await frames(4)
	Input.action_release("restart")
	var restarted := current_scene as BeeShmupStage
	check(restarted != stage and restarted.bee.spread_ammo == 0 and restarted.bee.bomb_charges == 1, "R did not restore kit")
	# 5 pickups since ARCADE REBUILD 02 (SpreadFirst, BombFirst, SpreadRecharge, PrebossPower, BombRecharge).
	check(restarted.get_node("Powerups").get_child_count() == 5 and restarted.bee.health.current_health == 100, "R did not restore pickups/health")
	check("BASE" in restarted.get_node("CanvasLayer/WeaponsHUD/State").text and "BOMB x1" in restarted.get_node("CanvasLayer/WeaponsHUD/State").text, "R HUD wrong")
	if failed:
		quit(1)
		return
	print("BEE_WEAPONS_POWERUPS_V01_OK base=10 spread=3x8 angle=14 ammo=32 bomb=32 radius=3 cap=3 families=7 dedup=OK exclusions=OK restart=OK")
	quit(0)
