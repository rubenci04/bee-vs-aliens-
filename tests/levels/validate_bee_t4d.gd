extends SceneTree
const GROUND := preload("res://scripts/levels/bee_ground_worm.gd")
var failures := 0
var worms: Array[AssetFauna] = []
var seen_shots := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _shot(node: Node) -> void:
	if not node is AlienEnemyProjectile or node.hitbox.attacker not in worms: return
	seen_shots += 1
	check(node.get_meta("shot_style", &"") == &"mud", "Reuses WormB's yellow mud projectile")
	check(node.damage == (4 if node.hitbox.attacker.kind == &"worm_rose" else 3), "Original ranged damage")
	check(node.travel_direction.y > .5 and is_zero_approx(node.travel_direction.z), "T6e: balls are lobbed UP")
	check(is_equal_approx(node.gravity, GROUND.BALL_GRAVITY), "T6e: they fall in an arc (gravity)")
func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 156
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(150,5,0)
	stage.bee.health.damage_blocked = true
	node_added.connect(_shot, CONNECT_DEFERRED)
	for i in 4:
		var family := "WormA" if i < 2 else "WormB"
		stage.wave._spawn({"family":family,"slot":i,"event":0,"hard":false})
		var worm := stage.wave.active_units.back() as AssetFauna
		worms.append(worm)
		worm.global_position = Vector3(158+i*.6,worm.ground_y,0)
		check(worm.health.max_health == BeeGameSettings.scaled_hp(BeeLevel01Controller.level_hp(family)), "HP remains unchanged")
		check(worm.attack_hitbox.damage == (5 if i < 2 else 7), "Original contact damage value")
		check(worm._ground_worm != null, "Level 01 ground adapter attached")
	var reference := GROUND.reference_interval(BeeLevel01Controller.ROSTER_FIRE_SLOWDOWN)
	check(is_equal_approx(reference,8.696), "Reference is the original full WormB spit cycle")
	check(is_equal_approx(worms[0]._ground_worm.volley_interval,reference/.6), "Early worm fires at 60 percent of reference")
	check(is_equal_approx(worms[2]._ground_worm.volley_interval,reference), "Compost keeps reference average cadence")
	var max_attacking := 0
	var emergence_seen := false
	for frame in 60*48:
		await physics_frame
		max_attacking = maxi(max_attacking,get_nodes_in_group(GROUND.ATTACK_GROUP).size())
		for worm in worms:
			check(is_equal_approx(worm.global_position.y,worm.ground_y), "No jump or vertical travel")
			check(worm._warn.is_empty(), "No dome, ellipse, line or ring warning")
			if worm._ground_worm.phase == GROUND.Phase.EMERGE and worm.rig.position.y < -.05 and worm.visual.visible: emergence_seen = true
			if worm._worm != null:
				check(worm._worm.lasers == 0 and worm._worm.leaps == 0 and not worm._worm._beam_box.enabled, "Legacy laser and leap cannot run")
	check(emergence_seen, "Visible gradual emergence")
	check(max_attacking <= 2 and max_attacking > 0, "No more than two attacking worms")
	check(seen_shots > 8, "Worms actually emit the lobbed balls")
	for worm in worms:
		var patterns: Array = worm._ground_worm.patterns_fired
		check(patterns.size() >= 2 and patterns.has(1) and patterns.has(2) and patterns.all(func(n): return n == 1 or n == 2), "T6e: volleys alternate 1 and 2 balls")
		worm.health.take_damage(99999)
	for i in 3: await physics_frame
	check(get_nodes_in_group(GROUND.ATTACK_GROUP).is_empty(), "Liberation releases attack slots")
	print("T4D_OK failures=",failures," shots=",seen_shots," max_attackers=",max_attacking," rose_interval=",reference/.6)
	quit(1 if failures else 0)
