extends SceneTree
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
func run() -> void:
	var scene := load("res://scenes/bee_prototype/bee_garden_poc.tscn") as PackedScene
	check(scene != null,"Garden missing")
	var garden := scene.instantiate()
	root.add_child(garden)
	current_scene = garden
	await frames(3)
	var bee := garden.get_node("BeePlayer") as BeePlayer
	check(bee != null,"Bee missing")
	check(garden.get_node("Enemies/Wasp") is WaspEnemy and garden.get_node("Enemies/Probe") is AlienProbeRanged,"Enemies missing")
	check(garden.get_node("Pollen").get_child_count()==3,"Pollen missing")
	check(garden.decoration_count < 150 and garden.decoration_count > 50,"Scenery not lightweight or missing")
	var start := bee.position
	Input.action_press("move_right")
	await frames(12)
	Input.action_release("move_right")
	check(bee.position.x > start.x+0.2,"X movement failed")
	Input.action_press("move_forward")
	await frames(12)
	Input.action_release("move_forward")
	check(bee.position.y > start.y+0.2 and bee.position.z==0,"Vertical flight or plane failed")
	bee.position = Vector3(-16,9,2)
	await frames(2)
	check(bee.position.x>=-15 and bee.position.y<=8.2 and bee.position.z==0,"Limits failed")
	bee.position = Vector3(-6.9,4,0)
	await frames(3)
	check(garden.get_node("Enemies/Wasp").is_active(),"Wasp proximity failed")
	bee.position = Vector3(4.1,4,0)
	await frames(3)
	check(garden.get_node("Enemies/Probe").is_active(),"Probe proximity failed")
	var pollen := garden.get_node("Pollen/PollenA") as BeePollenPickup
	bee.health.take_damage(25)
	check(pollen.collect(bee) and bee.health.current_health==95,"Pollen healing changed")
	await frames(2)
	bee.health.take_damage(1000)
	await frames(2)
	check(garden.get_node("CanvasLayer/Status").text.contains("PLAYER DOWN"),"Defeat hint missing")
	var old_id := garden.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id()!=old_id,"Garden restart failed")
	check(current_scene.get_node("Pollen").get_child_count()==3,"Restart pollen failed")
	var done := current_scene
	current_scene=null
	done.queue_free()
	await process_frame
	var previous := load("res://scenes/bee_prototype/bee_combat_poc.tscn") as PackedScene
	var combat := previous.instantiate()
	root.add_child(combat)
	await frames(2)
	check(combat.get_node("BeePlayer") is BeePlayer,"Combat regression")
	combat.queue_free()
	await process_frame
	print("BEE_GARDEN_POC_OK flight limits Z enemies pollen restart previous_combat")
	quit(0)
