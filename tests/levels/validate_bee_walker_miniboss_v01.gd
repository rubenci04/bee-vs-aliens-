extends SceneTree

# LOTE 12 · ETAPA 3 — the walking robot as MINI-BOSS (WalkerMiniboss) at checkpoint 2: structure (two escort waves of insects, aimed
# dorsal cannon warned 0.5 s, stomp wave with a warning band that the roll never destroys, weak points: the cannon - breaking it ends
# the shot - and the yellow eye x2, it explodes when it falls) and four bot fights (Normal/Easy x Base/Spread) measuring the robot's
# fight (activation -> fall) and the damage Bee takes at the gate. Target: 25-40 s in the four combinations.
# Bot: three taps/s, 60 % aimed at the nearest target on screen (escorts too), it reacts to every warning but every other time
# LATE (half of the warning gone), it sees half of the shots coming. Dev: -- report · -- first

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const BOT_TAPS_PER_SECOND := 3.0
const AIM_PATTERN := [true, true, false, true, false]
const LATE_FRACTION := 0.5
const BULLET_LOOKAHEAD := 0.9
const FIGHT_SECONDS := Vector2(25.0, 45.0) # LOTE 14: 40 -> 45 (the wider camera gives the escorts more room to live)

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var report_only := false
var use_spread := false
var lines: Array[String] = []

func _initialize() -> void:
	report_only = "report" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if report_only:
		if not ok:
			print("WOULD FAIL: ", message)
		return
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func load_level() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await frames(3)
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(6)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func gate_index() -> int:
	var events := BeeLevel01Controller.EVENTS_ROSTER
	for i in events.size():
		if bool(events[i].get("miniboss", false)):
			return i
	return -1

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	Engine.max_physics_steps_per_frame = 16
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	test_table()
	await test_structure()
	for difficulty in [BeeGameSettings.NORMAL, BeeGameSettings.EASY]:
		BeeGameSettings.difficulty = difficulty
		for spread in [false, true]:
			if "first" in OS.get_cmdline_user_args() and (difficulty != BeeGameSettings.NORMAL or spread):
				continue
			use_spread = spread
			var label := ("NORMAL" if difficulty == BeeGameSettings.NORMAL else "EASY") + (" SPREAD" if spread else " BASE")
			var result := await fight(label)
			print("MEASURE ", label, " ", result)
			check(float(result.seconds) >= FIGHT_SECONDS.x and float(result.seconds) <= FIGHT_SECONDS.y, label + ": robot fight outside 25-45 s: " + str(result.seconds))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	for line in lines:
		print(line)
	print("BEE_WALKER_MINIBOSS_V01_OK")
	quit(0)


func test_table() -> void:
	var index := gate_index()
	check(index == BeeLevel01Controller.EVENTS_ROSTER.size() - 1, "The robot gate is the last event of the roster table")
	var gate: Dictionary = BeeLevel01Controller.EVENTS_ROSTER[index]
	check(bool(gate.get("hard", false)) and float(gate["at"]) > 281.0, "Hard gate after checkpoint 2")
	var first: Array = (gate["units"] as Array).filter(func(f): return f != "Walker")
	var second: Array = gate["escort_wave"]["units"]
	var escorts := first + second
	check(escorts.size() >= 4 and escorts.size() <= 6, "4-6 escorts (%d)" % escorts.size())
	for family in escorts:
		check(family in ["Wasp", "FlyCommon", "FlyGreen"], "Escorts are wasps and flies (%s)" % family)
	check(not first.is_empty() and not second.is_empty(), "Two escort waves")


func start_gate() -> WalkerMiniboss:
	await load_level()
	var index := gate_index()
	stage.distance = 293.9
	stage._update_camera_and_bounds()
	wave.event_index = index
	for unit in wave.active_units:
		unit.queue_free()
	wave.active_units.clear()
	for group_name in ["Powerups", "Pollen", "PreBossSupply"]:
		var group := stage.get_node_or_null(group_name)
		if group != null:
			for item in group.get_children():
				item.queue_free()
	bee.global_position = Vector3(stage.camera.global_position.x - 3.6, 3.4, 0.0)
	var robot: WalkerMiniboss
	for i in 240:
		await physics_frame
		for unit in wave.active_units:
			if unit is WalkerMiniboss:
				robot = unit
		if robot != null and robot.is_active():
			break
	return robot


