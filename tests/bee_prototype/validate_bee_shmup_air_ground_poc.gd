extends SceneTree

const POC := preload("res://scenes/bee_prototype/bee_shmup_air_ground_poc.tscn")
var scene: BeeShmupStage
var bee: BeePlayer
var wave: BeeShmupAirGroundWaveController

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

func until_wave(number: int, limit := 1800) -> bool:
	for i in limit:
		if wave.wave_index >= number:
			return true
		await frames(1)
	return false

func until_active(unit: Node3D, limit := 260) -> bool:
	for i in limit:
		if bool(unit.call("is_active")):
			return true
		await frames(1)
	return false

func capture_runtime(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	check(image.save_png("res://dev/air_ground_review/" + filename) == OK, "Runtime capture failed")

func kill(unit: Node3D) -> void:
	unit.get_node("HealthComponent").take_damage(1000)

func run() -> void:
	root.size = Vector2i(1280, 720) # Tanda E: the aim assist checks the on-screen rect; the headless window is 64x64
	create_timer(140.0).timeout.connect(func(): quit(1))
	scene = POC.instantiate() as BeeShmupStage
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	bee = scene.bee
	wave = scene.wave as BeeShmupAirGroundWaveController
	check(bee != null and wave != null and is_equal_approx(scene.sector_length, 95.0) and is_equal_approx(scene.scroll_speed, 2.0), "Scene/scroll setup wrong")
	check(scene.get_node("Pollen").get_child_count() == 5 and scene.get_node("Turrets").get_child_count() == 4, "Pollen/turrets missing")
	check(scene.get_node("LogObstacle/CollisionShape3D").disabled, "Log obstacle remained enabled")
	check(await until_wave(1), "Wave 1 did not start from scroll")
	var probe1 := wave.get_node("Wave1Air") as AlienProbeRanged
	var turret1 := wave.turrets[0]
	check(await until_active(probe1) and await until_active(turret1), "Probe + Turret not activated")
	check(probe1.target == bee and turret1.target == bee and wave.active_count() == 2, "Wave 1 targets/max wrong")
	bee.global_position = Vector3(probe1.global_position.x - 3.0, probe1.global_position.y, 0)
	bee.facing_x = 1.0
	await frames(2)
	check(bee.refresh_auto_aim() == probe1, "Air auto-aim failed")
	bee.global_position = Vector3(turret1.global_position.x - 4.0, 1.0, 0)
	await frames(2)
	check(bee.refresh_auto_aim() == turret1, "Ground auto-aim failed")
	await capture_runtime("wave_1_probe_turret.png")
	kill(probe1)
	await frames(2)
	check(bee.refresh_auto_aim() != probe1, "Dead air target remained selectable")
	for i in 900:
		if wave.resolved_count >= 2:
			break
		await frames(1)
	check(wave.resolved_count == 2 and wave.defeated_count == 1 and not turret1.is_active(), "Turret bypass did not resolve wave 1")
	check(bee.refresh_auto_aim() != turret1, "Bypassed turret remained selectable")
	check(await until_wave(2), "Wave 2 did not start")
	var eye2 := wave.get_node("Wave2Air") as EyeDroneEnemy
	var turret2 := wave.turrets[1]
	check(await until_active(eye2) and await until_active(turret2), "EyeDrone + Turret not activated")
	check(eye2.health.max_health == 18 and is_equal_approx(eye2.move_speed, 4.5) and turret2.health.max_health == 30, "Approved enemy values changed")
	bee.global_position = Vector3(eye2.global_position.x - 3.0, eye2.global_position.y, 0)
	await frames(2)
	check(bee.refresh_auto_aim() == eye2, "EyeDrone auto-aim failed")
	await capture_runtime("wave_2_eye_turret.png")
	kill(eye2)
	kill(turret2)
	await frames(2)
	check(await until_wave(3), "Wave 3 did not start")
	var speeder3 := wave.get_node("Wave3Air") as SpeederEnemy
	var turret3 := wave.turrets[2]
	check(await until_active(speeder3) and await until_active(turret3), "Speeder + Turret not activated")
	check(is_equal_approx(speeder3.telegraph_time, 0.7) and is_equal_approx(speeder3.dash_speed, 9.5), "Speeder timing changed")
	check(is_equal_approx(turret3.windup_time, 0.65) and turret3.projectile_damage == 9, "Turret timing/damage changed")
	for i in 200:
		if speeder3.current_state == SpeederEnemy.Phase.TELEGRAPH:
			break
		await frames(1)
	check(speeder3.telegraph.visible and not speeder3.dash_hitbox.enabled, "Speeder telegraph not readable before dash")
	await capture_runtime("wave_3_speeder_turret.png")
	kill(speeder3)
	kill(turret3)
	await frames(2)
	check(await until_wave(4), "Wave 4 did not start")
	var eye4 := wave.get_node("Wave4Air") as EyeDroneEnemy
	check(await until_active(eye4), "Wave 4 EyeDrone missing")
	for i in 220:
		if wave.spawned_count >= 8:
			break
		await frames(1)
	var speeder4 := wave.get_node("Wave4Air2") as SpeederEnemy
	check(speeder4 != null and await until_active(speeder4), "Wave 4 Speeder missing")
	check(wave.active_count() == 2, "Wave 4 overlap wrong")
	kill(eye4)
	kill(speeder4)
	await frames(2)
	check(await until_wave(5), "Wave 5 did not start")
	var turret5 := wave.turrets[3]
	check(await until_active(turret5), "Final turret missing")
	var probe5: AlienProbeRanged
	for i in 220:
		probe5 = wave.get_node_or_null("Wave5Air") as AlienProbeRanged
		if probe5 != null:
			break
		await frames(1)
	check(probe5 != null and await until_active(probe5), "Final Probe missing")
	bee.global_position = Vector3(probe5.global_position.x - 3.0, probe5.global_position.y, 0)
	bee.facing_x = 1.0
	await frames(2)
	check(bee.refresh_auto_aim() == probe5, "Air target after ground failed")
	var pollen := scene.get_node("Pollen/PollenE") as BeePollenPickup
	bee.health.take_damage(20)
	var before_heal := bee.health.current_health
	check(pollen.collect(bee), "Pollen could not be collected")
	await frames(2)
	check(bee.health.current_health == mini(before_heal + 20, 100), "Pollen did not heal")
	kill(probe5)
	kill(turret5)
	await frames(2)
	check(wave.is_complete() and wave.resolved_count == 10 and wave.max_active_seen <= 2, "Completion/max simultaneous wrong")
	for i in 1800:
		if scene.sector_complete:
			break
		await frames(1)
	check(scene.sector_complete and scene.status.text == "SECTOR DESPEJADO", "Sector did not end")
	bee.health.take_damage(1000)
	await frames(2)
	check(bee.is_defeated and scene.status.text.contains("PLAYER DOWN"), "Defeat missing")
	var old_id := scene.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id() != old_id, "R did not reload scene")
	var reset := current_scene as BeeShmupStage
	var reset_wave := reset.wave as BeeShmupAirGroundWaveController
	check(reset.distance < 0.5 and reset_wave.wave_index == 0 and reset_wave.spawned_count == 0, "Scroll/waves did not reset")
	check(reset.bee.health.current_health == 100 and reset.get_node("Pollen").get_child_count() == 5, "Bee/pollen did not reset")
	check(reset_wave.turrets[0].health.current_health == 30 and not reset_wave.turrets[0].is_active(), "Turrets did not reset")
	print("BEE_SHMUP_AIR_GROUND_OK five waves max_two air_ground_aim turret_bypass pollen finish restart")
	quit(0)
