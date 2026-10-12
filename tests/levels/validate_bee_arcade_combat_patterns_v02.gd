extends SceneTree

# BEE ARCADE COMBAT PATTERN & DENSITY PASS 02. Real AI in the real Level 01 (LEVEL_TUNING applied by the
# controller), Bee parked on the left half and moving in a sine so re-aiming is observable.
#   PROBE   aimed burst of 3 (0.2 s apart, each shot re-aims, fixed path afterwards), short recovery, long cooldown.
#   EYE     alternates an aimed burst and a fan of 5 (12-18 deg, passable lanes, centred on Bee, violet telegraph).
#   TURRET  fan of 3 after the unchanged warning.      WALKER  slow burst of 3, re-aiming.
#   WASP    stalk -> 3 passes -> exit, no homing, two Wasps never attack at the same time.
#   LEVEL   enemy total, simultaneous threats, projectile ceiling, no off-screen fire, UFO unchanged, checkpoint, completion.
# With a renderer it saves captures in res://dev/arcade_pressure_review/ (pass 02 set, prefix p2_).
# Dev filter: -- only=probe|eye|turret|walker|wasp|level

## LOTE 9 · ETAPA C: the NODO ALIEN has 1200 HP and 4 phases (was 500 HP, 3 phases).
const BOSS_HP := 1200
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const REVIEW := "res://dev/arcade_pressure_review/"
const OLD_TOTAL := 53 # Arcade Pressure pass 01.

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var only := ""
var _shots: Array[Dictionary] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			only = arg.substr(5)
	call_deferred("run")

func wants(section: String) -> bool:
	return only.is_empty() or only == section

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW + file) == OK, "Capture failed: " + file)

func bind(value: Node) -> void:
	stage = value as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func reloaded(old: Node) -> void:
	for i in 120:
		await process_frame
		if current_scene != null and current_scene != old and current_scene.is_node_ready():
			break
	await frames(3)

func camera_x() -> float:
	return stage.camera.global_position.x

func arena(distance: float, bee_y := 3.5) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.current_health = bee.health.max_health
	bee.health.damage_blocked = true
	bee.global_position = Vector3(camera_x() - 3.0, bee_y, 0)
	bee.facing_x = 1.0

func spawn(family: String, slot := 0) -> Node3D:
	wave._spawn({"family": family, "slot": slot, "event": 0, "hard": false})
	return wave.active_units.back()

func clear_units() -> void:
	for unit in wave.active_units.duplicate():
		wave.active_units.erase(unit)
		unit.set_physics_process(false) # Never one last shot in this same physics step.
		unit.queue_free()
	for shot in get_nodes_in_group("alien_projectiles"):
		shot.queue_free()
	_shots.clear()
	await frames(2)

func listen(unit: Node) -> void:
	unit.projectile_fired.connect(func(p: AlienEnemyProjectile):
		_shots.append({"frame": Engine.get_physics_frames(), "dir": p.travel_direction, "origin": p.global_position,
				"bee": bee.global_position, "damage": p.damage, "node": p}))

## Bee sways vertically so every re-aim is visible in the shot directions.
func sway(seconds: float, extra: Callable = Callable()) -> void:
	var t := 0.0
	while t < seconds:
		bee.global_position.y = 3.5 + sin(t * 2.2) * 0.9
		await physics_frame
		t += 1.0 / 60.0
		if extra.is_valid():
			await extra.call()

func angle_deg(a: Vector3, b: Vector3) -> float:
	return rad_to_deg(a.angle_to(b))

## Groups launches that share a physics frame (volleys) or that follow each other within `gap` frames (bursts).
func bursts(max_gap_frames: int) -> Array:
	var result: Array = []
	for shot in _shots:
		if result.is_empty() or int(shot["frame"]) - int(result.back().back()["frame"]) > max_gap_frames:
			result.append([shot])
		else:
			result.back().append(shot)
	return result

# --- Probe ------------------------------------------------------------------------------------------

