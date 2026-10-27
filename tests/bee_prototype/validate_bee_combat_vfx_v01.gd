extends SceneTree

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const REVIEW := "res://dev/combat_vfx_review/"
var stage: BeeShmupStage
var bee: BeePlayer

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
		await process_frame

func effects(kind: StringName) -> Array: # NOCHE 01: Level 01 explosions are toon bursts (not BeeCombatVFX) carrying the same `kind`.
	var result: Array = []
	var bee_kind: StringName = {
		&"muzzle": &"bee_muzzle",
		&"muzzle_spread": &"bee_muzzle_spread",
		&"impact": &"bee_impact",
		&"melee": &"bee_melee",
	}.get(kind, kind)
	for node in get_nodes_in_group("bee_combat_vfx"):
		if node.get("kind") in [kind, bee_kind] and not node.is_queued_for_deletion():
			result.append(node)
	return result

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW + name + ".png") == OK, "Capture failed " + name)

func clear_shots() -> void:
	for child in stage.get_children():
		if child is BeeEnergyProjectile:
			child.queue_free()
	await frames(45)
	check(get_nodes_in_group("bee_combat_vfx").is_empty(), "Temporary VFX accumulated")

func unit(scene: PackedScene, point: Vector3) -> Node3D:
	var enemy := scene.instantiate() as Node3D
	stage.add_child(enemy)
	enemy.global_position = point
	enemy.call("activate", bee)
	enemy.set_physics_process(false)
	return enemy

