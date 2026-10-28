extends SceneTree
const MISSION := preload("res://scenes/bee_prototype/bee_mission_01.tscn")
var mission: Node3D
var bee: BeePlayer
var max_active_seen := 0

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
		if is_instance_valid(mission) and mission.is_inside_tree():
			var active := 0
			for enemy in mission.get_node("Enemies").get_children():
				if enemy.has_method("is_active") and enemy.is_active(): active += 1
			max_active_seen = maxi(max_active_seen, active)
			check(active <= 2, "More than two enemies active")
func release_controls() -> void:
	for action in ["move_left","move_right","move_forward","move_back","throw_orange"]:
		Input.action_release(action)
func fly_to(point: Vector3) -> void:
	for i in 600:
		var difference := point-bee.position
		release_controls()
		if absf(difference.x)>0.13: Input.action_press("move_right" if difference.x>0 else "move_left")
		if absf(difference.y)>0.13: Input.action_press("move_forward" if difference.y>0 else "move_back")
		if difference.length()<0.23:
			release_controls()
			await frames(4)
			return
		await frames(1)
	check(false,"Flight did not reach objective")
func fire_at(enemy: Node3D) -> void:
	release_controls()
	var dx := enemy.position.x-bee.position.x
	Input.action_press("move_right" if dx>0 else "move_left")
	await frames(1)
	Input.action_press("throw_orange")
	await frames(1)
	Input.action_release("throw_orange")
	await frames(6)
func fight(enemy: Node3D) -> void:
	for i in 600:
		if enemy.is_defeated():
			release_controls()
			return
		await fire_at(enemy)
	check(false,"Combat did not finish")
func run() -> void:
	create_timer(100.0).timeout.connect(func(): quit(1))
	var automated_started := Time.get_ticks_msec()
	mission=MISSION.instantiate()
	root.add_child(mission)
	current_scene=mission
	await frames(2)
	bee=mission.get_node("BeePlayer")
	var wasp := mission.get_node("Enemies/Wasp") as WaspEnemy
	var probe := mission.get_node("Enemies/Probe") as AlienProbeRanged
	var wasp_final := mission.get_node("Enemies/WaspFinal") as WaspEnemy
	var recovery := mission.get_node("RecoveryPollen") as BeePollenPickup
	check(mission.mission_state==mission.MissionState.INTRO,"Initial state failed")
	check(mission.get_node("Pollen").get_child_count()==3 and recovery != null,"Pollen count failed")
	check(not wasp.is_active() and not probe.is_active() and not wasp_final.is_active(),"Early enemies")
	var a: Vector3 = mission.get_node("Pollen/PollenA").position
	var b: Vector3 = mission.get_node("Pollen/PollenB").position
	var c: Vector3 = mission.get_node("Pollen/PollenC").position
	check(a.distance_to(b)>7 and b.distance_to(c)>8,"Pollen locations too close")
	check(c.distance_to(mission.SIGNAL_POSITION)>7,"Signal not separated from last pollen")
	check(mission.get_node("ObjectiveMarker").visible,"Pollen marker hidden")
	await fly_to(a)
	check(mission.pollen_count==1 and not wasp.is_active(),"First pollen progression failed")
	await fly_to(b)
	if mission.mission_state==mission.MissionState.INTRO: check(not wasp.is_active(),"Wasp activated during intro")
	for i in 180:
		if wasp.is_active(): break
		await frames(1)
	check(mission.pollen_count==2 and wasp.is_active() and mission.mission_state==mission.MissionState.WASP,"Wasp activation failed")
	check(mission.get_node("CanvasLayer/Narrative").text=="AVISPA TERRITORIAL","Wasp cue missing")
	await fight(wasp)
	check(not probe.is_active() and not wasp_final.is_active(),"Alien contact too early")
	await fly_to(c)
	check(mission.pollen_count==3 and mission.mission_state==mission.MissionState.ANOMALY,"Anomaly prerequisites failed")
	check(not probe.is_active() and mission.get_node("ObjectiveMarker/SignalVisual").visible,"Signal must require travel")
	await frames(5)
	check(not probe.is_active(),"Probe activated without reaching signal")
	await fly_to(mission.SIGNAL_POSITION)
	check(probe.is_active() and mission.mission_state==mission.MissionState.PROBE,"Probe did not appear at signal")
	for i in 600:
		if probe.health.current_health <= probe.health.max_health / 2.0: break
		await fire_at(probe)
	check(wasp_final.is_active() and mission.final_wasp_started,"Final Wasp failed at Probe half HP")
	check(probe.is_active() and max_active_seen==2,"Combined combat did not occur")
	await fight(probe)
	check(mission.mission_state==mission.MissionState.COMBINED and not wasp_final.is_defeated(),"Reveal started before final Wasp")
	bee.health.take_damage(20)
	var health_before_recovery := bee.health.current_health
	check(recovery.collect(bee) and bee.health.current_health>health_before_recovery and mission.pollen_count==3,"Recovery pollen did not heal or affected progress")
	await fight(wasp_final)
	check(mission.mission_state==mission.MissionState.REVEAL,"Reveal failed")
	for i in 350:
		if mission.mission_state==mission.MissionState.COMPLETE: break
		await frames(1)
	check(mission.completion_count==1 and mission.get_node("Presence").visible,"Completion/presence failed")
	await frames(10)
	check(mission.completion_count==1 and max_active_seen==2,"Duplicate completion or active enemies")
	print("MISSION_AUTOMATED_VALIDATION_SECONDS=%.2f (not player playtime)" % (float(Time.get_ticks_msec()-automated_started)/1000.0))
	bee.health.take_damage(1000)
	await frames(2)
	check(mission.down,"Defeat failed")
	var old_id:=mission.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id()!=old_id,"R reload failed")
	check(current_scene.pollen_count==0 and current_scene.completion_count==0 and current_scene.get_node("Pollen").get_child_count()==3,"Restart pollen/progress failed")
	check(not current_scene.get_node("Enemies/Wasp").is_active() and not current_scene.get_node("Enemies/Probe").is_active() and not current_scene.get_node("Enemies/WaspFinal").is_active(),"Restart enemies active")
	check(not current_scene.get_node("RecoveryPollen").was_collected and not current_scene.get_node("Presence").visible,"Restart recovery/reveal failed")
	var done:=current_scene
	current_scene=null
	done.queue_free()
	await process_frame
	for path in ["bee_combat_poc","bee_garden_poc"]:
		var scene: Node3D=load("res://scenes/bee_prototype/"+path+".tscn").instantiate()
		root.add_child(scene)
		await frames(2)
		check(scene.get_node("BeePlayer") is BeePlayer,"Previous POC failed")
		scene.queue_free()
		await process_frame
	print("BEE_MISSION_01_OK routine wasp signal probe combined reveal restart max_active=2")
	quit(0)