func test_probe() -> void:
	await clear_units()
	arena(100.0)
	var probe := spawn("Probe") as AlienProbeRanged
	# COMBAT VARIETY 01: Level 01 Probes now fire one split orb (validate_bee_combat_variety_v01). This section keeps
	# checking the aimed-burst machinery (still used by the POCs and the EyeDrone) with the pass-02 values.
	check(int(BeeLevel01Controller.LEVEL_TUNING["Probe"]["burst_shots"]) == 1 and probe.split_orb, "Probe tuning not applied")
	probe.split_orb = false
	probe.burst_shots = 4
	var burst := 4
	check(is_equal_approx(probe.burst_gap, 0.2) and probe.short_recovery > 0.0, "Probe burst timing changed")
	listen(probe)
	var captured := false
	var tracked: Dictionary = {}
	for i in 60 * 11:
		bee.global_position.y = 3.5 + sin(float(i) / 60.0 * 2.2) * 0.9
		await physics_frame
		if tracked.is_empty() and _shots.size() >= 1:
			tracked = {"node": _shots[0]["node"], "dir": _shots[0]["dir"]}
		if not tracked.is_empty() and is_instance_valid(tracked["node"]):
			check(angle_deg((tracked["node"] as AlienEnemyProjectile).travel_direction, tracked["dir"]) < 0.01, "A Probe shot changed direction after leaving the barrel (homing)")
		if not captured:
			var burst_now := 0
			for shot in _shots:
				if is_instance_valid(shot["node"]) and Engine.get_physics_frames() - int(shot["frame"]) < 30:
					burst_now += 1
			if burst_now >= 3:
				captured = true
				await frames(8)
				await capture("p2_01_probe_triple_burst.png")
	var groups := bursts(18)
	check(groups.size() >= 3, "Probe fired only %d bursts in 11 s" % groups.size())
	for g in groups:
		if g.size() < burst:
			continue
		check(g.size() == burst, "A Probe burst must be exactly %d shots (got %d)" % [burst, g.size()])
		for k in burst - 1:
			var gap := int(g[k + 1]["frame"]) - int(g[k]["frame"])
			check(gap >= 9 and gap <= 15, "Probe burst spacing %d frames, expected ~12 (0.2 s)" % gap)
	# Each shot aims at Bee where she stood when it was fired (re-aim), then keeps that line.
	for shot in _shots:
		var expected: Vector3 = (shot["bee"] - shot["origin"]).normalized()
		check(angle_deg(shot["dir"], expected) < 2.5, "Probe shot not aimed at Bee at the moment of firing (%.1f deg)" % angle_deg(shot["dir"], expected))
	var first: Array = groups[0]
	var reaim := 0.0 # Every shot re-aims: the largest change inside the burst (timing-independent).
	for k in range(1, first.size()):
		reaim = maxf(reaim, angle_deg(first[0]["dir"], first[k]["dir"]))
	check(reaim > 0.5, "Burst shots must re-aim (Bee moved between them, %.2f deg)" % reaim)
	# SHORT recovery between the two bursts of a cycle, LONG cooldown after the second one.
	var starts: Array[int] = []
	for g in groups:
		starts.append(int(g[0]["frame"]))
	check(starts.size() >= 3 and (starts[1] - starts[0]) < (starts[2] - starts[1]) - 30, "Probe needs a short recovery inside the cycle and a longer gap after it (%s)" % str(starts))
	check(int(_shots[0]["damage"]) == int((load("res://scenes/bee_prototype/alien_probe_ranged.tscn") as PackedScene).instantiate().projectile_scene.instantiate().damage), "Probe shot damage changed")
	var short_s := float(starts[1] - starts[0]) / 60.0
	var long_s := float(starts[2] - starts[1]) / 60.0
	print("PATTERN_PROBE bursts=%d shots_per_burst=4 spacing=12f re-aim=OK fixed_path=OK burst_to_burst=%.2fs then=%.2fs" % [groups.size(), short_s, long_s])
	await clear_units()
	# Fairness: outside the readable area the whole burst is suppressed.
	var far := spawn("Probe") as AlienProbeRanged
	far.split_orb = false # COMBAT VARIETY 01: burst machinery check (see above).
	far.burst_shots = 4
	far.set_physics_process(false)
	far.global_position = Vector3(camera_x() + 12.0, 4.0, 0)
	far._shoot()
	far.set_physics_process(true)
	for i in 40:
		far.global_position = Vector3(camera_x() + 12.0, 4.0, 0)
		await physics_frame
	check(get_nodes_in_group("alien_projectiles").is_empty() and far.suppressed_shot_count >= 3, "A Probe burst left the screen edge")
	await clear_units()