func test_structure() -> void:
	var robot := await start_gate()
	check(robot != null and robot.is_active(), "The gate spawns the mini-boss robot")
	check(robot.health.max_health == BeeGameSettings.scaled_hp(BeeLevel01Controller.MINIBOSS_HP), "Mini-boss HP")
	check(robot.health_bar_visible(), "Mini-boss bar")
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 3.6, 3.4, 0.0)
	# Let it walk in and attack: cannon (warned 0.5 s) and stomp (band + wave).
	var saw_band := false
	var wave_node: BeeGroundShockwave
	for i in 60 * 14:
		await physics_frame
		if robot._step == &"stomp_tele" and is_instance_valid(robot._stomp_band):
			saw_band = true
		for node in stage.get_children():
			if node is BeeGroundShockwave and wave_node == null:
				wave_node = node
		if robot.cannon_shots >= 1 and robot.stomps >= 1:
			break
	check(robot.cannon_shots >= 1 and robot.stomps >= 1 and saw_band, "Cannon burst and stomp with its warning band (shots %d stomps %d)" % [robot.cannon_shots, robot.stomps])
	var min_tele := INF
	for hazard in robot.hazards:
		min_tele = minf(min_tele, float(hazard["telegraph"]))
		if hazard["kind"] == &"cannon":
			check(float(hazard["telegraph"]) >= 0.5 - 0.001, "The cannon warns 0.5 s")
	check(min_tele >= WalkerMiniboss.MIN_TELEGRAPH, "Every robot attack warned >= 0.42 s")
	# The roll never destroys the stomp wave.
	var probe_wave := BeeGroundShockwave.launch(stage, robot, bee.global_position.x + 1.0, bee.global_position.x - 8.0, 8, 7.0, 1.25)
	bee.global_position.y = 1.0
	bee._roll_cooldown_left = 0.0
	bee.start_roll()
	await frames(10)
	check(is_instance_valid(probe_wave) and probe_wave.hitbox.enabled, "The roll must not destroy the stomp wave")
	probe_wave.stop()
	bee.global_position.y = 3.4
	# Eye x2.
	var at_eye := Node3D.new()
	stage.add_child(at_eye)
	at_eye.global_position = robot._eye.global_position
	check(is_equal_approx(robot.hurtbox.multiplier_for(at_eye), WalkerMiniboss.EYE_MULTIPLIER), "The yellow eye takes x2")
	at_eye.queue_free()
	# Second escort wave at 60 % HP.
	var spawned_before := int(wave.spawn_history.size())
	robot.health.take_damage(int(robot.health.max_health * 0.45))
	await frames(180)
	await frames(240)
	check(robot.escorts_called and wave.escort_waves == 2, "Second escort wave at 60 %% HP")
	var escort_families := wave.spawn_history.slice(spawned_before).map(func(e): return e["family"])
	var queued := wave._pending.filter(func(r): return int(r["slot"]) >= 200).size()
	check(escort_families.size() >= 2 and escort_families.size() + queued >= 3, "Second wave spawned or queued behind the threat cap (%s + %d queued)" % [str(escort_families), queued])
	# Cannon weak point: breaking it ends the shot.
	robot.cannon_health.take_damage(9999)
	await frames(2)
	check(not robot.cannon_alive, "The cannon breaks")
	for gun: Node3D in robot.visual_root.find_children("Cylinder", "MeshInstance3D", true, false):
		check(not gun.visible, "The broken cannon is hidden")
	var shots := robot.cannon_shots
	for i in 60 * 6:
		await physics_frame
	check(robot.cannon_shots == shots and robot.stomps >= 2, "No more cannon shots after it broke, the stomp goes on")
	# It explodes when it falls (technology: never freed).
	var freed_before := wave.liberated_count
	robot.health.take_damage(99999)
	await frames(30)
	check(robot.is_defeated() and wave.liberated_count == freed_before, "The robot explodes, it is not freed")
	await frames(60)
	check(not is_instance_valid(robot) or not robot.visual_root.visible, "Its model is gone after the blast")
	lines.append("WALKER structure cannon_tele=0.5 stomp=band+wave eye=x2 escorts=%d+%d cannon_break=OK explode=OK" % [
			(BeeLevel01Controller.EVENTS_ROSTER[gate_index()]["units"] as Array).size() - 1, (BeeLevel01Controller.EVENTS_ROSTER[gate_index()]["escort_wave"]["units"] as Array).size()])


