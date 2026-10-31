extends SceneTree
## Tanda C (T6e) — ARAÑA COLGANTE: lowers on its thread, swings like a pendulum and throws ONE web every 4 s (0.5 s pulse first).
## No drop strike, no column, no ring. +50 % spiders in the roster waves where it appears (3 -> 5).
var failures := 0
var spiders: Array[ControlledSpider] = []
var webs: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _added(node: Node) -> void:
	if node is AlienEnemyProjectile and node.hitbox.attacker in spiders:
		webs.append({"who": spiders.find(node.hitbox.attacker), "t": Engine.get_physics_frames() / 60.0, "gravity": node.gravity, "style": node.get_meta("shot_style", &""), "damage": node.damage, "dir": node.travel_direction, "at": node.global_position})
func _count_spiders() -> int:
	var total := 0
	for event: Dictionary in BeeLevel01Controller.EVENTS_ROSTER:
		total += event.get("units", []).count("Spider")
		for wave: Dictionary in event.get("arena", []):
			total += wave.get("units", []).count("Spider")
	return total
func run() -> void:
	check(_count_spiders() == 3 + BeeLevel01Controller.SPIDER_SECOND_WAVE.size(), "Roster spiders: 2 + 1 + the Tanda G second wave of 3, got %d" % _count_spiders())
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 270
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(265, 3, 0)
	stage.bee.health.damage_blocked = true
	node_added.connect(_added, CONNECT_DEFERRED)
	for i in 2:
		stage.wave._spawn({"family": "Spider", "slot": i, "event": 0, "hard": false, "x": [1.2, -2.2][i]})
		var spider := stage.wave.active_units.back() as ControlledSpider
		spiders.append(spider)
		check(spider.health.max_health == BeeGameSettings.scaled_hp(BeeLevel01Controller.level_hp("Spider")), "HP remains unchanged")
		check(spider.web_mode, "Roster spider runs in web mode")
		check(spider.find_children("*", "BeeImplantShooter", false, false).is_empty(), "No second (implant) gun")
	var s := spiders[0]
	var swing_min := 0.0
	var swing_max := 0.0
	var tilt_max := 0.0
	var y_min := 100.0
	var y_max := -100.0
	var tele_run := 0
	var tele_runs: Array[int] = []
	var max_slots := 0
	var column_seen := false
	var strike_state := false
	for frame in 60 * 30:
		await physics_frame
		max_slots = maxi(max_slots, get_nodes_in_group(BeeCommonSlots.GROUP).size())
		if s.current_state in [ControlledSpider.State.DROP, ControlledSpider.State.HOLD, ControlledSpider.State.RETRACT]: strike_state = true
		if s._column.visible or s._ring.visible: column_seen = true
		if s.current_state in [ControlledSpider.State.HANG, ControlledSpider.State.TELEGRAPH]:
			swing_min = minf(swing_min, s._sway)
			swing_max = maxf(swing_max, s._sway)
			tilt_max = maxf(tilt_max, absf(s._thread.rotation.z))
			y_min = minf(y_min, s.global_position.y)
			y_max = maxf(y_max, s.global_position.y)
		if s.current_state == ControlledSpider.State.TELEGRAPH:
			tele_run += 1
		elif tele_run > 0:
			tele_runs.append(tele_run)
			tele_run = 0
	var mine := webs.filter(func(w): return w.who == 0)
	check(mine.size() >= 6, "The spider threw webs (%d)" % mine.size())
	for i in range(1, mine.size()):
		check(absf((mine[i].t - mine[i - 1].t) - 4.0) < 0.1, "One web every 4 s (gap %.3f)" % (mine[i].t - mine[i - 1].t))
	for w in webs:
		check(w.style == &"web", "Spider palette: web")
		check(w.damage == 3 and w.gravity == 0.0, "Common bullet damage 3, straight path")
	check(s.strike_count == 0 and not strike_state and not column_seen, "No drop strike, column or ring")
	check(swing_max - swing_min > 1.8, "Pendulum swing %.2f m" % (swing_max - swing_min))
	check(tilt_max > 0.05, "The thread tilts with the swing (%.3f rad)" % tilt_max)
	check(y_max < 5.5 - 0.5, "It hangs LOW on the thread (y max %.2f)" % y_max)
	check(y_max - y_min < 1.0, "It oscillates but stays at its hanging height")
	for n in tele_runs:
		check(absf(float(n) / 60.0 - 0.5) < 0.08, "Pulse 0.5 s (%d frames)" % n)
	check(max_slots <= 2 and max_slots > 0, "At most two attackers (max %d)" % max_slots)
	for sp in spiders: sp.health.take_damage(99999)
	for i in 4: await physics_frame
	check(get_nodes_in_group(BeeCommonSlots.GROUP).is_empty(), "Liberation releases the attack slots")
	print("TANDA_C_SPIDER failures=", failures, " webs=", mine.size(), " swing=", snappedf(swing_max - swing_min, 0.01), " tilt=", snappedf(tilt_max, 0.001), " ymax=", snappedf(y_max, 0.01), " tele=", tele_runs.slice(0, 3), " slots=", max_slots)
	quit(1 if failures else 0)