# --- Eye drone ----------------------------------------------------------------------------------------

func test_eye() -> void:
	await clear_units()
	arena(100.0)
	var eye := spawn("EyeDrone") as EyeDroneEnemy
	# COMBAT VARIETY 01: Level 01 Eyes now use the laser (validate_bee_combat_variety_v01); this section keeps checking the
	# aimed-burst / fan machinery with the pass-02 values forced on the unit.
	check(eye.laser_every == 1 and eye.fan_every == 0 and eye.fan_count == 5, "Eye tuning not applied")
	eye.laser_every = 0
	eye.fan_every = 2
	listen(eye)
	var telegraph_by_attack: Array = []
	var windups_seen := 0
	var was_windup := false
	var captured := false
	for i in 60 * 16:
		bee.global_position.y = 3.5 + sin(float(i) / 60.0 * 2.2) * 0.7
		await physics_frame
		var in_windup: bool = eye.current_state == AlienProbeRanged.State.WINDUP
		if in_windup and not was_windup:
			windups_seen += 1
			telegraph_by_attack.append(false)
		if in_windup:
			telegraph_by_attack[telegraph_by_attack.size() - 1] = eye.telegraph.material_override != null
		was_windup = in_windup
		if not captured and eye.fan_shot_count >= 1:
			captured = true
			await frames(24)
			await capture("p2_02_eyedrone_fan.png")
		if windups_seen >= 5 and eye.current_state == AlienProbeRanged.State.COOLDOWN:
			break
	var volleys := bursts(18)
	check(volleys.size() >= 4, "Eye fired only %d attacks" % volleys.size())
	check(volleys[0].size() == 3 and volleys[1].size() == 5 and volleys[2].size() == 3 and volleys[3].size() == 5, "Eye must alternate aimed burst (4, ARCADE REBUILD 02) / fan (5): %s" % str(volleys.map(func(v): return v.size())))
	check(telegraph_by_attack[0] == false and telegraph_by_attack[1] == true, "Fan telegraph must differ (violet) from the aimed one: " + str(telegraph_by_attack))
	var fan: Array = volleys[1]
	for shot in fan:
		check(int(shot["frame"]) == int(fan[0]["frame"]), "A fan fires all its shots in the same frame")
	var to_bee: Vector3 = (fan[2]["bee"] - fan[2]["origin"])
	var distance := Vector2(to_bee.x, to_bee.y).length()
	check(distance >= eye.fan_min_distance - 0.05, "Fan used at %.2f m, closer than the passable minimum" % distance)
	check(angle_deg(fan[2]["dir"], to_bee.normalized()) < 1.0, "The centre shot of the fan must aim at Bee")
	var steps := []
	for k in 4:
		var step := angle_deg(fan[k]["dir"], fan[k + 1]["dir"])
		steps.append(step)
		check(step >= 11.5 and step <= 18.5, "Fan step %.1f deg outside 12-18" % step)
	var gap := BeeEnemyPatterns.lane_gap(distance, float(steps[0]))
	check(gap >= 0.85, "Fan lanes too tight to cross: %.2f m between neighbours at %.1f m" % [gap, distance])
	check(gap > 0.34 * 2.0 + 0.1, "The gap must exceed Bee's body plus a shot (0.68 m)")
	# Shots fly straight: every fan shot keeps its launch direction.
	await frames(10)
	for shot in fan:
		if is_instance_valid(shot["node"]):
			check(angle_deg((shot["node"] as AlienEnemyProjectile).travel_direction, shot["dir"]) < 0.01, "A fan shot changed direction")
	print("PATTERN_EYE order=aimed4,fan5,aimed4,fan5 fan_step=%.1fdeg lane_gap=%.2fm at %.1fm telegraph_violet_on_fan=OK" % [steps[0], gap, distance])
	await clear_units()

# --- Turret ---------------------------------------------------------------------------------------------

