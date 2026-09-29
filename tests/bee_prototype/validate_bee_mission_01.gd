extends SceneTree
const MISSION := preload("res://scenes/bee_prototype/bee_mission_01.tscn")
var mission: Node3D
var bee: BeePlayer

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
	check(false,"Flight did not reach pollen")
func fight(enemy: Node3D) -> void:
	for i in 600:
		if enemy.is_defeated():
			release_controls()
			return
		release_controls()
		var dx := enemy.position.x-bee.position.x
		Input.action_press("move_right" if dx>0 else "move_left")
		# Face and fire through the real player input path; no enemy HP injection.
		await frames(1)
		Input.action_press("throw_orange")
		await frames(1)
		Input.action_release("throw_orange")
		await frames(6)
	check(false,"Combat did not finish")
func run() -> void:
	create_timer(100.0).timeout.connect(func(): quit(1))
	var started := Time.get_ticks_msec()
	mission=MISSION.instantiate()
	root.add_child(mission)
	current_scene=mission
	await frames(2)
	bee=mission.get_node("BeePlayer")
	check(mission.mission_state==mission.MissionState.INTRO,"Initial state failed")
	check(mission.get_node("Pollen").get_child_count()==3,"Pollen count failed")
	var wasp := mission.get_node("Enemies/Wasp") as WaspEnemy
	var probe := mission.get_node("Enemies/Probe") as AlienProbeRanged
	check(not wasp.is_active() and not probe.is_active(),"Early enemies")
	await fly_to(mission.get_node("Pollen/PollenA").position)
	check(mission.pollen_count==1 and not wasp.is_active(),"First pollen progression failed")
	await fly_to(mission.get_node("Pollen/PollenB").position)
	check(mission.pollen_count==2 and wasp.is_active() and mission.mission_state==mission.MissionState.WASP,"Wasp activation failed")
	await fight(wasp)
	check(not probe.is_active(),"Probe appeared before all pollen")
	await fly_to(mission.get_node("Pollen/PollenC").position)
	check(mission.pollen_count==3 and mission.mission_state==mission.MissionState.ANOMALY,"Anomaly prerequisites failed")
	check(mission.get_node("CanvasLayer/Narrative").text=="SEÑAL DESCONOCIDA DETECTADA","Anomaly message failed")
	for i in 180:
		if probe.is_active(): break
		await frames(1)
	check(probe.is_active() and mission.mission_state==mission.MissionState.PROBE,"Probe failed to appear")
	await fight(probe)
	check(mission.mission_state==mission.MissionState.REVEAL,"Reveal failed")
	for i in 350:
		if mission.mission_state==mission.MissionState.COMPLETE: break
		await frames(1)
	check(mission.completion_count==1 and mission.get_node("Presence").visible,"Completion/presence failed")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/bee_prototype/mission_complete.png")
	await frames(10)
	check(mission.completion_count==1,"Duplicate completion")
	print("MISSION_RUNTIME_COMPLETE seconds=",float(Time.get_ticks_msec()-started)/1000.0," health=",bee.health.current_health)
	bee.health.take_damage(1000)
	await frames(2)
	check(mission.down,"Defeat failed")
	var old_id:=mission.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id()!=old_id,"R reload failed")
	check(current_scene.pollen_count==0 and current_scene.completion_count==0 and current_scene.get_node("Pollen").get_child_count()==3,"Restart not clean")
	check(not current_scene.get_node("Enemies/Wasp").is_active() and not current_scene.get_node("Enemies/Probe").is_active(),"Restart enemies active")
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
	print("BEE_MISSION_01_OK actual_flight_pickups_combat_reveal_completion_restart")
	quit(0)

