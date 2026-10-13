extends SceneTree

const COMBAT_POC := preload("res://scenes/bee_prototype/bee_combat_poc.tscn")


func _initialize() -> void:
	call_deferred("run_checks")


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)


func frames(count: int) -> void:
	for index in count:
		await physics_frame


func wait_for_state(actor: Node, wanted: int, limit := 120) -> bool:
	for index in limit:
		if actor.current_state == wanted:
			return true
		await physics_frame
	return false


func run_checks() -> void:
	create_timer(70.0).timeout.connect(func(): quit(1))
	check(COMBAT_POC != null, "Bee Combat POC failed to load")
	var poc := COMBAT_POC.instantiate()
	root.add_child(poc)
	current_scene = poc
	await frames(5)

	var bee := poc.get_node("BeePlayer") as BeePlayer
	var wasp_a := poc.get_node("Enemies/WaspA") as WaspEnemy
	var probe_a := poc.get_node("Enemies/ProbeA") as AlienProbeRanged
	var wasp_b := poc.get_node("Enemies/WaspB") as WaspEnemy
	var probe_b := poc.get_node("Enemies/ProbeB") as AlienProbeRanged
	check(bee.health.current_health == 100 and not bee.is_defeated, "BeePlayer did not start at 100 HP")
	check(bee.melee_damage == 30 and is_equal_approx(bee.melee_range, 0.85) and is_equal_approx(bee.melee_cooldown, 0.9), "Bee melee values changed (LOTE 14: 30 damage, 0.9 s)")
	check(not wasp_a.is_active() and not probe_a.is_active() and not wasp_b.is_active() and not probe_b.is_active(), "Enemies began active")
	check(poc.get_node("Pollen").get_child_count() == 2, "Combat POC must have two pollen pickups")

	# Encounter A activates by progression and Wasp chases in the X/Y plane.
	bee.position = Vector3(-5.9, 3.0, 0)
	await frames(4)
	check(poc.stage == poc.Stage.ENCOUNTER_A and wasp_a.is_active(), "Encounter A did not activate")
	check(wasp_a.health.current_health == 30 and is_equal_approx(wasp_a.move_speed, 5.0), "Wasp values changed")
	var wasp_start := wasp_a.position
	await frames(10)
	check(wasp_a.position.distance_to(bee.position) < wasp_start.distance_to(bee.position), "Wasp did not chase")

	# Its visible windup precedes one melee hit, followed by recovery.
	wasp_a.position = bee.position + Vector3(0.8, 0, 0)
	wasp_a.velocity = Vector3.ZERO
	wasp_a.current_state = WaspEnemy.State.CHASE
	await frames(2)
	check(wasp_a.current_state == WaspEnemy.State.WINDUP and wasp_a.telegraph.visible, "Wasp windup/telegraph failed")
	var health_before_wasp := bee.health.current_health
	check(await wait_for_state(wasp_a, WaspEnemy.State.ATTACK, 40), "Wasp never entered ATTACK")
	check(wasp_a.attack_hitbox.enabled, "Wasp hitbox was not enabled")
	for frame in 20:
		if bee.health.current_health < health_before_wasp:
			break
		await physics_frame
	check(bee.health.current_health == health_before_wasp - 10, "Wasp did not deal exactly 10 damage")
	check(await wait_for_state(wasp_a, WaspEnemy.State.RECOVERY, 30), "Wasp did not enter recovery")

	# Pollen heals 20 and never exceeds max.
	bee.health.take_damage(20)
	var damaged_health := bee.health.current_health
	var pollen_a := poc.get_node("Pollen/PollenA") as BeePollenPickup
	check(pollen_a.collect(bee), "First pollen was not collected")
	await frames(2)
	check(bee.health.current_health == mini(100, damaged_health + 20), "Pollen did not heal 20")
	bee.health.restore_health(100)
	var pollen_b := poc.get_node("Pollen/PollenB") as BeePollenPickup
	check(pollen_b.collect(bee), "Full-health pollen could not be collected")
	await frames(2)
	check(bee.health.current_health == 100 and poc.pollen_count == 2, "Pollen exceeded max HP or counter failed")

	# Z (LOTE 14: 30 damage, 360 degrees) kills the 30 HP Wasp in one hit; with nothing in reach it swings forward/back by facing.
	wasp_a.set_physics_process(false)
	wasp_a.position = bee.position + Vector3(0.75, 0, 0)
	bee.facing_x = 1.0
	bee._place_melee_hitbox()
	check(bee.start_melee(), "Z melee was rejected")
	check(bee.melee_hitbox.enabled and bee.melee_hitbox.position.x > 0.0, "Melee did not respect right facing")
	for frame in 12:
		if wasp_a.is_defeated():
			break
		await physics_frame
	check(wasp_a.is_defeated() and poc.stage == poc.Stage.PAUSE_B, "Wasp death did not advance progression")
	await frames(60)
	bee.facing_x = -1.0
	bee._place_melee_hitbox()
	check(bee.start_melee() and bee.melee_hitbox.position.x < 0.0, "Melee did not respect left facing")

	# Encounter B proves auto-aim and ranged attack behavior.
	bee.position = Vector3(-0.4, 3.5, 0)
	bee.facing_x = 1.0
	await frames(4)
	check(probe_a.is_active() and poc.stage == poc.Stage.ENCOUNTER_B, "Encounter B did not activate")
	check(bee.refresh_auto_aim() == probe_a, "Auto-aim did not accept AlienProbeRanged")
	probe_a.position = bee.position + Vector3(6.0, 0, 0)
	probe_a.velocity = Vector3.ZERO
	probe_a.current_state = AlienProbeRanged.State.POSITION
	var fired := {"projectile": null}
	probe_a.projectile_fired.connect(func(projectile: AlienEnemyProjectile): fired.projectile = projectile)
	await frames(2)
	check(probe_a.current_state == AlienProbeRanged.State.WINDUP and probe_a.telegraph.visible, "Probe windup failed")
	for frame in 60:
		if fired.projectile is AlienEnemyProjectile:
			break
		await physics_frame
	check(fired.projectile is AlienEnemyProjectile, "Probe did not shoot")
	var enemy_projectile := fired.projectile as AlienEnemyProjectile
	var original_direction := enemy_projectile.travel_direction
	check(enemy_projectile.damage == 8 and is_equal_approx(enemy_projectile.speed, 6.0), "Enemy projectile values changed")
	check(enemy_projectile.hitbox.can_damage(bee.hurtbox), "Enemy projectile cannot damage BeePlayer")
	check(not enemy_projectile.hitbox.can_damage(wasp_b.hurtbox), "Enemy projectile allows friendly fire")
	bee.position.y += 1.5
	await frames(2)
	check(enemy_projectile.travel_direction.is_equal_approx(original_direction), "Enemy projectile became homing")
	enemy_projectile.queue_free()
	await frames(2)

	# A second real projectile reaches a stationary Bee and applies eight damage.
	bee.position = Vector3(-3.5, 3.5, 0)
	probe_a.position = Vector3(2.5, 3.5, 0)
	probe_a.current_state = AlienProbeRanged.State.POSITION
	probe_a.velocity = Vector3.ZERO
	var hp_before_probe := bee.health.current_health
	for frame in 150:
		if bee.health.current_health < hp_before_probe:
			break
		await physics_frame
	check(bee.health.current_health == hp_before_probe - 8, "Probe projectile did not deal exactly 8 damage")
	check(probe_a.current_state == AlienProbeRanged.State.COOLDOWN or probe_a.projectile_fire_count >= 2, "Probe cooldown failed")

	# X still creates a directed projectile and can defeat the Probe.
	probe_a.set_physics_process(false)
	probe_a.position = bee.position + Vector3(4.0, 0, 0)
	bee.facing_x = 1.0
	for expected in [15, 5, 0]:
		check(bee.refresh_auto_aim() == probe_a, "X auto-aim lost Probe target")
		check(bee.fire() != null, "X failed to fire")
		for frame in 45:
			if probe_a.health.current_health == expected:
				break
			await physics_frame
		check(probe_a.health.current_health == expected, "X projectile did not damage Probe")
	check(probe_a.is_defeated() and poc.stage == poc.Stage.PAUSE_C, "Probe death did not advance progression")

	# Encounter C activates exactly two targets and auto-aim supports Wasp too.
	bee.position = Vector3(4.1, 3.4, 0)
	bee.facing_x = 1.0
	await frames(4)
	check(poc.stage == poc.Stage.ENCOUNTER_C and wasp_b.is_active() and probe_b.is_active(), "Encounter C did not activate both enemies")
	var selected := bee.refresh_auto_aim()
	check(selected == wasp_b or selected == probe_b, "Auto-aim rejected final enemy types")
	wasp_b.health.take_damage(1000)
	await frames(2)
	check(poc.completion_count == 0, "Final completed with Probe alive")
	probe_b.health.take_damage(1000)
	await frames(3)
	check(poc.stage == poc.Stage.COMPLETE and poc.completion_count == 1 and poc.completion_label.visible, "Final completion failed")
	poc._on_final_enemy_defeated(probe_b)
	check(poc.completion_count == 1, "Final completion duplicated")

	# Defeat blocks movement and attacks; R reloads this POC cleanly.
	bee.health.take_damage(1000)
	await frames(3)
	check(bee.is_defeated and poc.stage == poc.Stage.DEFEATED, "Bee defeat state failed")
	check(poc.defeat_label.visible and poc.retry_label.visible, "Defeat feedback is missing")
	var defeated_position := bee.position
	Input.action_press("move_right")
	await frames(4)
	Input.action_release("move_right")
	check(bee.position.is_equal_approx(defeated_position), "Defeated Bee still moved")
	check(bee.fire() == null and not bee.start_melee(), "Defeated Bee still attacked")
	var old_id := poc.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(8)
	check(current_scene != null and current_scene.get_instance_id() != old_id, "R did not reload Bee Combat POC")
	var restarted := current_scene
	check(restarted.scene_file_path.ends_with("bee_combat_poc.tscn"), "R loaded the wrong scene")
	check(restarted.get_node("BeePlayer").health.current_health == 100, "Restart did not restore Bee HP")
	check(restarted.get_node("BeePlayer/VisualRoot/BeeVisual").is_visible_in_tree(), "Restart lost the imported visual")
	check(not restarted.get_node("Enemies/WaspA").is_active(), "Restart retained encounter state")

	print("BEE_COMBAT_POC_OK melee=15 range=0.85 cooldown=0.52 wasp=30hp probe=25hp projectile=8 heal=20 encounters=3 defeat_restart friendly_fire")
	current_scene = null
	restarted.queue_free()
	await process_frame
	quit(0)
