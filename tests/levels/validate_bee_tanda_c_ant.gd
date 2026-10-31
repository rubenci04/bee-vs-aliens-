extends SceneTree
## Tanda C (T6e) — HORMIGA: marches in a file, stops every 2.5 s to spit an arcing pebble, never floats, no lunge, no aim lines.
var failures := 0
var ants: Array[AssetFauna] = []
var shots: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _added(node: Node) -> void:
	if node is AlienEnemyProjectile and node.hitbox.attacker in ants:
		shots.append({"gravity": node.gravity, "style": node.get_meta("shot_style", &""), "damage": node.damage})
func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 60
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(55, 3, 0)
	stage.bee.health.damage_blocked = true
	node_added.connect(_added, CONNECT_DEFERRED)
	for i in 4:
		stage.wave._spawn({"family": "Ant", "slot": i, "event": 0, "hard": false})
		var ant := stage.wave.active_units.back() as AssetFauna
		ants.append(ant)
		check(ant.health.max_health == BeeGameSettings.scaled_hp(BeeLevel01Controller.level_hp("Ant")), "HP remains unchanged")
		check(ant.config["mode"] == &"marcher" and ant.is_ground(), "Ant is a ground marcher")
		check(ant.get_node_or_null("ImplantGun") == null and ant.find_children("*", "BeeImplantShooter", false, false).is_empty(), "No second (implant) gun")
	var first := ants[0]
	var last_x := first.global_position.x
	var shot_times: Array[float] = []
	var seen_shots := 0
	var stopped_moves := 0
	var walked := 0.0
	var max_slots := 0
	var clock := 0.0
	for frame in 60 * 16:
		await physics_frame
		clock += 1.0 / 60.0
		max_slots = maxi(max_slots, get_nodes_in_group(BeeCommonSlots.GROUP).size())
		for ant in ants:
			if ant.is_active() and ant.state != AssetFauna.State.ENTER:
				check(is_equal_approx(ant.global_position.y, ant.ground_y), "Never floats: stays on the soil")
			if ant.state == AssetFauna.State.TELEGRAPH or ant.state == AssetFauna.State.ATTACK:
				check(ant._warn.is_empty(), "No line, strip, ring or dome warning for a common enemy")
		if first.is_active():
			if first.state in [AssetFauna.State.TELEGRAPH, AssetFauna.State.ATTACK, AssetFauna.State.RECOVER]:
				if absf(first.global_position.x - last_x) > 0.001: stopped_moves += 1
			else:
				walked += absf(first.global_position.x - last_x)
			last_x = first.global_position.x
		if first.shots_fired > seen_shots:
			seen_shots = first.shots_fired
			shot_times.append(clock)
	check(seen_shots >= 3, "The first ant spat at least three times in 16 s (got %d)" % seen_shots)
	check(stopped_moves <= 2, "It STOPS while it warns, spits and recovers (at most the 2 transition frames; moved %d)" % stopped_moves)
	check(walked > 0.5, "It marches between spits (walked %.2f m)" % walked)
	for i in range(1, shot_times.size()):
		check(absf((shot_times[i] - shot_times[i - 1]) - 2.5) < 0.12, "Spit every 2.5 s (gap %.3f)" % (shot_times[i] - shot_times[i - 1]))
	check(shots.size() >= seen_shots, "Projectiles emitted")
	for shot in shots:
		check(shot.gravity > 0.0, "Arcing (lobbed) shot")
		check(shot.style == &"pebble", "Ant palette: pebble")
		check(shot.damage == 3, "Common bullet damage 3")
	for ant in ants:
		for t in ant.telegraphs:
			check(t >= 0.4 and t <= 0.6, "Warning 0.4-0.6 s (got %.3f)" % t)
		check(ant.cycles_done >= 0, "cycles")
	check(max_slots <= 2 and max_slots > 0, "At most two ants attack at once (max %d)" % max_slots)
	for ant in ants:
		ant.health.take_damage(99999)
	for i in 4: await physics_frame
	check(get_nodes_in_group(BeeCommonSlots.GROUP).is_empty(), "Liberation releases the attack slots")
	print("TANDA_C_ANT failures=", failures, " shots=", shots.size(), " gaps=", shot_times, " max_slots=", max_slots, " walked=", snappedf(walked, 0.01))
	quit(1 if failures else 0)
