extends SceneTree
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
func run() -> void:
	var garden: Node3D = load("res://scenes/bee_prototype/bee_garden_poc.tscn").instantiate()
	root.add_child(garden)
	current_scene = garden
	await frames(3)
	assert(garden.get_node("ApprovedScenery").get_child_count() == 15)
	var bee: BeePlayer = garden.get_node("BeePlayer")
	Input.action_press("debug_attack")
	await frames(2)
	Input.action_release("debug_attack")
	assert(bee.melee_count == 1)
	Input.action_press("throw_orange")
	await frames(2)
	Input.action_release("throw_orange")
	assert(bee.shots_fired == 1)
	Input.action_press("move_forward")
	await frames(45)
	Input.action_release("move_forward")
	assert(bee.position.y > 5.0)
	Input.action_press("move_right")
	var wasp_seen := false
	var probe_seen := false
	for i in 300:
		await frames(1)
		var wasp: Node3D = garden.get_node("Enemies/Wasp")
		var probe: Node3D = garden.get_node("Enemies/Probe")
		wasp_seen = wasp_seen or (wasp.is_active() and wasp.is_visible_in_tree())
		probe_seen = probe_seen or (probe.is_active() and probe.is_visible_in_tree())
	Input.action_release("move_right")
	assert(bee.position.x > 14.0 and not bee.is_defeated)
	assert(wasp_seen and probe_seen)
	assert(garden.get_node("Pollen").get_child_count() == 3)
	print("GARDEN_GRAPHICAL_RUNTIME_OK movement Z X full_route Wasp Probe pollen=3 approved=15")
	current_scene = null
	garden.queue_free()
	await process_frame
	quit(0)
