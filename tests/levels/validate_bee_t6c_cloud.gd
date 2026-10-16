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
	await frames(3)
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
	await frames(75)
	check(cloud.population==3 and cloud.members.size()==3 and cloud.reserve==0,"Normal group has three independent flies, no hidden reserve")
	check(cloud.visual is MultiMeshInstance3D and cloud.instances.instance_count==3,"Single instanced visual")
	check(not cloud.is_in_group("bee_auto_aim_targets") and not cloud.has_node("HostileGlow"),"No shared target or transparent halo")
	check(cloud.visual.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"No fly shadows")
	for surface in cloud.instances.mesh.get_surface_count():
		var material: ShaderMaterial = cloud.instances.mesh.surface_get_material(surface)
		check(not material.shader.code.contains("ALPHA ="),"Opaque fly materials")
	for fly in cloud.members:
		check(fly.hp.max_health==1 and not fly.node.is_physics_processing() and not fly.node.is_processing(),"Passive one-hit members")
	cloud.global_position = Vector3(137,3,0)
	cloud._next_dive = 999.0
	cloud._next_volley = 999.0
	await frames(3)
	var before: int = cloud.shots_fired
	cloud._volley()
	check(cloud.shots_fired-before==3 and cloud.volleys==1,"All three fire in the same frame")
	check(S.VOLLEY_SECONDS>=3.5 and S.VOLLEY_SECONDS<=4.0 and S.DIVE_INTERVAL==6.0,"Configured volley and dive cadence")
	cloud._start_telegraph()
	var warned: Array = cloud.members.filter(func(fly): return fly.mode==1)
	check(warned.size()==2,"Exactly two flies detach")
	await frames(15)
	check(warned[0].cue_flash>0 and warned[0].cue_scale>1 and warned[0].cue_scale<=1.12,"Individual pulse and scale")
	check(cloud._warn.is_empty(),"No lines or bands")
	await frames(22)
	check(cloud.dives_started==2 and cloud.telegraphs.all(func(t):return t>=0.4 and t<=0.6),"Two dives follow their own warning")
	await frames(180)
	check(cloud.members.all(func(fly):return fly.mode==0),"Survivors return to V formation")
	cloud.global_position = Vector3(137,3,0)
	await frames(2)
	var shot := bee._spawn_projectile(Vector3.RIGHT,1)
	shot.hitbox._on_area_entered(cloud.members[0].hurt)
	check(cloud.health.current_health==2 and not cloud.members[0].node.alive,"One physical pellet releases one fly")
	shot.queue_free()
	await frames(20)
	check(cloud.reserve==0 and cloud.members[0].mode==5,"No replacement from an invisible cloud")
	before = cloud.shots_fired
	cloud._volley()
	check(cloud.shots_fired-before==2,"Only surviving flies fire")
	var bomb := DamageHitbox3D.new()
	bomb.damage = 32
	bomb.team_id = &"bee"
	root.add_child(bomb)
	bomb.set_enabled(true)
	for fly in cloud.members: fly.hurt.receive_hit(bomb)
	check(cloud.liberated and not stage.wave.active_units.has(cloud),"Bomb releases the remaining individuals and clears group once")
	bomb.queue_free()
	await frames(25)
	stage.distance = 240
	stage.wave._spawn({"family":"FlyCloud","event":607,"slot":0,"hard":false})
	stage.wave._spawn({"family":"FlyCloud","event":607,"slot":1,"hard":false})
	stage.wave._spawn({"family":"FlyCloud","event":607,"slot":2,"hard":false})
	check(stage.wave._fly_groups_alive()==2,"Never more than two simultaneous groups, including materializing groups")
	for group in stage.wave.active_units:
		check(group.population==5 and group.reserve==0,"Late waves use five one-hit flies")
	print("T6D_OK failures=",failures)
	quit(1 if failures else 0)
