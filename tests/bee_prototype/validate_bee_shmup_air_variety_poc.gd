extends SceneTree
const POC := preload("res://scenes/bee_prototype/bee_shmup_air_variety_poc.tscn")
const EYE_ASSET := preload("res://assets/external/approved/alien_air/quaternius/Sci-Fi Essentials Kit[Standard]/glTF/Enemy_EyeDrone.gltf")
const SPEEDER_ASSET := preload("res://assets/external/approved/alien_air/kenney/kenney_space-kit/Models/GLTF format/craft_speederA.glb")
var scene: BeeShmupStage
var bee: BeePlayer
var wave: BeeShmupAirWaveController
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
func until_wave(number: int, limit := 1400) -> bool:
	for i in limit:
		if wave.wave_index >= number: return true
		await frames(1)
	return false
func until_active(unit: Node3D, limit := 220) -> bool:
	for i in limit:
		if bool(unit.call("is_active")): return true
		await frames(1)
	return false
func until_state(unit: Node3D, wanted: int, limit := 300) -> bool:
	for i in limit:
		if unit.get("current_state") == wanted: return true
		await frames(1)
	return false
func capture_runtime(filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	check(image.save_png("res://dev/alien_air_review/" + filename) == OK, "Runtime capture failed")

func run() -> void:
	create_timer(125.0).timeout.connect(func(): quit(1))
	check(POC != null and EYE_ASSET != null and SPEEDER_ASSET != null, "POC/external models failed to load")
	scene = POC.instantiate() as BeeShmupStage
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	bee = scene.bee
	wave = scene.wave as BeeShmupAirWaveController
	check(bee != null and wave != null and is_equal_approx(scene.sector_length,76.0) and is_equal_approx(scene.scroll_speed,2.0), "Stage setup wrong")
	check(scene.get_node("Pollen").get_child_count() == 4 and wave.active_count() == 0, "Pollen/initial wave wrong")
	check(await until_wave(1), "Wave 1 never began")
	var probe := wave.get_node("Wave1Enemy1") as AlienProbeRanged
	check(probe.global_position.x > scene.camera.global_position.x + 8.0 and not probe.is_active(), "Probe did not enter from right")
	check(await until_active(probe) and probe.target == bee, "Wave 1 Probe not activated")
	probe.set_physics_process(false)
	probe.health.take_damage(100)
	await frames(2)
	check(await until_wave(2), "Wave 2 never began")
	var eye1 := wave.get_node("Wave2Enemy2") as EyeDroneEnemy
	check(eye1 != null and eye1.global_position.x > scene.camera.global_position.x + 8.0 and not eye1.is_active(), "EyeDrone entry wrong")
	bee.global_position = Vector3(scene.camera.global_position.x, 4.0, 0.0)
	check(await until_active(eye1), "EyeDrone failed to activate")
	var chase_start := eye1.global_position.distance_to(bee.global_position)
	await frames(24)
	check(eye1.current_state == AlienProbeRanged.State.POSITION or eye1.current_state == AlienProbeRanged.State.WINDUP, "EyeDrone did not chase")
	check(eye1.global_position.distance_to(bee.global_position) < chase_start, "EyeDrone did not close range")
	check(eye1.health.max_health == 18 and is_equal_approx(eye1.move_speed,4.5) and is_equal_approx(eye1.windup_time,0.4), "EyeDrone balance wrong")
	bee.global_position = eye1.global_position + Vector3(-3.1,0,0)
	bee.facing_x = 1.0
	await frames(2)
	check(bee.refresh_auto_aim() == eye1, "Bee auto-aim did not select EyeDrone")
	var shots := bee.shots_fired
	Input.action_press("throw_orange")
	await frames(2)
	Input.action_release("throw_orange")
	check(bee.shots_fired == shots + 1, "X did not fire at EyeDrone")
	check(await until_state(eye1,AlienProbeRanged.State.WINDUP), "EyeDrone did not wind up")
	check(eye1.telegraph.visible, "EyeDrone windup not visible")
	await capture_runtime("eye_runtime.png")
	check(await until_state(eye1,AlienProbeRanged.State.SHOOT) or eye1.projectile_fire_count > 0, "EyeDrone did not shoot")
	check(eye1.projectile_fire_count > 0, "EyeDrone did not launch projectile")
	check(eye1.shot_damage == 6 and is_equal_approx(eye1.cooldown_time,1.4), "EyeDrone shot/cooldown wrong")
	check(not eye1.telegraph.visible, "EyeDrone telegraph persisted after shot")
	for i in 180:
		if wave.spawned_count >= 3: break
		await frames(1)
	check(wave.spawned_count == 3 and wave.active_count() <= 2, "EyeDrone pair did not stagger")
	var eye2 := wave.get_node("Wave2Enemy3") as EyeDroneEnemy
	check(await until_active(eye2), "Second EyeDrone never activated")
	eye1.set_physics_process(false)
	eye2.set_physics_process(false)
	eye1.health.take_damage(100)
	eye2.health.take_damage(100)
	await frames(2)
	check(eye1.is_defeated() and eye2.is_defeated(), "EyeDrone death failed")
	check(await until_wave(3), "Wave 3 never began")
	var speeder := wave.get_node("Wave3Enemy4") as SpeederEnemy
	check(speeder != null and speeder.global_position.x > scene.camera.global_position.x + 8.0, "Speeder did not enter from right")
	check(await until_active(speeder), "Speeder failed to activate")
	check(speeder.health.max_health == 23 and is_equal_approx(speeder.dash_speed,9.5) and is_equal_approx(speeder.telegraph_time,0.7) and speeder.contact_damage == 13, "Speeder balance wrong")
	bee.global_position = Vector3(scene.camera.global_position.x, speeder.global_position.y, 0.0)
	bee.velocity = Vector3.ZERO
	bee.facing_x = 1.0
	check(await until_state(speeder,SpeederEnemy.Phase.TELEGRAPH), "Speeder telegraph missing")
	check(speeder.telegraph.visible and not speeder.dash_hitbox.enabled, "Speeder hitbox active before dash")
	await capture_runtime("speeder_runtime.png")
	check(bee.refresh_auto_aim() == speeder, "Bee auto-aim did not select Speeder")
	var hp := bee.health.current_health
	check(await until_state(speeder,SpeederEnemy.Phase.DASH), "Speeder never dashed")
	check(speeder.dash_hitbox.enabled and not speeder.telegraph.visible, "Speeder dash phase wrong")
	for i in 100:
		if bee.health.current_health < hp: break
		await frames(1)
	check(bee.health.current_health == hp - 13, "Speeder dash contact did not deal 13")
	for i in 160:
		if speeder.pass_count >= 1: break
		await frames(1)
	check(speeder.pass_count >= 1 and not speeder.dash_hitbox.enabled, "Speeder did not exit/re-enter cleanly")
	speeder.set_physics_process(false)
	speeder.health.take_damage(100)
	await frames(2)
	check(speeder.is_defeated(), "Speeder death failed")
	check(await until_wave(4), "Wave 4 never began")
	check(wave.active_count() <= 2 and wave.max_active_seen <= 2, "Three enemies overlapped")
	var final_eye := wave.get_node("Wave4Enemy5") as EyeDroneEnemy
	check(await until_active(final_eye), "Final EyeDrone did not enter")
	for i in 180:
		if wave.spawned_count >= 6: break
		await frames(1)
	check(wave.spawned_count == 6 and wave.active_count() == 2, "Final EyeDrone + Speeder missing")
	var final_speeder := wave.get_node("Wave4Enemy6") as SpeederEnemy
	check(await until_active(final_speeder), "Final Speeder did not enter")
	final_eye.set_physics_process(false)
	final_speeder.set_physics_process(false)
	var pollen := scene.get_node("Pollen/PollenD") as BeePollenPickup
	bee.health.take_damage(20)
	var before_heal := bee.health.current_health
	check(pollen.collect(bee), "Pollen collection failed")
	await frames(2)
	check(bee.health.current_health == mini(before_heal + 20,100) and scene.pollen_count == 1, "Pollen did not heal")
	final_eye.health.take_damage(100)
	final_speeder.health.take_damage(100)
	await frames(2)
	check(wave.is_complete() and wave.defeated_count == 6 and wave.max_active_seen <= 2, "Wave progression/completion wrong")
	for i in 1800:
		if scene.sector_complete: break
		await frames(1)
	check(scene.sector_complete and scene.status.text == "SECTOR DESPEJADO", "Sector did not complete")
	bee.health.take_damage(1000)
	await frames(2)
	check(bee.is_defeated and scene.status.text.contains("PLAYER DOWN"), "Player defeat failed")
	var old_id := scene.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id() != old_id, "R did not reload POC")
	var reset := current_scene as BeeShmupStage
	var reset_wave := reset.wave as BeeShmupAirWaveController
	check(reset.distance < 0.5 and reset_wave.wave_index == 0 and reset_wave.spawned_count == 0, "Scroll/waves did not reset")
	check(reset.bee.health.current_health == 100 and reset.get_node("Pollen").get_child_count() == 4, "Bee/pollen did not reset")
	print("BEE_SHMUP_AIR_VARIETY_OK four waves EyeDrone chase/shot Speeder dash/contact restart")
	quit(0)