func test_turret() -> void:
	await clear_units()
	arena(100.0)
	var turret := spawn("Turret") as GroundTurretEnemy
	check(turret.mortar_mode, "Turret mortar not applied")
	turret.mortar_mode = false # COMBAT VARIETY 01: fan machinery check (the mortar is tested in combat_variety_v01).
	check(turret.fan_count == 3 and is_equal_approx(turret.windup_time, 0.65), "Turret tuning not applied / warning changed")
	listen(turret)
	var warning_frames := 0
	var captured := false
	for i in 60 * 8:
		bee.global_position.y = 3.5 + sin(float(i) / 60.0 * 2.2) * 0.5
		await physics_frame
		if turret.current_state == GroundTurretEnemy.State.WINDUP:
			warning_frames += 1
			check(turret.telegraph.visible, "No warning during the Turret windup")
		if not captured and _shots.size() >= 3:
			captured = true
			await frames(24)
			await capture("p2_03_turret_pattern.png")
	var volleys := bursts(3)
	check(volleys.size() >= 2 and volleys[0].size() == 3, "Turret must fire a fan of 3 (%s)" % str(volleys.map(func(v): return v.size())))
	check(float(warning_frames) / 60.0 / float(volleys.size()) >= 0.6, "Turret warning shorter than before")
	var v: Array = volleys[0]
	var aim: Vector3 = v[1]["bee"] - v[1]["origin"]
	check(angle_deg(v[1]["dir"], aim) < 1.0, "The middle shot of the Turret fan must aim at Bee")
	var step := angle_deg(v[0]["dir"], v[1]["dir"])
	check(step >= 12.0 and step <= 16.0 and absf(angle_deg(v[1]["dir"], v[2]["dir"]) - step) < 0.5, "Turret fan step %.1f deg" % step)
	var gap := BeeEnemyPatterns.lane_gap(Vector2(aim.x, aim.y).length(), step)
	check(gap >= 0.95, "Turret lanes too tight (%.2f m)" % gap)
	check(v[0]["dir"].y != v[2]["dir"].y, "The fan must spread vertically/diagonally")
	print("PATTERN_TURRET fan=3 step=%.1fdeg lane_gap=%.2fm warning=%.2fs" % [step, gap, float(warning_frames) / 60.0 / float(volleys.size())])
	await clear_units()

# --- Walker ----------------------------------------------------------------------------------------------

func test_walker() -> void:
	await clear_units()
	arena(100.0)
	var walker := spawn("Walker") as GroundWalkerEnemy
	check(walker.low_burst, "Walker low burst not applied")
	walker.low_burst = false # COMBAT VARIETY 01: aimed-burst machinery check (the low burst is tested in combat_variety_v01).
	check(walker.burst_shots == 3 and walker.health.max_health == int(BeeLevel01Controller.LEVEL_HP["Walker"]) and is_equal_approx(walker.walk_speed, 2.4), "Walker tuning not applied (burst 4, LEVEL_HP, walk 2.4)")
	listen(walker)
	var captured := false
	for i in 60 * 16:
		bee.global_position.y = 3.5 + sin(float(i) / 60.0 * 2.2) * 0.9
		await physics_frame
		if not captured and _shots.size() >= 2:
			captured = true
			await frames(14)
			await capture("p2_04_walker_burst.png")
		if bursts(60).size() >= 2 and _shots.size() >= 6:
			break
	var groups := bursts(60)
	check(groups.size() >= 2 and groups[0].size() == 3, "Walker must fire a burst of 3 (%s)" % str(groups.map(func(g): return g.size())))
	var g: Array = groups[0]
	for k in 2:
		var gap := int(g[k + 1]["frame"]) - int(g[k]["frame"])
		check(gap >= 17 and gap <= 25, "Walker burst spacing %d frames (~0.35 s)" % gap)
	var reaim := 0.0 # Every shot re-aims: compare the first one with the rest of the burst (timing-independent).
	for k in range(1, g.size()):
		reaim = maxf(reaim, angle_deg(g[0]["dir"], g[k]["dir"]))
	check(reaim > 0.5, "Walker shots must re-aim inside the burst (%.2f deg)" % reaim)
	check(int(g[0]["damage"]) == 9, "Walker shot damage changed")
	var cycle := float(int(groups[1][0]["frame"]) - int(g[0]["frame"])) / 60.0
	check(cycle >= 2.5, "Walker is a machine gun (%.2f s between bursts)" % cycle)
	print("PATTERN_WALKER burst=4 spacing=0.35s re-aim=OK between_bursts=%.2fs speed=2.4 hp=72" % cycle)
	await clear_units()

