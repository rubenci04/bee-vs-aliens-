extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func run() -> void:
	var bee: BeePlayer = load("res://scenes/bee_prototype/bee_player.tscn").instantiate()
	root.add_child(bee)
	bee.set_physics_process(false)
	var visual := bee.get_node("VisualRoot/BeeVisual")
	var wing := visual.find_child("Wing_L", true, false) as Node3D
	require(wing != null and visual.find_child("Wing_R",true,false) != null,"Independent wings missing")
	require(is_equal_approx(bee.get_node("CollisionShape3D").shape.radius,0.28),"Collider changed")
	require(bee.health.current_health == 100 and bee.melee_damage == 15,"Gameplay values changed")
	var before := wing.rotation
	var position_before := bee.position
	for i in 3: await process_frame
	require(not wing.rotation.is_equal_approx(before),"Wingbeat is not running")
	require(bee.position == position_before,"Visual moved physics body")
	require(is_equal_approx(bee.visual_root.rotation.y,-PI/2),"Initial right facing is wrong")
	Input.action_press("move_left")
	bee._physics_process(1.0 / 60.0)
	Input.action_release("move_left")
	require(is_equal_approx(bee.visual_root.rotation.y,PI/2),"Left facing is wrong")
	require(visual.is_visible_in_tree() and not bee.has_node("VisualRoot/Body"),"Visual hidden or proxy duplicated")
	var flash := bee.get_node("HitFlash3D") as HitFlash3D
	bee.health.take_damage(1)
	require(flash.is_flashing(),"Imported meshes did not receive HitFlash")
	bee.health.take_damage(1000)
	var stopped := wing.rotation
	for i in 3: await process_frame
	require(wing.rotation == stopped,"Wings kept moving after defeat")
	bee.queue_free()
	await process_frame
	var lab: Node3D = load("res://scenes/bee_prototype/visuals/bee_player_visual_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	require(lab.get_node("LeftFacing/VisualRoot/BeeVisual").is_visible_in_tree(),"Lab visual missing")
	require(not lab.get_node("RightFacing").is_physics_processing(),"Lab actor is moving")
	lab.queue_free()
	await process_frame
	print("BEE_VISUAL_OK wings facing collider health melee hitflash defeat")
	quit(0)


