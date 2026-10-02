extends SceneTree

const POC := preload("res://scenes/bee_prototype/bee_shmup_core_poc.tscn")
var scene: BeeShmupStage
var bee: BeePlayer
var wave: Node3D

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

func wait_for_spawn(count: int, limit := 600) -> bool:
	for i in limit:
		if wave.spawned_count >= count:
			return true
		await frames(1)
	return false

func wait_for_entry(probe: AlienProbeRanged, limit := 180) -> bool:
	for i in limit:
		if probe.is_active():
			return true
		await frames(1)
	return false

func run() -> void:
	create_timer(90.0).timeout.connect(func(): quit(1))
	check(POC != null, "SHMUP scene failed to load")
	scene = POC.instantiate() as BeeShmupStage
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	bee = scene.bee
	wave = scene.wave
	check(bee != null and scene.camera != null and wave != null, "Core nodes missing")
	check(InputMap.has_action("throw_orange") and InputMap.has_action("debug_attack") and InputMap.has_action("restart"), "Bee input missing")
	check(scene.get_node("Pollen").get_child_count() == 4, "Four pollen pickups required")
	check(is_equal_approx(scene.scroll_speed, 2.0) and is_equal_approx(scene.sector_length, 54.0), "Scroll defaults changed")
	check(not scene.sector_complete and wave.spawned_count == 0, "Wave began prematurely")
	var start_camera_x := scene.camera.global_position.x
	var start_local_x := bee.global_position.x - scene.camera.global_position.x
	var start_y := bee.global_position.y
	Input.action_press("move_right")
	Input.action_press("move_forward")
	await frames(15)
	Input.action_release("move_right")
	Input.action_release("move_forward")
	check(scene.camera.global_position.x > start_camera_x, "Camera did not advance")
	check(bee.global_position.x - scene.camera.global_position.x > start_local_x and bee.global_position.y > start_y, "Bee cannot steer in X/Y")
	check(bee.global_position.x >= scene.camera.global_position.x + scene.screen_left - 0.01 and bee.global_position.x <= scene.camera.global_position.x + scene.screen_right + 0.01, "Bee escaped horizontal flight window")
	check(bee.global_position.y >= scene.flight_bottom and bee.global_position.y <= scene.flight_top, "Bee escaped vertical flight window")
	check(scene.get_node("LogObstacle/CollisionShape3D") != null and scene.get_node("BottleObstacle/CollisionShape3D") != null, "Large obstacles need collision")
	bee.velocity = Vector3.ZERO
	bee.global_position = Vector3(scene.camera.global_position.x + scene.screen_left + 0.02, 4.0, 0.0)
	var rear_start := bee.global_position.x
	await frames(20)
	check(bee.global_position.x > rear_start + 0.4 and bee.global_position.x >= scene.camera.global_position.x + scene.screen_left - 0.01, "Rear edge did not carry Bee")
	check(await wait_for_spawn(1), "First Probe did not spawn by distance")
	var probe1 := wave.get_node("Probe1") as AlienProbeRanged
	check(probe1.global_position.x > scene.camera.global_position.x + 8.0 and not probe1.is_active(), "Probe did not enter from off-screen right")
	check(await wait_for_entry(probe1), "Probe did not enter and activate")
	check(wave.active_count() == 1 and probe1.target == bee, "First Probe target/active state wrong")
	probe1.set_physics_process(false)
	bee.global_position = probe1.global_position + Vector3(-3.0,0,0)
	bee.facing_x = 1.0
	await frames(2)
	check(bee.refresh_auto_aim() == probe1, "Auto-aim lost target while camera scrolls")
	var shots := bee.shots_fired
	var first_hp := probe1.health.current_health
	check(bee.fire() != null and bee.shots_fired == shots + 1, "X firing rejected")
	for i in 40:
		if probe1.health.current_health < first_hp:
			break
		await frames(1)
	check(probe1.health.current_health < first_hp, "Shot did not damage moving-world Probe")
	probe1.health.take_damage(100)
	await frames(2)
	check(wave.defeated_count == 1, "First defeat not counted")
	check(await wait_for_spawn(3), "Second pair did not spawn after pause/threshold")
	check(wave.active_count() <= 2 and wave.max_active_seen <= 2, "More than two Probes active")
	var probe2 := wave.get_node("Probe2") as AlienProbeRanged
	var probe3 := wave.get_node("Probe3") as AlienProbeRanged
	check(await wait_for_entry(probe2) and await wait_for_entry(probe3), "Probe pair failed to enter")
	check(probe2.target == bee and probe3.target == bee, "Probe pair missing Bee target")
	probe2.set_physics_process(false)
	probe3.set_physics_process(false)
	bee.health.take_damage(30)
	var hp := bee.health.current_health
	check((scene.get_node("Pollen/PollenA") as BeePollenPickup).collect(bee), "Pollen cannot be collected")
	await frames(2)
	check(bee.health.current_health == mini(hp + 20, bee.health.max_health) and scene.pollen_count == 1, "Pollen heal/counter wrong")
	probe2.health.take_damage(100)
	probe3.health.take_damage(100)
	await frames(2)
	check(wave.defeated_count == 3 and wave.is_complete() and scene.wave_clear_announced, "Wave did not complete after three deaths")
	check(scene.status.text == "OLEADA ELIMINADA", "Wave clear feedback missing")
	for i in 1700:
		if scene.sector_complete:
			break
		await frames(1)
	check(scene.sector_complete and scene.status.text == "SECTOR COMPLETO", "Distance-based sector finish missing")
	var final_distance := scene.distance
	await frames(10)
	check(is_equal_approx(scene.distance, final_distance), "Scroll continued after completion")
	bee.health.take_damage(1000)
	await frames(2)
	check(bee.is_defeated and scene.status.text.contains("PLAYER DOWN"), "Defeat feedback missing")
	var old_id := scene.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id() != old_id, "R did not reload scene")
	var reset_scene := current_scene as BeeShmupStage
	check(reset_scene.distance < 0.5 and reset_scene.wave.spawned_count == 0, "Scroll/wave did not reset")
	check(reset_scene.bee.health.current_health == 100 and reset_scene.get_node("Pollen").get_child_count() == 4, "Bee/pollen did not reset")
	print("BEE_SHMUP_CORE_POC_OK scroll XY fire autoaim 1+2 pollen complete restart")
	quit(0)