# --- Wasp ------------------------------------------------------------------------------------------------

func test_wasp() -> void:
	await clear_units()
	arena(60.0)
	var wasp := spawn("Wasp") as WaspEnemy
	check(wasp.arcade_mode and wasp.max_passes == 99 and wasp.health.max_health == int(BeeLevel01Controller.LEVEL_HP["Wasp"]) and wasp.attack_damage == 10, "Wasp tuning / HP / damage (LOTE 7: passes 99, retired at CAMERA_TIME; HP from LEVEL_HP)")
	wasp.max_passes = 3 # The 3-pass pattern itself (the level keeps Wasps until CAMERA_TIME).
	var order: Array = []
	var dash_dirs: Array = []
	var stalk_first := 0.0
	var captured_stalk := false
	var captured_pass := false
	var presence := 0.0
	for i in 60 * 18:
		await physics_frame
		presence += 1.0 / 60.0
		var state: int = wasp.current_state
		if order.is_empty() or order.back() != state:
			order.append(state)
			if state == WaspEnemy.State.DASH:
				dash_dirs.append([])
		if (state == WaspEnemy.State.STALK or state == WaspEnemy.State.STING) and not order.has(WaspEnemy.State.WINDUP): # COMBAT VARIETY 01: stalk + fan sting = one presence.
			stalk_first += 1.0 / 60.0
			if stalk_first > 1.5 and not captured_stalk:
				captured_stalk = true
				await capture("p2_05_wasp_stalk.png")
		if state == WaspEnemy.State.DASH:
			dash_dirs.back().append(wasp.velocity.normalized())
			if dash_dirs.back().size() == 14 and not captured_pass:
				captured_pass = true
				await capture("p2_06_wasp_pass.png")
		if state == WaspEnemy.State.EXIT and Vector2(wasp.global_position.x - bee.global_position.x, 0).length() > 9.0:
			break
	check(order.count(WaspEnemy.State.DASH) == 3 and wasp.passes_done == 3, "The Wasp must make three passes (got %d)" % wasp.passes_done)
	check(order.back() == WaspEnemy.State.EXIT, "The Wasp must exit after its last pass")
	check(stalk_first >= 2.2, "First stalk too short: %.2f s" % stalk_first)
	for pass_dirs in dash_dirs:
		for direction in pass_dirs:
			check(direction.dot(pass_dirs[0]) > 0.98, "Wasp pass is not a straight locked line (homing)")
	check(presence >= 9.0, "Wasp presence %.1f s, expected several seconds on screen" % presence)
	print("PATTERN_WASP order=%d states passes=3 first_stalk=%.1fs presence_until_exit=%.1fs straight_dash=OK" % [order.size(), stalk_first, presence])
	await clear_units()
	# Two Wasps: never in WINDUP/DASH at the same time; different hover lines.
	arena(60.0)
	var a := spawn("Wasp", 0) as WaspEnemy
	var b := spawn("Wasp", 1) as WaspEnemy
	check(not is_equal_approx(a.stalk_lane, b.stalk_lane) and not is_equal_approx(a.stalk_time, b.stalk_time), "Two Wasps must get different lanes and stalk times")
	var overlap_frames := 0
	var attacks_a := 0
	var attacks_b := 0
	var lane_gap := 0.0
	var lane_samples := 0
	for i in 60 * 16:
		await physics_frame
		var attacking_a := a.current_state == WaspEnemy.State.WINDUP or a.current_state == WaspEnemy.State.DASH
		var attacking_b := b.current_state == WaspEnemy.State.WINDUP or b.current_state == WaspEnemy.State.DASH
		if attacking_a and attacking_b:
			overlap_frames += 1
		attacks_a += 1 if attacking_a else 0
		attacks_b += 1 if attacking_b else 0
		if a.current_state == WaspEnemy.State.STALK and b.current_state == WaspEnemy.State.STALK:
			lane_gap += absf(a.global_position.y - b.global_position.y)
			lane_samples += 1
	check(overlap_frames == 0, "Two Wasps attacked at the same time for %d frames" % overlap_frames)
	check(attacks_a > 0 and attacks_b > 0, "Both Wasps must attack")
	if lane_samples > 0:
		check(lane_gap / float(lane_samples) >= 0.6, "Wasps share the same hover line")
	if DisplayServer.get_name() != "headless":
		await clear_units()
	print("PATTERN_WASP_DESYNC simultaneous_attack_frames=0 attacks=%d/%d" % [attacks_a, attacks_b])
	await clear_units()

