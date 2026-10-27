extends SceneTree

const POC := preload("res://scenes/bee_prototype/bee_shmup_organic_alien_poc.tscn")
const ALIEN_ASSET := preload("res://assets/external/approved/alien_ground/quaternius/Alien_sUTLXji0aL/Alien by Quaternius - sUTLXji0aL.glb")

var scene: BeeShmupStage
var bee: BeePlayer
var wave: BeeShmupOrganicAlienWaveController

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

func until_wave(number: int, limit := 1500) -> bool:
	for i in limit:
		if wave.wave_index >= number: return true
		await frames(1)
	return false

func until_state(unit: OrganicAlienEnemy, wanted: int, limit := 600) -> bool:
	for i in limit:
		if unit.current_state == wanted: return true
		await frames(1)
	return false

func capture_runtime(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	var directory := ProjectSettings.globalize_path("res://dev/organic_alien_review")
	DirAccess.make_dir_recursive_absolute(directory)
	var picture := root.get_viewport().get_texture().get_image()
	check(picture.save_png(directory.path_join(filename)) == OK, "Capture failed: " + filename)

func run() -> void:
	root.size = Vector2i(1280, 720) # Tanda E: the aim assist checks the on-screen rect; the headless window is 64x64
	create_timer(160.0).timeout.connect(func(): quit(1))
	check(POC != null and ALIEN_ASSET != null, "POC or approved Alien missing")
	scene = POC.instantiate() as BeeShmupStage
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	bee = scene.bee
	wave = scene.wave as BeeShmupOrganicAlienWaveController
	check(bee != null and wave != null and is_equal_approx(scene.sector_length, 70.0) and is_equal_approx(scene.scroll_speed, 2.0), "Stage setup wrong")
	check(scene.get_node("Pollen").get_child_count() == 4 and wave.active_count() == 0, "Pollen/initial wave wrong")
	check(await until_wave(1), "Encounter 1 did not start")
	var alien := wave.get_node("Wave1Alien1") as OrganicAlienEnemy
	check(alien != null and alien.current_state == OrganicAlienEnemy.State.ENTER and alien.global_position.x > scene.camera.global_position.x + 8.0, "ENTER not from right")
	check(alien.health.max_health == 35 and alien.bite_damage == 13, "Alien HP/damage wrong")
	check(alien.is_active() and alien.is_in_group("bee_auto_aim_targets"), "Alien inactive/not targetable")
	check(await until_state(alien, OrganicAlienEnemy.State.HOVER), "Alien did not hover")
	check(await until_state(alien, OrganicAlienEnemy.State.STALK), "Alien did not stalk")
	bee.global_position = alien.global_position + Vector3(-3.1, 0.0, 0.0)
	bee.facing_x = 1.0
	await frames(2)
	check(alien.facing_x < 0.0 and alien.visual_root.rotation.y < 0.0, "Alien visual did not face Bee on the left")
	check(bee.refresh_auto_aim() == alien and bee.target_indicator.visible, "Auto-aim marker did not select Alien")
	check((bee.target_indicator.get_node("Marker") as Label3D).font_size == 28, "Shared reticle size not applied")
	await capture_runtime("alien_runtime.png")
	var original_hp := alien.health.current_health
	var shot := bee.fire()
	check(shot != null and shot.travel_direction.x > 0.0, "Bee could not shoot toward Alien")
	for i in 100:
		if alien.health.current_health < original_hp: break
		await frames(1)
	check(alien.health.current_health == original_hp - int(bee.weapon_profile()["damage"][0]) and alien.get_node("HitFlash3D").activation_count > 0, "Projectile/HitFlash failed")
	check(await until_state(alien, OrganicAlienEnemy.State.WINDUP), "WINDUP missing")
	check(alien.telegraph.visible and not alien.attack_hitbox.enabled, "WINDUP telegraph/hitbox wrong")
	check(is_equal_approx(alien.windup_time, 0.65) and is_equal_approx(alien.lunge_time, 0.38) and is_equal_approx(alien.recovery_time, 0.75), "Phase timings changed")
	bee.global_position = alien.global_position + Vector3(-3.1, 0.0, 0.0)
	bee.velocity = Vector3.ZERO
	await capture_runtime("alien_windup.png")
	var bee_hp := bee.health.current_health
	check(await until_state(alien, OrganicAlienEnemy.State.LUNGE), "LUNGE missing")
	check(alien.attack_hitbox.enabled and not alien.telegraph.visible and alien.last_clip.contains("Bite_Front"), "Bite animation/hitbox failed")
	var committed_direction := alien.lunge_direction
	var committed_yaw := alien.visual_root.rotation.y
	check(committed_direction.x < 0.0 and committed_yaw < 0.0, "Bite/lunge facing mismatch")
	bee.global_position.y += 0.25
	await frames(4)
	check(alien.lunge_direction.is_equal_approx(committed_direction), "LUNGE homed after launch")
	check(is_equal_approx(alien.visual_root.rotation.y, committed_yaw), "Visual flipped during LUNGE")
	await capture_runtime("alien_lunge.png")
	check(await until_state(alien, OrganicAlienEnemy.State.RECOVERY), "RECOVERY missing")
	check(not alien.attack_hitbox.enabled and not alien.telegraph.visible, "Bite did not end")
	check(bee.health.current_health == bee_hp - 13 and alien.hit_count == 1 and alien.attack_count == 1, "Lunge must hit Bee exactly once")
	await frames(12)
	check(bee.health.current_health == bee_hp - 13, "Recovery dealt extra damage")
	alien.health.take_damage(100)
	await frames(2)
	check(alien.is_defeated() and not alien.is_active() and not alien.is_in_group("bee_auto_aim_targets"), "Death/target cleanup failed")
	check(alien.last_clip.contains("Death") and not alien.attack_hitbox.enabled, "Death animation or hitbox cleanup failed")
	check(bee.refresh_auto_aim() != alien, "Dead Alien remained auto-aim target")
	await frames(10)
	await capture_runtime("alien_death.png")
	check(await until_wave(2), "Encounter 2 did not start")
	var second := wave.get_node("Wave2Alien2") as OrganicAlienEnemy
	check(second != null and is_equal_approx(second.global_position.y, 5.5) and second.current_state == OrganicAlienEnemy.State.ENTER, "Second entry height/state wrong")
	check(await until_state(second, OrganicAlienEnemy.State.HOVER), "Second Alien did not repeat entry")
	second.health.take_damage(100)
	await frames(2)
	check(await until_wave(3), "Encounter 3 did not start")
	var third := wave.get_node("Wave3Alien3") as OrganicAlienEnemy
	check(third != null and wave.active_count() == 1, "Final encounter did not begin staggered")
	for i in 160:
		if wave.spawned_count >= 4: break
		await frames(1)
	check(wave.spawned_count == 4 and wave.active_count() == 2 and wave.max_active_seen <= 2, "Final pair/max-two failed")
	var fourth := wave.get_node("Wave3Alien4") as OrganicAlienEnemy
	check(fourth != null and fourth.is_active(), "Second final Alien missing")
	var pollen := scene.get_node("Pollen/PollenD") as BeePollenPickup
	bee.health.take_damage(20)
	var damaged_hp := bee.health.current_health
	check(pollen.collect(bee), "Optional pollen did not collect")
	await frames(2)
	check(bee.health.current_health == mini(damaged_hp + 20, 100) and scene.pollen_count == 1, "Pollen heal/counter failed")
	third.health.take_damage(100)
	fourth.health.take_damage(100)
	await frames(2)
	check(wave.is_complete() and wave.defeated_count == 4 and wave.max_active_seen <= 2, "Waves failed to complete")
	for i in 1800:
		if scene.sector_complete: break
		await frames(1)
	check(scene.sector_complete and scene.status.text == "SECTOR COMPLETO", "Sector did not close")
	bee.health.take_damage(1000)
	await frames(2)
	check(bee.is_defeated and scene.status.text.contains("PLAYER DOWN"), "Bee defeat failed")
	var old_id := scene.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id() != old_id, "R did not reload POC")
	var reset := current_scene as BeeShmupStage
	var reset_wave := reset.wave as BeeShmupOrganicAlienWaveController
	check(reset.distance < 0.5 and reset_wave.wave_index == 0 and reset_wave.spawned_count == 0, "Scroll/waves did not reset")
	check(reset.bee.health.current_health == 100 and reset.get_node("Pollen").get_child_count() == 4, "Bee/pollen did not reset")
	print("BEE_SHMUP_ORGANIC_ALIEN_OK ambush_lunge once_per_attack autoaim hitflash death waves pollen restart")
	quit(0)
