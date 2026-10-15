extends SceneTree
const S := preload("res://scripts/game/bee_fly_cloud_settings.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("Juice").set_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 138
	stage._update_camera_and_bounds()
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(134,3,0)
	stage.wave._spawn({"family":"FlyCloud","event":606,"slot":0,"hard":false})
	var cloud = stage.wave.active_units.back()
	cloud.global_position = Vector3(137,3,0)
	cloud.set("_next_dive",999.0)
	await frames(3)
	check(cloud.health.max_health == 60 and cloud.members.size()==24 and cloud.reserve==36,"Factory: sixty one-hit members, twenty-four nodes/visible, thirty-six reserve")
	check(not cloud.is_in_group("bee_auto_aim_targets") and not cloud.has_node("HostileGlow"),"No shared-body aim target or transparent halo")
	check(cloud.visual is MultiMeshInstance3D and cloud.instances.instance_count==24,"One instanced visual for the whole cloud")
	check(cloud.visual.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and cloud.find_children("*","Light3D",true,false).is_empty(),"No fly shadows or lights")
	check(cloud.find_children("*","MeshInstance3D",true,false).is_empty() and cloud.find_children("*","AnimationPlayer",true,false).is_empty(),"No per-piece meshes or animation players")
	for fly in cloud.members:
		check(fly.hp.max_health==1 and not fly.node.is_processing() and not fly.node.is_physics_processing(),"Passive one-hit target; only cloud moves it")
		check(fly.attack.get_child(0).disabled,"Formation flies have no active dive collision shape")
	for surface in cloud.instances.mesh.get_surface_count():
		var mat: ShaderMaterial = cloud.instances.mesh.surface_get_material(surface)
		check(not mat.shader.code.contains("ALPHA ="),"Opaque body, wings and cue; no alpha fade")
	# Real configured projectile -> hitbox -> individual body -> one member removed.
	var shot := bee._spawn_projectile(Vector3.RIGHT,3)
	shot.hitbox._on_area_entered(cloud.members[0].hurt)
	check(cloud.members[0].hp.current_health==0 and cloud.health.current_health==59 and cloud.reserve==36,"One Base impact removes exactly one fly, not the whole cloud")
	shot.queue_free()
	await frames(20)
	check(cloud.reserve==35 and cloud.members[0].hp.current_health==1 and cloud.health.current_health==59,"Reserve enters after the short opaque departure")
	shot = bee._spawn_projectile(Vector3.RIGHT,1)
	shot.hitbox._on_area_entered(cloud.members[1].hurt)
	check(cloud.health.current_health==58,"Even a one-damage side pellet is one impact")
	shot.queue_free()
	await frames(20)
	var bomb := DamageHitbox3D.new()
	bomb.damage = 32
	bomb.team_id = &"bee"
	bomb.attacker_path = NodePath(bee.get_path())
	root.add_child(bomb)
	bomb.set_enabled(true)
	for fly in cloud.members: fly.hurt.receive_hit(bomb)
	check(cloud.health.current_health==34 and cloud.reserve==34,"Area damage clears visible members once, not hidden reserve")
	await frames(20)
	for fly in cloud.members: fly.hurt.receive_hit(bomb)
	check(cloud.health.current_health==34,"Same hitbox cannot repeatedly farm a reused slot")
	bomb.queue_free()
	cloud.configure_population(60)
	cloud.global_position = Vector3(237,3,0)
	await frames(3)
	check(cloud.members.all(func(fly): return not fly.collision_active and fly.hp.damage_blocked),"Far off-screen flies have no live collision")
	cloud.global_position = Vector3(137,3,0)
	await frames(3)
	check(cloud.members.all(func(fly): return fly.collision_active),"On-screen flies regain collision")
	check(S.WARNING_SECONDS>=0.4 and S.WARNING_SECONDS<=0.6 and S.WARNING_SCALE<=1.12,"Own readable anticipation follows T3j")
	cloud._start_telegraph()
	cloud.set("_next_dive",999.0)
	var warned: Array = cloud.members.filter(func(fly): return fly.mode==1)
	check(warned.size()>=2 and warned.size()<=3 and cloud.members.all(func(fly): return not fly.attack.enabled),"Two/three detach with no premature damage")
	await frames(15)
	# Dummy RenderingServer returns identity/default instance data; verify the exact CPU inputs here.
	check(cloud.members[0].cue_flash>0 and cloud.members[0].cue_scale<=1.121 and cloud.members[0].cue_scale>1.0,"Per-fly pulse and small scale, no whole-cloud cue")
	check(cloud.find_children("*Telegraph*","Node3D",true,false).is_empty() and cloud._warn.is_empty(),"No lines or warning bands")
	await frames(22)
	var diving: Array = cloud.members.filter(func(fly): return fly.mode==2)
	check(diving.size()>=2 and cloud.telegraphs.all(func(t): return t>=0.4 and t<=0.6),"Each dive waits its own 0.5-second warning")
	bee.health.damage_blocked = false
	bee.health.invulnerable = false
	var before := bee.health.current_health
	if not diving.is_empty(): diving[0].attack._on_area_entered(bee.get_node("Hurtbox3D"))
	check(before-bee.health.current_health==3,"Dive applies three damage like a small enemy shot")
	bee.health.damage_blocked = true
	await frames(240)
	check(cloud.members.all(func(fly): return fly.mode==0),"Surviving divers return to formation")
	var at: Vector3 = cloud.members[0].node.global_position
	paused = true
	for i in 4: await process_frame
	check(cloud.members[0].node.global_position==at,"Pause stops the single movement administrator")
	paused = false
	var liberated := [0]
	cloud.liberated_now.connect(func(_unit): liberated[0]+=1)
	cloud.set_physics_process(false) # A frozen encounter must still finish its short opaque departure.
	cloud.health.take_damage(99999)
	await frames(22)
	check(liberated[0]==1 and cloud.reserve==0 and cloud.state==AssetFauna.State.DONE,"Cloud completes once; no reserve or invisible attackers remain")
	check(cloud.members.all(func(fly): return not fly.node.is_active() and not fly.attack.enabled),"No attacks/aim targets after liberation")
	# Continuous input and real traveling projectiles must also clear the reserve, not just callback tests.
	stage.wave._spawn({"family":"FlyCloud","event":607,"slot":0,"hard":false})
	var bank = stage.wave.active_units.back()
	bank.global_position = Vector3(137,3,0)
	bank.set("_next_dive",999.0)
	await frames(3)
	bee.spread_ammo = 0
	bee.honey_left = 0
	bee.set_physics_process(true)
	Input.action_press("throw_orange")
	var elapsed := 0.0
	for i in 60*12:
		if bank.liberated: break
		for fly in bank.members:
			if fly.node.alive and fly.collision_active:
				bee.set_aim_point(fly.node.global_position)
				break
		await physics_frame
		elapsed += 1.0/60.0
	Input.action_release("throw_orange")
	check(bank.liberated and bank.health.current_health==0 and elapsed<12,"Continuous Base clears all sixty moving members including reserve")
	print("T6C_CONTINUOUS seconds=",elapsed)
	print("T6C_OK failures=",failures)
	quit(1 if failures else 0)
