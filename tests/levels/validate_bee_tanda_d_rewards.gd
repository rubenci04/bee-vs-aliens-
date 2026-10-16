extends SceneTree
## Tanda D (T7e) — the rewards after the robot (and the boss bomb) are the SAME toon medallions as the rest of the level, one icon per type.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	var wave := stage.wave as BeeLevel01Controller
	wave.set_physics_process(false)
	stage.bee.health.current_health = 40
	var before := stage.get_children().size()
	wave._post_robot_supplies()
	await physics_frame
	await physics_frame
	var fresh: Array[Node] = stage.get_children().slice(before)
	var bombs := 0
	var spreads := 0
	var heals := 0
	for item in fresh:
		if item is BeePowerupPickup:
			check(item.scene_file_path.begins_with("res://scenes/items/toon/"), "Reward uses the toon medallion scene (%s)" % item.scene_file_path)
			check(not item.has_node("PickupMedallion"), "No old-capsule dressing on top")
			check(not (item.get_node("Label") as Label3D).visible, "No prototype letter")
			if item.kind == BeePowerupPickup.Kind.BOMB: bombs += 1
			else: spreads += 1
		elif item.scene_file_path.ends_with("pollen_cluster.tscn"):
			heals += 1
	check(bombs == 1 and spreads == 1 and heals == 1, "One medallion per type: bomb, spread, healing cluster (%d/%d/%d)" % [bombs, spreads, heals])
	# The pickups still do what they did.
	var bee := stage.bee
	bee.bomb_charges = 1
	bee.spread_ammo = 0.0
	for item in fresh:
		if item is BeePowerupPickup:
			check(item.collect(bee), "Reward is collectable")
	check(bee.bomb_charges == 4 and bee.spread_ammo > 0.0, "Original +3 bombs and Spread amounts preserved")
	var bomb := wave.TOON_BOMB.instantiate() as BeePowerupPickup
	check(bomb.kind == BeePowerupPickup.Kind.BOMB, "Boss bomb is the toon bomb")
	print("TANDA_D_REWARDS failures=", failures)
	quit(1 if failures else 0)
