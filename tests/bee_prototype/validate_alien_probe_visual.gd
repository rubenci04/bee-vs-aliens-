extends SceneTree
const POC := preload("res://scenes/bee_prototype/bee_combat_poc.tscn")
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
func wait_state(probe: AlienProbeRanged, state: int, limit: int) -> bool:
	for i in limit:
		if probe.current_state == state: return true
		await physics_frame
	return false
func run() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	var poc := POC.instantiate()
	root.add_child(poc)
	current_scene = poc
	await frames(3)
	var bee := poc.get_node("BeePlayer") as BeePlayer
	var probe := poc.get_node("Enemies/ProbeA") as AlienProbeRanged
	var visual := probe.get_node("VisualRoot/AlienProbeVisual") as Node3D
	check(not probe.has_node("VisualRoot/Body") and not probe.has_node("VisualRoot/Ring"),"Proxy duplicated")
	check(visual.find_child("SensorIris",true,false) != null and visual.find_child("EmitterAperture",true,false) != null,"GLB missing")
	check(is_equal_approx(probe.get_node("CollisionShape3D").shape.radius,0.55),"Collider changed")
	check(is_equal_approx(probe.get_node("Hurtbox3D/CollisionShape3D").shape.radius,0.55),"Hurtbox changed")
	check(probe.health.current_health == 25 and probe.move_speed == 2.2,"HP/speed changed")
	check(probe.minimum_range == 5 and probe.maximum_range == 7,"Preferred distance changed")
	check(is_equal_approx(probe.windup_time,0.45) and is_equal_approx(probe.cooldown_time,1.25),"Timing changed")
	bee.position = Vector3(-5.9,3,0)
	await frames(4)
	poc.get_node("Enemies/WaspA").health.take_damage(1000)
	bee.position = Vector3(-0.4,3,0)
	bee.set_physics_process(false)
	await frames(4)
	check(probe.is_active() and visual.is_visible_in_tree(),"Encounter B failed")
	probe.position = bee.position + Vector3(9,0,0)
	var position_before := probe.position
	await frames(10)
	check(probe.current_state == AlienProbeRanged.State.POSITION and probe.position != position_before,"POSITION did not move")
	probe.position = bee.position + Vector3(6,0,0)
	probe.velocity = Vector3.ZERO
	check(await wait_state(probe,AlienProbeRanged.State.WINDUP,90),"No WINDUP")
	check(probe.telegraph.visible,"Telegraph lost")
	var shot := {"projectile":null}
	probe.projectile_fired.connect(func(p: AlienEnemyProjectile): shot.projectile=p)
	check(await wait_state(probe,AlienProbeRanged.State.SHOOT,60),"No SHOOT")
	var projectile := shot.projectile as AlienEnemyProjectile
	check(is_instance_valid(projectile),"No projectile")
	check(projectile.speed == 6 and projectile.damage == 8 and projectile.lifetime == 2.5,"Projectile changed")
	check((-visual.global_basis.z).normalized().dot((bee.global_position-probe.global_position).normalized()) > 0.99,"Emitter aim mismatch")
	check(await wait_state(probe,AlienProbeRanged.State.COOLDOWN,5),"No cooldown")
	check(not probe.telegraph.visible,"Telegraph stayed on")
	for i in 90:
		if bee.health.current_health == 92: break
		await frames(1)
	check(bee.health.current_health == 92,"Projectile damage failed")
	probe.set_physics_process(false)
	var physical := probe.position
	var model := visual.get_node("Model") as Node3D
	var bob := model.position
	await frames(5)
	check(probe.position == physical and not model.position.is_equal_approx(bob),"Visual animation moved physics or stopped")
	for side in [-1.0,1.0]:
		bee.position = probe.position + Vector3(side*3,1,0)
		await frames(2)
		check((-visual.global_basis.z).normalized().dot((bee.global_position-probe.global_position).normalized()) > 0.99,"Facing/pitch mismatch")
	bee.position = Vector3(-0.4,3,0)
	probe.position = bee.position + Vector3(2,0,0)
	bee.facing_x = 1
	check(bee.refresh_auto_aim() == probe,"Auto-aim rejected Probe")
	var flash := probe.get_node("HitFlash3D") as HitFlash3D
	var flash_count := flash.activation_count
	var shot_dmg := int(bee.weapon_profile()["damage"][0]) # Tanda E: the Base shot is no longer 10
	var hp_before: int = probe.health.current_health
	check(bee.fire() != null,"X refused")
	for i in 30:
		if probe.health.current_health == hp_before - shot_dmg: break
		await frames(1)
	check(probe.health.current_health == hp_before - shot_dmg and flash.activation_count > flash_count,"X/HitFlash failed")
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		check(mesh.material_overlay != null,"HitFlash missed an imported mesh")
	probe.position = bee.position + Vector3(0.75,0,0)
	bee.set_physics_process(true) # Tanda E: the sting dash advances in Bee's own physics step
	check(bee.start_melee(),"Z refused")
	for i in 60:
		if probe.is_defeated(): break
		await frames(1)
	check(probe.is_defeated() and not visual.is_visible_in_tree(),"Z/death failed")
	check(poc.stage == poc.Stage.PAUSE_C,"Encounter did not continue")
	var dead_pose := model.transform
	await frames(4)
	check(model.transform == dead_pose,"Dead visual kept animating")
	bee.health.invulnerable = false # Tanda E: the sting dash / pirouette leave Bee protected for a moment
	bee.health.take_damage(1000)
	await frames(2)
	var old_id := poc.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(6)
	check(current_scene.get_instance_id() != old_id,"R failed")
	probe = current_scene.get_node("Enemies/ProbeA")
	check(probe.health.current_health == 25 and not probe.is_active(),"Restart state failed")
	check(probe.has_node("VisualRoot/AlienProbeVisual/Model"),"Restart lost visual")
	var done := current_scene
	current_scene = null
	done.queue_free()
	await process_frame
	var lab: Node3D = load("res://scenes/bee_prototype/visuals/alien_probe_visual_lab.tscn").instantiate()
	root.add_child(lab)
	await frames(2)
	check(lab.get_node("ProbeRight").is_visible_in_tree() and lab.get_node("ProbeLeft").is_visible_in_tree(),"Lab missing facings")
	lab.queue_free()
	await process_frame
	print("ALIEN_PROBE_VISUAL_OK GLB physics facing bob POSITION WINDUP SHOOT cooldown projectile autoaim X Z HitFlash death progression restart lab")
	quit(0)