func measure(stress: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await frames(30)
	var start := Time.get_ticks_usec()
	var last := start
	var worst := 0.0
	var peak := 0
	var slow_frames := 0
	var worst_index := -1
	var tail_start := 0
	var victims: Array[Node3D] = []
	if stress:
		bee.collect_spread()
		bee.collect_bomb()
		for i in 3:
			var enemy := unit(BeeLevel01Controller.PROBE, bee.global_position + Vector3(2 + i * 0.2, i * 0.5, 0))
			enemy.set_physics_process(true)
			victims.append(enemy)
	for i in 240:
		if stress and i % 24 == 0:
			bee.fire()
		if stress and i == 45:
			bee.use_bomb()
		if stress and i == 75:
			for enemy in victims:
				if is_instance_valid(enemy):
					enemy.get_node("HealthComponent").take_damage(9999)
		await process_frame
		var now := Time.get_ticks_usec()
		var milliseconds := float(now - last) / 1000.0
		if milliseconds > worst:
			worst = milliseconds
			worst_index = i
		if milliseconds > 33.3:
			slow_frames += 1
		if i == 119:
			tail_start = now
		last = now
		peak = maxi(peak, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("COMBAT_VFX_PERFORMANCE stress=", stress, " frames=240 fps=", 240000000.0 / float(last - start), " worst_ms=", worst, " peak_nodes=", peak, " slow_frames=", slow_frames, " worst_index=", worst_index, " tail_fps=", 120000000.0 / float(last - tail_start))
	for enemy in victims:
		if is_instance_valid(enemy):
			enemy.queue_free()

func run() -> void:
	create_timer(100.0, true, false, true).timeout.connect(func(): quit(1))
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("Juice").set_physics_process(false) # LOTE 11: the item magnet would pull the Spread capsule next to Bee.
	bee = stage.bee
	bee.set_physics_process(false)
	bee.flight_min = Vector2(-20, 0.7)
	bee.flight_max = Vector2(400, 7.2)
	bee.hurtbox.monitorable = false
	bee.global_position = Vector3(24, 3.8, 0)
	stage.camera.set_stage_x(26)
	var base := bee.fire()
	check(effects(&"muzzle").size() == 1, "Base muzzle absent")
	check(effects(&"muzzle")[0].global_position.distance_to(base.global_position) < 0.4, "Muzzle effect is at the model muzzle, within 0.4 m of the spawn")
	check(base.damage == 3 and base.speed == 14 and is_equal_approx(base.hitbox.get_node("CollisionShape3D").shape.radius, 0.15), "Projectile gameplay altered (Base: 3 damage, 14 m/s, 0.15 m radius)")
	await capture("01_base_muzzle")
	await frames(8)
	check(is_equal_approx(base.trail.lifetime, preload("res://scripts/game/bee_shooting_settings.gd").SHOT_TRAIL_SECONDS) and not base.trail.local_coords and base.trail.emitting, "Trail missing/incorrect (LOTE 9: short plasma trail)")
	await capture("02_projectile_trail")
	await clear_shots()

	var probe := unit(BeeLevel01Controller.PROBE, Vector3(27, 3.8, 0))
	await frames(3)
	bee.fire()
	for i in 25:
		await frames(1)
		if not effects(&"impact").is_empty():
			break
	check(effects(&"impact").size() == 1, "Projectile impact missing/duplicated")
	check(probe.get_node("HealthComponent").current_health == probe.get_node("HealthComponent").max_health - 3, "Impact changed damage")
	check(probe.get_node("HitFlash3D").activation_count > 0, "Existing HitFlash not preserved")
	await frames(3)
	await capture("03_projectile_impact")
	probe.queue_free()
	await clear_shots()

	bee.collect_spread()
	var spread := bee.fire()
	check(effects(&"muzzle_spread").size() == 1 and spread.trail.amount == 14 and bee.spread_ammo > 19.0 and bee.spread_ammo <= 20.0, "Spread visual/state wrong")
	await frames(4)
	await capture("04_spread")
	await clear_shots()

	var wasp := unit(BeeLevel01Controller.WASP, bee.global_position + Vector3(0.8, 0, 0))
	await frames(3)
	check(bee.start_melee(), "Melee refused")
	bee.set_physics_process(true) # Tanda E: the sting dash advances in Bee's own physics step
	await frames(40)
	check(wasp.health.current_health <= 0, "Melee damage incorrect (Tanda E: the melee impact is now a punch star, not a BeeCombatVFX effect)")
	await capture("05_melee_hit")
	wasp.queue_free()
	await clear_shots()

	check(bee.use_bomb() != null, "Bomb refused")
	bee.active_bomb.detonate()
	await frames(16)
	check(effects(&"bomb").size() == 1, "Bomb VFX missing")
	var bomb_visual := effects(&"bomb")[0] as BeeCombatVFX
	check(bomb_visual.extent == 3.0 and bomb_visual.duration == 0.55, "Bomb visual radius/duration wrong")
	await frames(4)
	await capture("06a_bomb_early")
	await frames(6)
	await capture("06b_bomb_mid")
	await frames(7)
	check(bomb_visual.get_node("Shockwave").scale.is_equal_approx(Vector3.ONE * 3.0), "Shockwave did not reach real radius")
	await capture("06_bomb_shockwave")
	await frames(35)
	check(effects(&"bomb").is_empty(), "Bomb VFX did not finish")

	var walker := unit(BeeLevel01Controller.WALKER, Vector3(25, 2, 0))
	await frames(3)
	walker.get_node("HealthComponent").take_damage(9999)
	await frames(3)
	check(effects(&"tech_death").size() == 1 and walker.call("is_defeated"), "Tech death missing")
	var walker_animation: AnimationPlayer = walker.animation_player
	check("Death" in walker_animation.current_animation and walker_animation.is_playing(), "Walker Death interrupted")
	await frames(8)
	await capture("07_tech_death")
	await frames(45)
	check(effects(&"tech_death").is_empty(), "Tech death VFX did not finish")
	walker.queue_free()

	var organic := unit(BeeLevel01Controller.ORGANIC, Vector3(25, 3, 0))
	await frames(3)
	organic.get_node("HealthComponent").take_damage(9999)
	await frames(3)
	check(effects(&"organic_death").size() == 1 and organic.call("is_defeated"), "Organic death missing")
	check("Death" in organic._animation_player.current_animation and organic._animation_player.is_playing(), "Organic Death interrupted")
	await frames(8)
	await capture("08_organic_death")
	organic.queue_free()
	await clear_shots()

	stage.camera.set_stage_x(18)
	var crate: DestructibleObstacle3D = stage.get_node("Destructibles/GardenCrate")
	crate.health.take_damage(9999)
	await frames(3)
	check(crate.collider.disabled and crate.body.collision_layer == 0 and effects(&"crate").size() == 1, "Break VFX kept blocking collider")
	await frames(7)
	await capture("09_crate_break")
	await clear_shots()

	stage.camera.set_stage_x(22)
	bee.spread_ammo = 0.0
	var pickup: BeePowerupPickup = stage.get_node("Powerups/SpreadFirst")
	check(pickup.collect(bee) and not pickup.collect(bee), "Pickup duplication")
	await frames(3)
	var toon_feedback := stage.get_node("Powerups").get_children().any(func(n): return n.has_signal("finished")) # NOCHE 01: Codex toon pickup = warm toon burst.
	check((effects(&"pickup").size() == 1 or toon_feedback) and bee.spread_ammo > 19.0 and bee.spread_ammo <= 20.0, "Pickup feedback/state wrong")
	await capture("10_pickup")
	await clear_shots()
	var pollen: BeePollenPickup = stage.get_node("Pollen/PollenA")
	check(pollen.collect(bee) and not pollen.collect(bee), "Pollen collection changed")
	await frames(3)
	check(effects(&"pollen").size() == 1, "Pollen pulse missing")
	await clear_shots()
	await measure(false)
	await measure(true)
	await clear_shots()
	check(stage.get_node("CombatVFX").get_child_count() == 0, "Cleanup left children")
	print("BEE_COMBAT_VFX_V01_OK muzzle trail impact spread melee bomb deaths animations crates pickups cleanup gameplay=unchanged")
	quit(0)