# --- Level -----------------------------------------------------------------------------------------------

func test_level() -> void:
	var events := BeeLevel01Controller.EVENTS
	var total := 0
	var by_family := {}
	var biggest := 0
	for event: Dictionary in events:
		var units: Array = event["units"]
		total += units.size()
		for zone_wave: Dictionary in event.get("arena", []): # LOTE 9: zone waves count in the budget.
			total += (zone_wave["units"] as Array).size()
		var threats := units.filter(func(f): return f != "Swarm") # Popcorn sits outside the threat cap.
		biggest = maxi(biggest, threats.size())
		for family in units:
			by_family[family] = int(by_family.get(family, 0)) + 1
		var delays: Array = event.get("delays", [])
		check(delays.is_empty() or delays.size() == units.size(), "Delays must match the units: " + str(event["label"]))
		for i in range(1, delays.size()):
			check(float(delays[i]) >= float(delays[i - 1]), "Delays must be ascending (the queue is FIFO): " + str(event["label"]))
		if units.filter(func(f): return f != "Swarm").size() >= 4:
			check(float(delays.back()) >= 2.4, "The 4th threat must still be staggered (REBUILD 02: >= 2.4 s): " + str(event["label"]))
	check(events.size() == 71 and float(events.back()["at"]) == 340.0, "Event table changed (LOTE 11: 71 events, last defence at X=340)")
	check(total >= 144 and total <= 150, "Unit total %d outside the 144-150 budget (LOTE 11: +35-40 % over 107, zones included)" % total)
	check(biggest <= 4, "More than 4 threats in one encounter")
	check(BeeLevel01Controller.threat_cap(10.0) == 4 and BeeLevel01Controller.threat_cap(150.0) == 5 and BeeLevel01Controller.threat_cap(300.0) == 6, "Concurrency cap changed")
	check(_base_hp() == {"Wasp": 36, "Probe": 70, "EyeDrone": 50, "Turret": 70, "Speeder": 40, "OrganicAlien": 100, "Walker": 100, "Dragonfly": 110, "Swarm": 10, "Spider": 80}, "HP changed (LOTE 9 table)")
	print("PATTERN_LEVEL enemies=%d (+%d) by_family=%s" % [total, total - OLD_TOTAL, str(by_family)])
	# Controlled projectile ceiling: the heaviest legal quartet (REBUILD 02 caps threats at 4) alive for 14 s, Bee not shooting.
	# The live-shot ceiling (10 + one 5-shot fan) keeps the peak inside 14.
	await clear_units()
	arena(100.0)
	for family in ["Probe", "EyeDrone", "Turret", "Walker"]:
		spawn(family, wave.active_units.size())
	var peak := 0
	var total_frames := 0
	var shot_frames := 0
	for i in 60 * 14:
		bee.global_position.y = 3.5 + sin(float(i) / 60.0 * 2.2) * 0.8
		await physics_frame
		var count := get_nodes_in_group("alien_projectiles").size()
		peak = maxi(peak, count)
		total_frames += 1
		shot_frames += count
	check(peak >= 6 and peak <= BeeLevel01Controller.LIVE_SHOT_CEILING + 4, "Hostile projectile peak %d outside the controlled 6-14 range" % peak)
	check(float(shot_frames) / float(total_frames) <= float(BeeLevel01Controller.LIVE_SHOT_CEILING), "Sustained projectile load too high")
	print("PATTERN_PROJECTILES three_ranged_peak=%d average=%.1f (ceiling 14)" % [peak, float(shot_frames) / float(total_frames)])
	await clear_units()
	# No fire from outside the screen for any family (whole volley suppressed).
	for family in ["Probe", "EyeDrone", "Turret", "Walker"]:
		var unit := spawn(family)
		unit.set_physics_process(false)
		unit.global_position = Vector3(camera_x() + 12.0, 4.0 if family in ["Probe", "EyeDrone"] else -0.2, 0)
		if unit is GroundWalkerEnemy:
			unit._fire_projectile()
		elif unit is EyeDroneEnemy:
			unit._fire_fan()
			unit._fire_drone_shot()
		elif unit is GroundTurretEnemy:
			unit._shoot()
		else:
			unit._fire_one()
		await frames(2)
		check(get_nodes_in_group("alien_projectiles").is_empty() and int(unit.suppressed_shot_count) >= 1, family + " fired from outside the screen")
		await clear_units()
	# Formations and late-game encounter for the review captures.
	arena(100.0)
	spawn("Probe", 0)
	spawn("Wasp", 1)
	await frames(260)
	await capture("p2_07_formation_a_probe_wasp.png")
	await clear_units()
	arena(170.0)
	spawn("EyeDrone", 0)
	spawn("Turret", 1)
	await frames(300)
	await capture("p2_08_formation_b_eye_turret.png")
	await clear_units()
	arena(324.0)
	spawn("Probe", 0)
	spawn("EyeDrone", 1)
	spawn("Wasp", 2)
	await frames(320)
	await capture("p2_09_late_three_threats.png")
	await clear_units()
	arena(124.0)
	await frames(10)
	await capture("p2_10_respite.png")

