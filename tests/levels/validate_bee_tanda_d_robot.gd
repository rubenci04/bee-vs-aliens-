extends SceneTree
## Tanda D (T7c + T7d) — ROBOT CAMINANTE: plasma waves (no cyan), two new attacks with their own 0.5 s pulse (burst of 3, short hop with a wave),
## the mid-fight call of two escorts, at most two simultaneous attackers, and a fight of >= 45 s at the base weapon's DPS (36).
const DPS_TICK := 3 # Base: 3 damage per shot...
const SHOT_INTERVAL := 1.0 / 12.0 # ...12 shots per second = 36 DPS
const MIN_FIGHT_SECONDS := 45.0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func gate_event() -> Dictionary:
	for event: Dictionary in BeeLevel01Controller.EVENTS_ROSTER:
		if bool(event.get("miniboss", false)):
			return event
	return {}
func run() -> void:
	# --- plasma wave (no cyan) ---
	var hot := BeeGroundShockwave.COLOR
	check(hot.r > 0.9 and hot.b < 0.3 and hot.g < 0.6, "Wave foot is hot orange")
	check(BeeGroundShockwave.CROWN.r > 0.9 and BeeGroundShockwave.CROWN.b > 0.4 and BeeGroundShockwave.CROWN.g < 0.3, "Wave crown is magenta")
	var mesh := BeeGroundShockwave._plasma_mesh()
	check(mesh is ArrayMesh and mesh.get_surface_count() == 1, "Jagged procedural mesh")
	var radii := {}
	for v: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		radii[snappedf(Vector2(v.x, v.z).length() + v.y, 0.01)] = true
	check(radii.size() > 12, "Irregular edge (%d distinct radii)" % radii.size())
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	var wave := stage.wave as BeeLevel01Controller
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 294
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 3.0, 0)
	stage.bee.health.damage_blocked = true
	var gate := gate_event()
	wave._spawn({"family": "Walker", "slot": 0, "event": 0, "hard": true, "miniboss": true, "escort_wave": gate["escort_wave"]})
	var robot := wave.miniboss
	check(robot != null and is_equal_approx(robot.health.max_health, BeeGameSettings.scaled_hp(BeeLevel01Controller.MINIBOSS_HP)), "Robot HP unchanged (600)")
	check((gate["escort_wave"]["units"] as Array).size() == 2, "Mid-fight escort call = 2 units")
	# --- the fight: attacks, slots, wave looks ---
	var wave_checked := false
	var max_slots := 0
	var kinds := {}
	var seen_waves: Array[BeeGroundShockwave] = []
	var spot := func(node: Node):
		if node is BeeGroundShockwave:
			seen_waves.append(node)
	node_added.connect(spot)
	for frame in 60 * 100:
		await physics_frame
		max_slots = maxi(max_slots, get_nodes_in_group(BeeCommonSlots.GROUP).size())
		if robot.attack_kind != &"none":
			kinds[robot.attack_kind] = true
	for h in robot.hazards:
		check(h.telegraph >= 0.42, "Every hazard is warned (%s %.2f)" % [h.kind, h.telegraph])
	check(robot.bursts >= 2 and robot.burst_shots_fired >= 3 * (robot.bursts - 1), "Burst of 3 fired (%d bursts, %d shots)" % [robot.bursts, robot.burst_shots_fired])
	check(robot.hops >= 2, "Short hop used (%d)" % robot.hops)
	check(robot.hazards.any(func(h): return h.kind == &"hop_wave"), "The hop lands with a wave")
	for w in seen_waves:
		if is_instance_valid(w):
			wave_checked = true
			check(w._visual.mesh is ArrayMesh and w._visual.material_override == null, "Live wave uses the plasma mesh")
			break
	check(seen_waves.size() >= 4, "Ground waves were spawned (%d)" % seen_waves.size())
	check(kinds.has(&"burst") and kinds.has(&"hop"), "Both new attack kinds ran")
	check(WalkerMiniboss.HOP_APEX == 3.5 and WalkerMiniboss.JUMP_APEX == 4.4 and WalkerMiniboss.BURST_SPEED == 10.0, "E2: hop 3.5 m, jump 4.4 m, burst at 10 m/s")
	check(max_slots <= 2, "At most two attackers at once (max %d)" % max_slots)
	print("TANDA_D_ROBOT_ATTACKS bursts=", robot.bursts, " shots=", robot.burst_shots_fired, " hops=", robot.hops, " slots=", max_slots, " kinds=", kinds.keys())
	check(robot.escorts_called and wave.escort_waves == 2, "The mid-fight call happened exactly once (waves %d)" % wave.escort_waves)
	# --- duration at Base DPS (fastest possible fight: every shot hits the body, none is wasted) ---
	var stage2 := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage2)
	stage.queue_free()
	current_scene = stage2
	for i in 4: await physics_frame
	var wave2 := stage2.wave as BeeLevel01Controller
	stage2.set_physics_process(false)
	wave2.set_physics_process(false)
	stage2.bee.set_physics_process(false)
	stage2.get_node("CheckpointQoL").set_process(false)
	stage2.distance = 294
	stage2._update_camera_and_bounds()
	stage2.bee.global_position = Vector3(stage2.camera.global_position.x - 2.0, 3.0, 0)
	stage2.bee.health.damage_blocked = true
	wave2._spawn({"family": "Walker", "slot": 0, "event": 0, "hard": true, "miniboss": true, "escort_wave": gate["escort_wave"]})
	var robot2 := wave2.miniboss
	var call_ratio := [-1.0]
	robot2.escorts_requested.connect(func(): call_ratio[0] = float(robot2.health.current_health) / float(robot2.health.max_health))
	var next_shot := 0.0
	var clock := 0.0
	robot2.cannon_hurtbox.set_deferred("monitorable", false)
	while robot2.health.current_health > 0 and clock < 400.0:
		await physics_frame
		clock += 1.0 / 60.0
		if robot2._step == &"enter":
			continue
		while next_shot <= robot2.fight_seconds:
			var permitted := robot2.limit_hull_damage(DPS_TICK, null)
			if permitted > 0:
				robot2.health.take_damage(permitted)
			next_shot += SHOT_INTERVAL
	check(robot2.health.current_health <= 0, "The robot falls")
	check(call_ratio[0] > 0.44 and call_ratio[0] <= 0.55, "The escorts are called at the middle of the fight (HP %.2f)" % call_ratio[0])
	check(robot2.fight_seconds >= MIN_FIGHT_SECONDS, "Fight at Base DPS lasts >= 45 s (got %.1f s)" % robot2.fight_seconds)
	print("TANDA_D_ROBOT_DURATION fight_seconds=", snappedf(robot2.fight_seconds, 0.1))
	print("TANDA_D_ROBOT failures=", failures)
	quit(1 if failures else 0)
