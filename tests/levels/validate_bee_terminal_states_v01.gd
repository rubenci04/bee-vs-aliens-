extends SceneTree

# Terminal-state contracts of Level 01:
#   1. Victory: Bee cannot be damaged, enemy shots in flight are removed, nothing spawns.
#   2. R after victory fully restarts the level.
#   3. Pollen neither heals nor is consumed by a defeated Bee.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const ENEMY_SHOT := preload("res://scenes/bee_prototype/alien_enemy_projectile.tscn")

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

func press(action: String) -> void:
	await process_frame
	Input.action_press(action)
	await frames(5)
	Input.action_release(action)

func bind(value: Node) -> void:
	stage = value as BeeShmupStage
	bee = stage.bee

func run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(4)
	bind(current_scene)
	var wave := stage.wave as BeeLevel01Controller

	# --- 1. Victory is not damageable -------------------------------------
	wave.event_index = BeeLevel01Controller.EVENTS.size() # Every encounter consumed.
	stage.distance = 359.0
	stage.scroll_speed = 8.0
	await frames(2)
	# UFO BOSS 01: the level now completes only after the boss dies (covered in validate_bee_ufo_boss_01).
	for i in 900:
		await frames(1)
		if wave.boss != null and wave.boss.is_active():
			wave.boss.health.take_damage(99999)
		if wave.boss_defeated:
			break
	check(wave.boss_defeated, "UFO boss did not finish")
	var shot := ENEMY_SHOT.instantiate() as AlienEnemyProjectile
	stage.add_child(shot)
	shot.global_position = Vector3(stage.distance + 3.0, 5.0, 0)
	shot.launch(Vector3.LEFT, null)
	for i in 240:
		if stage.sector_complete:
			break
		await frames(1)
	check(stage.sector_complete and stage.status.text == "SECTOR DESPEJADO", "Level did not complete")
	check("R — JUGAR DE NUEVO" in stage.section_label.text, "Replay prompt missing")
	await frames(3)
	check(not is_instance_valid(shot) or shot.is_queued_for_deletion(), "Enemy shot survived victory")
	var late := ENEMY_SHOT.instantiate() as AlienEnemyProjectile
	stage.add_child(late)
	late.global_position = bee.global_position
	late.launch(Vector3.LEFT, null)
	await frames(3)
	check(not is_instance_valid(late) or late.is_queued_for_deletion(), "Late enemy shot survived victory")
	var spawned := wave.spawn_history.size()
	check(bee.health.take_damage(50) == 0 and bee.health.current_health == bee.health.max_health, "Bee took damage after victory")
	check(not bee.is_defeated, "Bee defeated after victory")
	await frames(30)
	check(wave.spawn_history.size() == spawned and wave.active_units.is_empty(), "Enemies appeared after victory")

	# --- 2. R after victory restarts the level ----------------------------
	var old_id := stage.get_instance_id()
	await press("restart")
	await frames(2)
	check(current_scene.get_instance_id() != old_id, "R after victory did not reload the level")
	bind(current_scene)
	wave = stage.wave as BeeLevel01Controller
	check(not stage.sector_complete and stage.distance < 1.0, "Restart did not reset progress")
	check(not stage.checkpoint.checkpoint_active and wave.event_index == 0, "Restart was not a full restart")
	check(bee.health.current_health == 100 and not bee.health.damage_blocked, "Restart left Bee protected or hurt")
	check(stage.get_node("Pollen").get_child_count() == 17, "Restart pollen missing")

	# --- 3. Pollen and a defeated Bee -------------------------------------
	bee.health.take_damage(30)
	var pollen_a := stage.get_node("Pollen/PollenA") as BeePollenPickup
	check(pollen_a.collect(bee) and bee.health.current_health == 90 and stage.pollen_count == 1, "Pollen no longer heals a living Bee")
	await frames(1)
	var count_alive := stage.pollen_count
	bee.health.take_damage(9999)
	check(bee.is_defeated and bee.health.current_health == 0, "Bee not defeated")
	var pollen_b := stage.get_node("Pollen/PollenB") as BeePollenPickup
	check(not pollen_b.collect(bee), "Pollen accepted a defeated Bee")
	await frames(2)
	check(is_instance_valid(pollen_b) and not pollen_b.was_collected and not pollen_b.is_queued_for_deletion(), "Pollen consumed by defeated Bee")
	check(bee.health.current_health == 0 and bee.is_defeated and stage.pollen_count == count_alive, "Pollen revived/counted for a defeated Bee")
	print("TERMINAL_STATES_OK")
	quit(0)