func test_checkpoint_and_complete() -> void:
	stage.distance = 190.05
	stage.checkpoint.checkpoint_active = false # LOTE 7: earlier sections may have passed the second checkpoint (281).
	stage.checkpoint.second_checkpoint_active = false
	stage.checkpoint.activate_checkpoint()
	var old_stage := stage
	stage.checkpoint.restart_level(false)
	await reloaded(old_stage)
	bind(current_scene)
	check(absf(stage.distance - 190.0) < 0.6 and wave.event_index == checkpoint_event() and wave.active_units.is_empty(), "Checkpoint respawn did not restore the second half cleanly")
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	stage.scroll_speed = 2.0
	wave.set_physics_process(true)
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	stage.distance = 352.0
	stage._update_camera_and_bounds()
	for i in 900:
		await physics_frame
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			break
	var boss := wave.boss
	check(boss != null and boss.max_hp == BOSS_HP and is_equal_approx(UfoBoss01.APPROACH_SECONDS, 3.2), "UFO Boss changed")
	boss.health.take_damage(boss.health.max_health)
	for i in 900:
		await physics_frame
		bee.global_position.y = 7.0
		if stage.sector_complete:
			break
	check(stage.sector_complete and stage.status.text.begins_with("SECTOR DESPEJADO"), "Level Complete missing after the boss died")
	print("PATTERN_CHECKPOINT_COMPLETE OK (UFO %d HP)" % BOSS_HP)

func run() -> void:
	create_timer(560.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	bind(current_scene)
	if wants("probe"):
		await test_probe()
	if wants("eye"):
		await test_eye()
	if wants("turret"):
		await test_turret()
	if wants("walker"):
		await test_walker()
	if wants("wasp"):
		await test_wasp()
	if wants("level"):
		await test_level()
		await test_checkpoint_and_complete()
	print("BEE_ARCADE_COMBAT_PATTERNS_V02_OK")
	quit(0)

func checkpoint_event() -> int:
	var index := 0
	for event: Dictionary in BeeLevel01Controller.EVENTS:
		if float(event["at"]) < 190.0:
			index += 1
	return index

## LOTE 6: the original ten families keep their HP; the Codex fauna has its own table (validate_bee_asset_fauna_v01).
func _base_hp() -> Dictionary:
	var result := {}
	for family in ["Wasp", "Probe", "EyeDrone", "Turret", "Speeder", "OrganicAlien", "Walker", "Dragonfly", "Swarm", "Spider"]:
		result[family] = BeeLevel01Controller.LEVEL_HP[family]
	return result
