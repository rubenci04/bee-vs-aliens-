extends SceneTree

const POC := preload("res://scenes/bee_prototype/bee_shmup_walker_poc.tscn")
const MODEL := preload("res://assets/external/approved/alien_ground/quaternius/Robot_Enemy_Legs_Gun_lFZfDh2hzP/Enemy_2Legs_Gun.fbx")

var stage: BeeShmupStage
var bee: BeePlayer
var wave: BeeShmupWalkerWaveController

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

func until_wave(number: int, limit := 1600) -> bool:
	for i in limit:
		if wave.wave_index >= number:
			return true
		await frames(1)
	return false

func until_state(walker: GroundWalkerEnemy, state: int, limit := 500) -> bool:
	for i in limit:
		if walker.current_state == state:
			return true
		await frames(1)
	return false

func capture_runtime(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	check(root.get_viewport().get_texture().get_image().save_png("res://dev/walker_review/" + filename) == OK, "Capture failed")

func run() -> void:
	create_timer(120.0).timeout.connect(func(): quit(1))
	check(POC != null and MODEL != null, "Walker scene/source missing")
	stage = POC.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	bee = stage.bee
	wave = stage.wave as BeeShmupWalkerWaveController
	check(bee != null and wave != null and stage.get_node("Walkers").get_child_count() == 4, "POC actors missing")
	check(is_equal_approx(stage.scroll_speed, 2.0) and is_equal_approx(stage.sector_length, 78.0) and stage.get_node("Pollen").get_child_count() == 5, "Stage length/scroll/pollen wrong")
	var a := wave.walker_a
	var b := wave.walker_b
	var c := wave.walker_c
	var d := wave.walker_d
	check(a.health.max_health == 45 and a.health.current_health == 45 and is_equal_approx(a.walk_speed, 1.9), "Walker HP/speed wrong")
	check(a.visual_root.scale == Vector3.ONE * 2.8 and is_equal_approx(a.get_node("VisualRoot/ModelPivot").position.y, 0.0) and is_equal_approx(a.global_position.y, -0.2), "Walker scale/grounding wrong")
	check(a.animation_player != null and a.animation_player.has_animation(&"CharacterArmature|Walk") and a.animation_player.has_animation(&"CharacterArmature|Shoot") and a.animation_player.has_animation(&"CharacterArmature|Death"), "Walker animations missing")
	check(not a.is_active() and not a.is_in_group("bee_auto_aim_targets") and wave.active_count() == 0, "Walker active early")
	check(await until_wave(1) and a.is_active() and a.current_state == GroundWalkerEnemy.State.ENTER, "Encounter 1 entry missing")
	check(a.visual_root.visible and a.hurtbox.monitorable and a.animation_player.current_animation == "CharacterArmature|Walk", "Entry visuals/collider wrong")
	check(await until_state(a, GroundWalkerEnemy.State.ADVANCE), "Walker did not advance")
	var start_x := a.global_position.x
	for i in 240:
		if a.global_position.x <= stage.camera.global_position.x + 4.2:
			break
		await frames(1)
	check(a.global_position.x <= stage.camera.global_position.x + 4.2 and a.distance_walked > 0.5 and a.global_position.x < start_x, "Walker failed to walk into view")
	await capture_runtime("walker_runtime.png")
	await frames(10)
	check(a.animation_player.current_animation == "CharacterArmature|Walk", "Walker did not keep Walk during advance")
	await capture_runtime("walker_walk.png")
	bee.global_position = Vector3(a.global_position.x - 3.8, 2.0, 0)
	bee.velocity = Vector3.ZERO
	bee.facing_x = 1.0
	await frames(2)
	check(bee.refresh_auto_aim() == a, "Bee cannot auto-aim Walker")
	check(await until_state(a, GroundWalkerEnemy.State.AIM), "Walker AIM missing")
	check(await until_state(a, GroundWalkerEnemy.State.WINDUP), "Walker WINDUP missing")
	check(a.aim_charge.visible and a.projectile_fire_count == 0 and is_equal_approx(a.windup_time, 0.65), "Windup telegraph/shot timing wrong")
	check(a.visual_root.rotation.y < -1.0 and a.aim_charge.position.x < 0, "Walker gun did not face Bee on the left")
	await capture_runtime("walker_windup.png")
	var walker_hp := a.health.current_health
	var shot_count := bee.shots_fired
	Input.action_press("throw_orange")
	await frames(2)
	Input.action_release("throw_orange")
	check(bee.shots_fired == shot_count + 1, "Bee X did not fire")
	for i in 80:
		if a.health.current_health < walker_hp:
			break
		await frames(1)
	check(a.health.current_health < walker_hp and a.get_node("HitFlash3D").activation_count > 0, "Walker ignored Bee X/HitFlash")
	var fired := {"projectile": null}
	a.projectile_fired.connect(func(projectile: AlienEnemyProjectile): fired.projectile = projectile)
	for i in 100:
		if fired.projectile != null:
			break
		await frames(1)
	check(fired.projectile != null and a.projectile_fire_count == 1 and a.animation_player.current_animation == "CharacterArmature|Shoot", "Shoot clip/projectile missing")
	var projectile := fired.projectile as AlienEnemyProjectile
	check(projectile.damage == 9 and is_equal_approx(projectile.speed, 6.5) and projectile.global_position.y > 2.5 and not a.aim_charge.visible, "Projectile values/muzzle wrong")
	var initial_direction := projectile.travel_direction
	bee.global_position.y += 0.08
	await frames(2)
	check(is_instance_valid(projectile) and projectile.travel_direction == initial_direction, "Projectile homed after firing")
	await capture_runtime("walker_shoot.png")
	var bee_hp := bee.health.current_health
	for i in 100:
		if bee.health.current_health < bee_hp:
			break
		await frames(1)
	check(bee.health.current_health == bee_hp - 9, "Walker projectile did not damage Bee")
	check(await until_state(a, GroundWalkerEnemy.State.RECOVERY), "Walker recovery missing")
	check(await until_state(a, GroundWalkerEnemy.State.REPOSITION), "Walker did not reposition")
	var reposition_x := a.global_position.x
	await frames(16)
	check(a.reposition_count == 1 and absf(a.global_position.x - reposition_x) > 0.2 and a.animation_player.current_animation == "CharacterArmature|Walk", "Walker stayed static after shooting")
	check(await until_state(a, GroundWalkerEnemy.State.ADVANCE, 100), "Walker did not finish reposition")
	check(absf(a.global_position.x - reposition_x) >= 1.4, "Walker did not travel the intended reposition distance")
	a.set_physics_process(false)
	bee.global_position = Vector3(a.global_position.x - 1.25, 0.75, 0)
	bee.velocity = Vector3.ZERO
	bee.facing_x = 1.0
	bee._place_melee_hitbox()
	var before_melee := a.health.current_health
	check(bee.start_melee(), "Bee melee rejected")
	for i in 15:
		if a.health.current_health < before_melee:
			break
		await frames(1)
	check(a.health.current_health < before_melee, "Walker ignored Bee Z melee")
	a.health.take_damage(100)
	await frames(2)
	check(a.is_defeated() and not a.is_active() and a.animation_player.current_animation == "CharacterArmature|Death" and not a.aim_charge.visible, "Walker death did not cancel combat/play Death")
	check(not a.is_in_group("bee_auto_aim_targets") and bee.refresh_auto_aim() != a and not a.hurtbox.monitorable, "Dead Walker remained targetable")
	await frames(18)
	await capture_runtime("walker_death.png")
	check(await until_wave(2) and b.is_active(), "Encounter 2 did not activate")
	check(not c.is_active() and not d.is_active(), "Encounter 3 activated too early")
	bee.global_position.y = 7.0
	b.health.take_damage(100)
	await frames(2)
	check(await until_wave(3) and c.is_active(), "Encounter 3 did not activate")
	check(not d.is_active(), "Final pair ignored stagger")
	for i in 250:
		if d.is_active():
			break
		await frames(1)
	check(d.is_active() and wave.active_count() == 2 and wave.max_active_seen <= 2, "Staggered pair/max active wrong")
	c.health.take_damage(100)
	d.health.take_damage(100)
	await frames(2)
	check(wave.is_complete() and wave.defeated_count == 4, "Walker encounters did not complete")
	var pollen := stage.get_node("Pollen/PollenE") as BeePollenPickup
	bee.health.take_damage(10)
	var before_heal := bee.health.current_health
	check(pollen.collect(bee), "Optional pollen not collectible")
	await frames(2)
	check(bee.health.current_health == mini(before_heal + 20, 100), "Pollen did not heal")
	for i in 1700:
		if stage.sector_complete:
			break
		await frames(1)
	check(stage.sector_complete and stage.status.text == "SECTOR DESPEJADO", "Walker sector did not finish")
	bee.health.take_damage(1000)
	await frames(2)
	check(bee.is_defeated and stage.status.text.contains("PLAYER DOWN"), "Defeat missing")
	var previous_id := stage.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id() != previous_id, "R did not reload POC")
	var reset := current_scene as BeeShmupStage
	var reset_wave := reset.wave as BeeShmupWalkerWaveController
	check(reset.distance < 0.5 and reset_wave.wave_index == 0 and reset_wave.defeated_count == 0, "Scroll/waves did not reset")
	check(reset.bee.health.current_health == 100 and reset.get_node("Pollen").get_child_count() == 5 and reset_wave.walker_a.health.current_health == 45, "Bee/pollen/Walker did not reset")
	reset.distance = 15.0
	reset._update_camera_and_bounds()
	reset.bee.global_position = Vector3(16, 2.0, 0)
	await frames(2)
	check(reset_wave.walker_a.is_active() and reset_wave.walker_a.visual_root.rotation.y > 1.0, "Walker did not face Bee on the right")
	reset.bee.global_position = Vector3(10, 2.0, 0)
	await frames(2)
	check(reset_wave.walker_a.visual_root.rotation.y < -1.0, "Walker did not turn left while free")
	check(await until_state(reset_wave.walker_a, GroundWalkerEnemy.State.WINDUP), "Restarted Walker did not reach windup")
	reset.bee.global_position = Vector3(16, 2.0, 0)
	await frames(3)
	check(reset_wave.walker_a.visual_root.rotation.y < -1.0, "Walker changed committed facing during windup")
	print("BEE_SHMUP_WALKER_OK grounded advance aim windup shoot projectile damage recovery reposition hitflash death three_encounters pollen restart")
	quit(0)
