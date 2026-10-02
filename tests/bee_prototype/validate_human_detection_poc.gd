extends SceneTree
const POC := preload("res://scenes/bee_prototype/human_detection_poc.tscn")
var scene: Node3D
var bee: BeePlayer
var human: HumanObserver
var probe: AlienProbeRanged
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
func run() -> void:
	create_timer(45.0).timeout.connect(func(): quit(1))
	scene = POC.instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(3)
	bee = scene.get_node("BeePlayer") as BeePlayer
	human = scene.get_node("HumanObserver") as HumanObserver
	probe = scene.get_node("AlienProbe") as AlienProbeRanged
	check(bee != null and human != null and probe != null, "POC actors missing")
	check(human.current_state == HumanObserver.State.IDLE and human.suspicion==0, "Human initial state wrong")
	check(not probe.is_active(), "Probe active too early")
	check(human.get_node_or_null("Hurtbox3D") == null and not human.is_in_group("bee_auto_aim_targets"), "Human became combat target")
	await frames(25)
	check(human.suspicion == 0 and not human.can_see_bee(), "Out-of-range Bee raised suspicion")
	bee.position = Vector3(-6,1.5,0)
	await frames(10)
	check(human.suspicion == 0 and not human.can_see_bee(), "Occluder did not block line of sight")
	bee.position = Vector3(0,5.8,0)
	await frames(10)
	check(human.suspicion == 0 and not human.can_see_bee(), "Bee outside cone raised suspicion")
	bee.position = Vector3(-2,1.5,0)
	await frames(60)
	check(human.can_see_bee() and human.suspicion > 10.0, "Visible Bee did not raise suspicion")
	var before_shot := human.suspicion
	var hp_before := bee.health.current_health
	check(bee.fire()!=null, "Bee X fire rejected")
	await frames(3)
	check(human.suspicion > before_shot + 24.0, "Visible X did not add significant suspicion")
	var before_melee := human.suspicion
	check(bee.start_melee(), "Bee Z melee rejected")
	await frames(3)
	check(human.suspicion > before_melee + 7.0, "Visible Z did not add suspicion")
	check(human.get_node_or_null("HealthComponent") == null, "Human can be damaged by Bee")
	bee.position = Vector3(-6,1.5,0)
	var before_escape := human.suspicion
	await frames(75)
	check(human.suspicion < before_escape - 8.0, "Leaving vision did not reduce suspicion")
	bee.position = Vector3(-2,1.5,0)
	for i in 500:
		if human.current_state == HumanObserver.State.NOTICE: break
		await frames(1)
	check(human.current_state == HumanObserver.State.NOTICE and human.get_node("StateLabel").text=="?", "NOTICE missing")
	for i in 500:
		if human.current_state == HumanObserver.State.ALERT: break
		await frames(1)
	check(human.current_state == HumanObserver.State.ALERT and human.get_node("StateLabel").text=="!", "ALERT missing")
	for i in 500:
		if human.current_state == HumanObserver.State.HOSTILE: break
		await frames(1)
	check(human.current_state == HumanObserver.State.HOSTILE and human.suspicion==100, "HOSTILE missing")
	bee.position = Vector3(-10,1.5,0)
	await frames(20)
	check(human.current_state == HumanObserver.State.HOSTILE, "HOSTILE did not persist")
	bee.position = Vector3(0.45,1.1,0)
	var attack_hp := bee.health.current_health
	for i in 180:
		if bee.health.current_health < attack_hp: break
		await frames(1)
	check(human.attack_count > 0 and bee.health.current_health == attack_hp - human.attack_damage, "Human windup/hitbox did not deal 20 damage")
	check(not probe.is_active(), "Probe activated before sector")
	bee.position = Vector3(4.0,4.0,0)
	await frames(5)
	check(probe.is_active() and probe.target==bee, "Probe sector activation failed")
	var probe_hp := probe.health.current_health
	bee.facing_x = 1.0
	check(bee.fire()!=null, "Bee cannot fire at Probe")
	await frames(35)
	check(probe.health.current_health < probe_hp, "Probe combat failed")
	check(human.get_node_or_null("Hurtbox3D") == null, "Crossfire could damage human")
	bee.health.take_damage(1000)
	await frames(2)
	check(bee.is_defeated and scene.get_node("CanvasLayer/Status").text.contains("PLAYER DOWN"), "Defeat hint missing")
	var old_id := scene.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id()!=old_id, "R did not reload POC")
	check(current_scene.get_node("HumanObserver").suspicion==0 and current_scene.get_node("HumanObserver").current_state==HumanObserver.State.IDLE, "Human not reset")
	check(not current_scene.get_node("AlienProbe").is_active() and current_scene.get_node("BeePlayer").health.current_health==100, "Probe/Bee not reset")
	print("HUMAN_DETECTION_POC_OK cone occlusion suspicion X Z NOTICE ALERT HOSTILE attack=20 Probe restart")
	var done := current_scene
	current_scene=null
	done.queue_free()
	await process_frame
	quit(0)
