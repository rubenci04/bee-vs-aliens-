extends SceneTree
## Tanda C (T6e) — ESCARABAJO: slow tank, straight ram after a 0.6 s pulse, stunned for 1 s afterwards. No stones, no lines.
var failures := 0
var beetles: Array[AssetFauna] = []
var stray_shots := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _added(node: Node) -> void:
	if node is AlienEnemyProjectile and node.hitbox.attacker in beetles:
		stray_shots += 1
func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 200
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(195, 3, 0)
	stage.bee.health.damage_blocked = true
	node_added.connect(_added, CONNECT_DEFERRED)
	for i in 3:
		stage.wave._spawn({"family": "StagBeetle", "slot": i, "event": 0, "hard": false})
		var beetle := stage.wave.active_units.back() as AssetFauna
		beetles.append(beetle)
		check(beetle.health.max_health == BeeGameSettings.scaled_hp(BeeLevel01Controller.level_hp("StagBeetle")), "HP remains unchanged")
		check(beetle.find_children("*", "BeeImplantShooter", false, false).is_empty(), "No stone-throwing implant gun")
	var b := beetles[0]
	var stun_frames := 0
	var stun_runs: Array[int] = []
	var stun_moved := 0.0
	var stun_hitbox_on := false
	var last_x := b.global_position.x
	var charge_xs: Array[float] = []
	var charge_runs: Array = []
	var charge_speed_max := 0.0
	var walk_speed_max := 0.0
	var max_slots := 0
	var max_off := 0.0
	var cam: Camera3D = stage.camera
	for frame in 60 * 40:
		await physics_frame
		max_slots = maxi(max_slots, get_nodes_in_group(BeeCommonSlots.GROUP).size())
		for x in beetles:
			if x.state == AssetFauna.State.TELEGRAPH:
				for node in x._warn:
					check(node is Node3D and node.layers == 0 or node is GeometryInstance3D and node.layers == 0, "No VISIBLE line, strip or dome while it warns (T3j keeps only hidden geometry handles)")
		if not b.is_active() or b.state == AssetFauna.State.ENTER:
			last_x = b.global_position.x
			continue
		var dx := b.global_position.x - last_x
		last_x = b.global_position.x
		check(is_equal_approx(b.global_position.y, b.ground_y), "Stays on the soil")
		max_off = maxf(max_off, absf(b.global_position.x - cam.global_position.x))
		if b.state == AssetFauna.State.ATTACK:
			charge_xs.append(b.global_position.x)
			charge_speed_max = maxf(charge_speed_max, absf(dx) * 60.0)
		elif charge_xs.size() > 0:
			charge_runs.append(charge_xs.duplicate())
			charge_xs.clear()
		if b.stunned:
			stun_frames += 1
			if stun_frames > 1: stun_moved += absf(dx) # (the first stunned frame still holds the last step of the ram)
			if b.attack_hitbox.enabled: stun_hitbox_on = true
		elif stun_frames > 0:
			stun_runs.append(stun_frames)
			stun_frames = 0
		if b.state == AssetFauna.State.IDLE:
			walk_speed_max = maxf(walk_speed_max, absf(dx) * 60.0)
	check(stray_shots == 0, "It throws nothing (no stones): %d shots" % stray_shots)
	check(charge_runs.size() >= 2, "It rams repeatedly (%d rams)" % charge_runs.size())
	for run_xs in charge_runs:
		var sign := signf(run_xs[run_xs.size() - 1] - run_xs[0])
		var mono := true
		for i in range(1, run_xs.size()):
			if (run_xs[i] - run_xs[i - 1]) * sign < -0.0001: mono = false
		check(mono and absf(run_xs[run_xs.size() - 1] - run_xs[0]) > 3.0, "Each ram is one straight line")
	check(charge_speed_max > 5.5 and charge_speed_max < 7.5, "Ram speed ~6.5 m/s (%.2f)" % charge_speed_max)
	check(walk_speed_max < 2.2, "It walks slowly like a tank (%.2f m/s)" % walk_speed_max)
	check(stun_runs.size() >= 1, "It is stunned after ramming")
	for n in stun_runs:
		check(absf(float(n) / 60.0 - 1.0) < 0.08, "Stun lasts 1 s (%d frames)" % n)
	check(stun_moved < 0.001 and not stun_hitbox_on, "Stunned: motionless and harmless")
	check(b.stuns_done >= 1, "stun counter")
	for x in beetles:
		for t in x.telegraphs: check(t >= 0.4 and t <= 0.61, "Warning 0.4-0.6 s (got %.3f)" % t)
	check(max_slots <= 2 and max_slots > 0, "At most two attackers (max %d)" % max_slots)
	check(max_off < 6.5 + 0.2, "The ram stays inside the frame (off %.2f)" % max_off)
	for x in beetles: x.health.take_damage(99999)
	for i in 4: await physics_frame
	check(get_nodes_in_group(BeeCommonSlots.GROUP).is_empty(), "Liberation releases the attack slots")
	print("TANDA_C_BEETLE failures=", failures, " rams=", charge_runs.size(), " stuns=", stun_runs, " charge_speed=", snappedf(charge_speed_max, 0.01), " walk=", snappedf(walk_speed_max, 0.01), " slots=", max_slots)
	quit(1 if failures else 0)
