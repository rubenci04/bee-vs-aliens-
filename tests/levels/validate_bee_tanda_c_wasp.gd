extends SceneTree
## Tanda C (T6e) — AVISPA: two kinds. SHOOTER = burst of 3 bolts after a 0.5 s pulse, repeating, never dashes.
## KAMIKAZE = 0.5 s pulse, then a locked straight ram; it fires nothing. At most two common enemies attack at once.
var failures := 0
var wasps: Array[WaspEnemy] = []
var bolts: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _added(node: Node) -> void:
	if node is AlienEnemyProjectile and node.hitbox.attacker in wasps:
		bolts.append({"who": wasps.find(node.hitbox.attacker), "t": Engine.get_physics_frames() / 60.0, "damage": node.damage, "style": node.get_meta("shot_style", &"")})
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
		stage.wave._spawn({"family": "Wasp", "slot": i, "event": 0, "hard": false})
		var wasp := stage.wave.active_units.back() as WaspEnemy
		wasps.append(wasp)
		check(wasp.health.max_health == BeeGameSettings.scaled_hp(BeeLevel01Controller.level_hp("Wasp")), "HP remains unchanged")
	check(wasps[0].variant == &"shooter" and wasps[1].variant == &"kamikaze" and wasps[2].variant == &"shooter" and wasps[3].variant == &"kamikaze", "Variants alternate shooter / kamikaze")
	check(wasps[0].sting_shots == 3 and wasps[0].sting_fan_count == 0 and not wasps[0].overload_enabled, "Shooter: burst of 3, no fan")
	check(wasps[1].sting_shots == 0 and is_equal_approx(wasps[1].dash_windup, 0.5), "Kamikaze: no needles, 0.5 s warning")
	var windup_frames := {}
	var windup_run := {}
	var max_slots := 0
	var telegraph_visible := false
	for frame in 60 * 30:
		await physics_frame
		max_slots = maxi(max_slots, get_nodes_in_group(BeeCommonSlots.GROUP).size())
		for i in wasps.size():
			var w := wasps[i]
			if w.current_state == WaspEnemy.State.WINDUP:
				windup_run[i] = int(windup_run.get(i, 0)) + 1
				if w.telegraph.visible and w.telegraph.layers != 0: telegraph_visible = true
			elif windup_run.get(i, 0) > 0:
				windup_frames[i] = int(windup_run[i])
				windup_run[i] = 0
	check(not telegraph_visible, "No line / strip drawn: the pulse is the warning")
	# --- shooter ---
	var shooter_bolts := bolts.filter(func(b): return b.who == 0)
	check(shooter_bolts.size() >= 6, "The shooter fired at least two bursts (%d bolts)" % shooter_bolts.size())
	check(shooter_bolts.size() % 3 == 0 or shooter_bolts.size() > 6, "Bolts come in bursts of three")
	var bursts: Array = []
	for b in shooter_bolts:
		if bursts.is_empty() or b.t - bursts.back().back().t > 0.6: bursts.append([b])
		else: bursts.back().append(b)
	for burst in bursts.slice(0, bursts.size() - 1):
		check(burst.size() == 3, "A burst is exactly 3 bolts (got %d)" % burst.size())
	check(wasps[0].passes_done == 0 and wasps[0].attack_count == 0, "The shooter never dashes")
	for b in shooter_bolts:
		check(b.style == &"stinger", "Wasp palette: stinger")
		check(b.damage == 3, "Common bullet damage 3")
	# --- kamikaze ---
	check(bolts.filter(func(b): return b.who == 1).is_empty(), "The kamikaze fires nothing")
	check(wasps[1].passes_done >= 1, "The kamikaze rams (passes %d)" % wasps[1].passes_done)
	check(windup_frames.has(1) and absf(float(windup_frames[1]) / 60.0 - 0.5) < 0.08, "Kamikaze warning 0.5 s (frames %s)" % str(windup_frames.get(1)))
	check(max_slots <= 2 and max_slots > 0, "At most two wasps attack at once (max %d)" % max_slots)
	for w in wasps:
		w.health.take_damage(99999)
	for i in 4: await physics_frame
	check(get_nodes_in_group(BeeCommonSlots.GROUP).is_empty(), "Liberation releases the attack slots")
	print("TANDA_C_WASP failures=", failures, " shooter_bolts=", shooter_bolts.size(), " bursts=", bursts.size(), " kamikaze_passes=", wasps[1].passes_done, " windup=", windup_frames, " slots=", max_slots)
	quit(1 if failures else 0)
