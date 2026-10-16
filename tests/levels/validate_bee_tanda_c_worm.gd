extends SceneTree
## Tanda C (T6e) — GUSANO: emerges from the soil and lobs 1-2 slow balls UP that fall in an arc. No jump, no laser, no dome, no lines.
const GROUND := preload("res://scripts/levels/bee_ground_worm.gd")
var failures := 0
var worms: Array[AssetFauna] = []
var balls: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _added(node: Node) -> void:
	if node is AlienEnemyProjectile and node.hitbox.attacker in worms:
		balls.append({"gravity": node.gravity, "dir": node.travel_direction, "style": node.get_meta("shot_style", &""), "damage": node.damage, "who": worms.find(node.hitbox.attacker)})
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
	stage.bee.global_position = Vector3(150, 3, 0)
	stage.bee.health.damage_blocked = true
	node_added.connect(_added, CONNECT_DEFERRED)
	for i in 4:
		var family := "WormA" if i < 2 else "WormB"
		stage.wave._spawn({"family": family, "slot": i, "event": 0, "hard": false})
		var worm := stage.wave.active_units.back() as AssetFauna
		worms.append(worm)
		worm.global_position = Vector3(158 + i * 0.6, worm.ground_y, 0)
		check(worm.health.max_health == BeeGameSettings.scaled_hp(BeeLevel01Controller.level_hp(family)), "HP remains unchanged")
	var emerged := false
	var apex := 0.0
	var max_attacking := 0
	for frame in 60 * 50:
		await physics_frame
		max_attacking = maxi(max_attacking, get_nodes_in_group(GROUND.ATTACK_GROUP).size())
		for worm in worms:
			check(is_equal_approx(worm.global_position.y, worm.ground_y), "No jump or vertical travel")
			check(worm._warn.is_empty(), "No dome, line, strip or ring warning")
			if worm._worm != null:
				check(worm._worm.lasers == 0 and worm._worm.leaps == 0, "No laser and no leap")
			if worm._ground_worm.phase == GROUND.Phase.EMERGE and worm.rig.position.y < -0.05 and worm.visual.visible: emerged = true
		for ball in get_nodes_in_group("alien_projectiles"):
			if ball is AlienEnemyProjectile and ball.hitbox.attacker in worms:
				apex = maxf(apex, ball.global_position.y)
	check(emerged, "It visibly emerges from the soil")
	check(balls.size() >= 6, "Balls were thrown (%d)" % balls.size())
	check(apex > 3.0, "The balls climb high (apex %.2f)" % apex)
	for b in balls:
		check(b.gravity > 0.0 and b.dir.y > 0.5, "Lobbed upward, then falling")
		check(b.style == &"mud", "Worm palette: mud")
	for i in worms.size():
		var patterns: Array = worms[i]._ground_worm.patterns_fired
		check(patterns.size() >= 2 and patterns.all(func(n): return n == 1 or n == 2) and patterns.has(1) and patterns.has(2), "1 and 2 balls alternate (%s)" % str(patterns))
		check(worms[i].shots_fired == balls.filter(func(b): return b.who == i).size(), "Every ball counted")
		for t in worms[i].telegraphs: check(t >= 0.4 and t <= 0.6, "Warning 0.4-0.6 s")
	check(max_attacking <= 2 and max_attacking > 0, "At most two worms attack at once (max %d)" % max_attacking)
	for worm in worms: worm.health.take_damage(99999)
	for i in 3: await physics_frame
	check(get_nodes_in_group(GROUND.ATTACK_GROUP).is_empty(), "Liberation releases attack slots")
	print("TANDA_C_WORM failures=", failures, " balls=", balls.size(), " apex=", snappedf(apex, 0.01), " max_attackers=", max_attacking)
	quit(1 if failures else 0)
