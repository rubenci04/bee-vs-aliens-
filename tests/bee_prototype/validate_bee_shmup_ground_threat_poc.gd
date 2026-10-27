extends SceneTree
const POC := preload("res://scenes/bee_prototype/bee_shmup_ground_threat_poc.tscn")
const MODEL := preload("res://assets/external/approved/ground_threat/kenney/kenney_space-kit/Models/GLTF format/turret_single.glb")
var scene: BeeShmupStage
var bee: BeePlayer
var wave: BeeShmupGroundWaveController
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok,message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
func until_wave(number: int, limit := 1400) -> bool:
	for i in limit:
		if wave.wave_index >= number: return true
		await frames(1)
	return false
func until_state(turret: GroundTurretEnemy, state: int, limit := 200) -> bool:
	for i in limit:
		if turret.current_state == state: return true
		await frames(1)
	return false
func capture_runtime(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	check(image.save_png("res://dev/ground_threat_review/"+name) == OK,"Runtime capture failed")
func run() -> void:
	root.size = Vector2i(1280, 720) # Tanda E: the aim assist checks the on-screen rect; the headless window is 64x64
	create_timer(115.0).timeout.connect(func(): quit(1))
	check(POC != null and MODEL != null,"Scene/turret asset failed to load")
	scene = POC.instantiate() as BeeShmupStage
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	bee = scene.bee
	wave = scene.wave as BeeShmupGroundWaveController
	check(bee != null and wave != null and scene.get_node("Turrets").get_child_count() == 4,"Core actors missing")
	check(is_equal_approx(scene.scroll_speed,2.0) and is_equal_approx(scene.sector_length,62.0),"Scroll/length wrong")
	check(scene.get_node("Pollen").get_child_count() == 4 and wave.active_count() == 0,"Pollen/initial state wrong")
	var a := wave.turret_a
	var b := wave.turret_b
	var c := wave.turret_c
	var d := wave.turret_d
	check(is_equal_approx(a.global_position.y,-0.2) and a.health.max_health == 30,"Turret ground/HP wrong")
	check(not a.is_active() and not b.is_active() and not c.is_active() and not d.is_active(),"Turrets active too early")
	check(await until_wave(1) and a.is_active(),"Encounter 1 did not activate by scroll")
	check(a.global_position == Vector3(13,-0.2,0),"Turret moved off its ground position")
	bee.global_position = Vector3(a.global_position.x-4.0,1.0,0)
	bee.velocity = Vector3.ZERO
	bee.facing_x = 1.0
	await frames(2)
	check(bee.refresh_auto_aim() == a,"Bee could not aim downward at turret")
	check(await until_state(a,GroundTurretEnemy.State.WINDUP),"Turret never entered WINDUP")
	check(a.telegraph.visible and a.projectile_fire_count == 0,"Turret telegraph/shot timing wrong")
	await capture_runtime("turret_windup.png")
	var turret_hp := a.health.current_health
	var shot_count := bee.shots_fired
	Input.action_press("throw_orange")
	await frames(2)
	Input.action_release("throw_orange")
	check(bee.shots_fired == shot_count+1,"Bee X did not fire at turret")
	for i in 55:
		if a.health.current_health < turret_hp: break
		await frames(1)
	check(a.health.current_health < turret_hp and a.get_node("HitFlash3D").activation_count > 0,"Turret did not take X damage/HitFlash")
	var fired := {"projectile": null}
	a.projectile_fired.connect(func(projectile: AlienEnemyProjectile): fired.projectile = projectile)
	check(await until_state(a,GroundTurretEnemy.State.SHOOT) or a.projectile_fire_count > 0,"Turret never fired")
	check(a.projectile_fire_count > 0 and fired.projectile != null,"Projectile was not spawned")
	var projectile := fired.projectile as AlienEnemyProjectile
	check(projectile.damage == 9 and is_equal_approx(projectile.speed,6.5) and is_equal_approx(projectile.lifetime,2.5),"Projectile values wrong")
	var initial_direction := projectile.travel_direction
	bee.global_position.y += 0.1
	await frames(2)
	check(is_instance_valid(projectile) and projectile.travel_direction == initial_direction,"Projectile homed after firing")
	await capture_runtime("turret_projectile.png")
	var bee_hp := bee.health.current_health
	for i in 80:
		if bee.health.current_health < bee_hp: break
		await frames(1)
	check(bee.health.current_health == bee_hp-9,"Projectile did not hit Bee for 9")
	await frames(2)
	check(not is_instance_valid(projectile),"Projectile persisted after impact")
	check(await until_state(a,GroundTurretEnemy.State.COOLDOWN),"Cooldown missing")
	check(not a.telegraph.visible,"Telegraph persisted after shot")
	a.set_physics_process(false)
	bee.global_position = Vector3(a.global_position.x-0.86,0.72,0)
	bee.velocity = Vector3.ZERO
	bee.facing_x = 1.0
	bee._place_melee_hitbox()
	var before_melee := a.health.current_health
	check(bee.start_melee(),"Bee melee rejected")
	for i in 45:
		if a.health.current_health < before_melee: break
		await frames(1)
	check(a.health.current_health < before_melee,"Reachable turret ignored melee")
	a.health.take_damage(100)
	await frames(2)
	check(a.is_defeated() and not a.is_active() and not a.telegraph.visible,"Turret death did not cancel combat")
	check(bee.refresh_auto_aim() != a,"Dead turret remained auto-aim target")
	check(await until_wave(2) and b.is_active(),"Encounter 2 did not activate")
	check(not c.is_active() and not d.is_active(),"Later turrets activated early")
	b.health.take_damage(100)
	await frames(2)
	check(await until_wave(3) and c.is_active(),"Encounter 3 did not activate")
	for i in 300:
		if d.is_active(): break
		await frames(1)
	check(d.is_active() and wave.active_count() == 2 and wave.max_active_seen <= 2,"Staggered pair/max active wrong")
	c.health.take_damage(100)
	d.health.take_damage(100)
	await frames(2)
	check(wave.is_complete() and wave.defeated_count == 4,"Final encounter did not complete")
	for i in 1200:
		if scene.sector_complete: break
		await frames(1)
	check(scene.sector_complete and scene.status.text == "SECTOR DESPEJADO","Sector did not finish")
	bee.health.take_damage(1000)
	await frames(2)
	check(bee.is_defeated and scene.status.text.contains("PLAYER DOWN"),"Defeat text missing")
	var old_id := scene.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id() != old_id,"R did not reload POC")
	var reset := current_scene as BeeShmupStage
	var reset_wave := reset.wave as BeeShmupGroundWaveController
	check(reset.distance < 0.5 and reset_wave.wave_index == 0 and reset_wave.defeated_count == 0,"Scroll/waves did not reset")
	check(reset.bee.health.current_health == 100 and reset.get_node("Pollen").get_child_count() == 4,"Bee/pollen did not reset")
	reset.distance = 5.6
	reset._update_camera_and_bounds()
	await frames(2)
	check(reset_wave.turret_a.is_active(),"Bypass setup failed")
	reset.distance = 20.0
	reset._update_camera_and_bounds()
	await frames(2)
	check(not reset_wave.turret_a.is_active() and reset_wave.resolved_count == 1 and reset_wave.defeated_count == 0,"Off-screen turret did not resolve as bypass")
	reset.distance = 22.0
	reset._update_camera_and_bounds()
	await frames(2)
	check(reset_wave.wave_index == 2 and reset_wave.turret_b.is_active(),"Bypass blocked next encounter")
	print("BEE_SHMUP_GROUND_THREAT_OK autoaim windup projectile damage melee death 3 encounters restart")
	quit(0)