func fight(label: String) -> Dictionary:
	var robot := await start_gate()
	check(robot != null, label + ": no robot")
	bee.set_physics_process(false)
	bee.bomb_charges = 0
	bee.spread_ammo = 0
	bee.honey_seconds = 0.0
	bee.health.max_health = 1000
	bee.health.current_health = 1000
	bee.health.damage_blocked = false
	var damage := [0]
	bee.health.health_changed.connect(func(_c: int, _m: int, change: int):
		if change < 0:
			damage[0] += -change)
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var clock := 0.0
	var fire_left := 0.0
	var taps := 0
	var last_attack := -1
	var react_at := -1.0
	var react_kind := &"none"
	var dodge_until := 0.0
	var dodge_goal := Vector3.ZERO
	var bullet_seen := {}
	var bullet_until := 0.0
	var bullet_goal := Vector3.ZERO
	while clock < 120.0 and is_instance_valid(robot) and not robot.is_defeated():
		await physics_frame
		clock += tick
		var cam_x := stage.camera.global_position.x
		if "trace" in OS.get_cmdline_user_args() and int(clock * 60.0) % 60 == 0:
			print("T %.0f hp=%d step=%s robot_x=%.1f active=%s units=%s" % [clock, robot.health.current_health, robot._step, robot.global_position.x - cam_x, robot.is_active(), str(wave.active_units.map(func(u): return str(u.name).get_slice("_", 0)))])
		if robot.attacks_started != last_attack:
			last_attack = robot.attacks_started
			react_kind = robot._step
			var late := last_attack % 2 == 1
			react_at = clock + (robot._left * LATE_FRACTION if late else 0.0)
		var goal := Vector3(cam_x - 3.6, clampf(3.4 + 1.2 * sin(clock * TAU / 3.6), 1.6, 5.6), 0.0)
		if react_at >= 0.0 and clock >= react_at:
			react_at = -1.0
			if react_kind == &"stomp_tele":
				dodge_goal = Vector3(bee.global_position.x, 3.0, 0.0)
				dodge_until = clock + maxf(robot._left, 0.0) + 1.4
			elif react_kind == &"cannon_tele":
				dodge_goal = Vector3(bee.global_position.x, bee.global_position.y + (1.8 if bee.global_position.y < 3.6 else -1.8), 0.0)
				dodge_until = clock + maxf(robot._left, 0.0) + 0.7
		if clock < dodge_until:
			goal = dodge_goal
		for unit in wave.active_units:
			if is_instance_valid(unit) and unit != robot and unit.global_position.distance_to(bee.global_position) < 2.0 and clock >= dodge_until:
				goal.y = clampf(bee.global_position.y + (1.8 if unit.global_position.y < bee.global_position.y else -1.8), 1.6, 5.8)
		if clock >= bullet_until:
			for node in get_nodes_in_group("alien_projectiles"):
				var shot := node as AlienEnemyProjectile
				if shot == null or not is_instance_valid(shot) or shot.is_queued_for_deletion():
					continue
				if not bullet_seen.has(shot.get_instance_id()):
					bullet_seen[shot.get_instance_id()] = bullet_seen.size()
				if int(bullet_seen[shot.get_instance_id()]) % 2 == 1:
					continue
				var v := Vector2(shot.travel_direction.x, shot.travel_direction.y) * shot.speed
				var r := Vector2(shot.global_position.x - bee.global_position.x, shot.global_position.y - bee.global_position.y)
				var closest_t := -r.dot(v) / maxf(v.length_squared(), 0.001)
				if closest_t <= 0.0 or closest_t > BULLET_LOOKAHEAD:
					continue
				var miss := r + v * closest_t
				if miss.length() > 0.8:
					continue
				var perp := Vector2(-v.y, v.x).normalized()
				if perp.dot(-miss) > 0.0:
					perp = -perp
				bullet_goal = bee.global_position + Vector3(perp.x, perp.y, 0.0) * 1.6
				bullet_until = clock + 0.4
				break
		if clock < bullet_until and clock >= dodge_until:
			goal = bullet_goal
		goal.x = clampf(goal.x, bee.flight_min.x, bee.flight_max.x)
		goal.y = clampf(goal.y, bee.flight_min.y, bee.flight_max.y)
		var p := bee.global_position
		p.x = move_toward(p.x, goal.x, bee.horizontal_speed * tick)
		p.y = move_toward(p.y, goal.y, bee.vertical_speed * tick)
		bee.global_position = p
		bee.spread_ammo = 9999 if use_spread else 0
		fire_left -= tick
		if fire_left <= 0.0:
			fire_left = 1.0 / BOT_TAPS_PER_SECOND
			var aimed: bool = AIM_PATTERN[taps % AIM_PATTERN.size()]
			taps += 1
			var target_point := _nearest_target()
			if not aimed:
				target_point += Vector3(0.0, 5.0, 0.0)
			bee.set_aim_point(target_point)
			bee.fire()
	var seconds := wave.miniboss_seconds
	lines.append("WALKER %s fight=%.1fs damage=%d cannon_shots=%d stomps=%d cannon_alive=%s escort_waves=%d taps=%d" % [label, seconds, damage[0],
			robot.cannon_shots if is_instance_valid(robot) else -1, robot.stomps if is_instance_valid(robot) else -1,
			str(robot.cannon_alive) if is_instance_valid(robot) else "?", wave.escort_waves, taps])
	return {"seconds": seconds, "damage": damage[0]}


## The nearest live target on screen (escorts included); the robot's body otherwise.
func _nearest_target() -> Vector3:
	var best := Vector3(stage.camera.global_position.x + 3.0, 1.2, 0.0)
	var best_d := INF
	for node in get_nodes_in_group("bee_auto_aim_targets"):
		var target := node as Node3D
		if target == null or not target.is_visible_in_tree() or not BeeShmupFairness.is_on_screen(target, -0.4):
			continue
		if target.has_method("is_active") and not bool(target.call("is_active")):
			continue
		var point := bee._target_point(target)
		var d := point.distance_to(bee.global_position)
		if d < best_d:
			best_d = d
			best = point
	return best
