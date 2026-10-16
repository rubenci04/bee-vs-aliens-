extends SceneTree
## Tanda C (T6e) — MARIQUITA: two wide arc jumps (small ring at the landing), then a straight rolling charge; ground unit, no lines / domes.
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
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 60
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(55, 3, 0)
	stage.bee.health.damage_blocked = true
	var birds: Array[AssetFauna] = []
	for i in 3:
		stage.wave._spawn({"family": "Ladybird", "slot": i, "event": 0, "hard": false})
		var bird := stage.wave.active_units.back() as AssetFauna
		birds.append(bird)
		check(bird.health.max_health == BeeGameSettings.scaled_hp(BeeLevel01Controller.level_hp("Ladybird")), "HP remains unchanged")
		check(bird.is_ground() and bird.config["mode"] == &"hopper", "Ladybird is a ground hopper")
		check(bird.find_children("*", "BeeImplantShooter", false, false).is_empty(), "No implant gun")
	var bird := birds[0]
	var sequence := ""
	var last_hops := 0
	var last_rolls := 0
	var max_height := 0.0
	var min_height := 0.0
	var max_slots := 0
	var roll_xs: Array[float] = []
	var roll_runs := {}
	var roll_ys: Array[float] = []
	var roll_hitbox_on := true
	var flight_hitbox_on := false
	var hop_span := 0.0
	var hop_start_x := 0.0
	var tired_x_moves := 0
	var tired_last := INF
	var rings := 0
	var ring_seen := {}
	for frame in 60 * 40:
		await physics_frame
		max_slots = maxi(max_slots, get_nodes_in_group(BeeCommonSlots.GROUP).size())
		for b in birds:
			if b.state == AssetFauna.State.TELEGRAPH:
				check(b._warn.is_empty(), "No line, strip or dome while it warns")
		if not bird.is_active() or bird.state == AssetFauna.State.ENTER:
			continue
		max_height = maxf(max_height, bird.global_position.y - bird.ground_y)
		min_height = minf(min_height, bird.global_position.y - bird.ground_y)
		if bird.state == AssetFauna.State.ATTACK and not bird._hop_is_roll and not bird._hop_landed and bird.attack_hitbox.enabled:
			flight_hitbox_on = true
		if bird.state == AssetFauna.State.ATTACK and bird._hop_is_roll:
			roll_xs.append(bird.global_position.x)
			if not roll_runs.has(bird.rolls_done): roll_runs[bird.rolls_done] = []
			roll_runs[bird.rolls_done].append(bird.global_position.x)
			roll_ys.append(bird.global_position.y)
			if not bird.attack_hitbox.enabled: roll_hitbox_on = false
		if bird.state == AssetFauna.State.ATTACK and not bird._hop_is_roll and hop_start_x == 0.0:
			hop_start_x = bird._lock_from.x
			hop_span = maxf(hop_span, absf(bird._lock_to.x - bird._lock_from.x))
		if bird.state != AssetFauna.State.ATTACK:
			hop_start_x = 0.0
		if bird.state == AssetFauna.State.RECOVER and bird._hops_done == 0 and bird.rolls_done > 0:
			if tired_last != INF and absf(bird.global_position.x - tired_last) > 0.001: tired_x_moves += 1
			tired_last = bird.global_position.x
		else:
			tired_last = INF
		if bird.hops_landed > last_hops:
			last_hops = bird.hops_landed
			sequence += "h"
		if bird.rolls_done > last_rolls:
			last_rolls = bird.rolls_done
			sequence += "r"
	check(sequence.begins_with("hhrhhr"), "Order: two hops then a roll, repeated (got %s)" % sequence)
	check(max_height > 2.0, "Wide arc: it rises %.2f m" % max_height)
	check(min_height > -0.01, "It never sinks below the soil (%.3f)" % min_height)
	check(hop_span >= 2.4, "Wide jump span %.2f m" % hop_span)
	check(not flight_hitbox_on, "No contact damage while in the air")
	check(roll_hitbox_on and roll_xs.size() > 10, "The roll hurts along its whole path")
	if roll_ys.size() > 0:
		check(roll_ys.max() - roll_ys.min() < 0.01, "The roll is a straight ground line")
		var mono := true
		for run_id in roll_runs:
			var xs: Array = roll_runs[run_id]
			var sign := signf(xs[xs.size() - 1] - xs[0])
			for i in range(1, xs.size()):
				if (xs[i] - xs[i - 1]) * sign < -0.0001: mono = false
		check(mono and roll_runs.size() >= 2, "The roll never turns back (%d rolls)" % roll_runs.size())
	check(tired_x_moves == 0, "It rests still after the roll")
	for b in birds:
		for t in b.telegraphs:
			check(t >= 0.4 and t <= 0.6, "Warning 0.4-0.6 s (got %.3f)" % t)
	check(max_slots <= 2 and max_slots > 0, "At most two attackers (max %d)" % max_slots)
	for b in birds:
		b.health.take_damage(99999)
	for i in 4: await physics_frame
	check(get_nodes_in_group(BeeCommonSlots.GROUP).is_empty(), "Liberation releases the attack slots")
	print("TANDA_C_LADYBIRD failures=", failures, " seq=", sequence, " height=", snappedf(max_height, 0.01), " span=", snappedf(hop_span, 0.01), " slots=", max_slots)
	quit(1 if failures else 0)
