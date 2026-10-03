extends SceneTree
## DEV ONLY (ARCADE CONTENT & SPECTACLE REBUILD 02). Stricter than dev/director_blueprint/gap_analysis.gd: a second is
## ACTIVE only when there is ACTIVE PRESSURE OR A MEANINGFUL EVENT on screen:
##   threat     a hostile on screen (inside the visible width), not retreating, not a liberated animal
##   projectile a hostile projectile on screen
##   hazard     Giant Human alert / crossing, UFO active
##   pickup     a power-up capsule on screen (NOT pollen)
##   device     a shootable alien device still standing on screen (contaminated garden)
##   motion     a director set piece in significant motion (shorter windows than the old analyzer)
## Static rocks, crates, landmarks and pollen never count. The bot follows the nearest enemy's height, fires every
## `fire` seconds, never dodges and never dies. Nothing in the game changes.
##   godot --headless --fixed-fps 60 --path . --script res://dev/arcade_rebuild_v02_review/pressure_analysis.gd -- fire=0.3

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
## Seconds a director moment counts as "significant motion" (only the part that really moves).
const MOTION_SECONDS := {"opening_can": 3.0, "human_aftermath": 4.0, "bomb_reward": 2.0, "contaminated_garden": 3.0,
		"last_silence": 4.0, "depth_formation": 3.0, "scale_event": 6.0, "preboss_power": 4.0, "walker_showcase": 2.0}
## Designed respites (X ranges): a gap fully inside one is reported apart from the "dead air".
const RESPITES := [[0.0, 8.0], [140.0, 156.0], [298.0, 312.0]]

var fire_interval := 0.6

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("fire="):
			fire_interval = float(arg.substr(5))
	call_deferred("run")

func _new_row() -> Dictionary:
	return {"active": false, "threat": false, "projectile": false, "hazard": false, "pickup": false, "device": false, "motion": false,
			"shots_peak": 0, "shots_sum": 0.0, "frames": 0, "threats": 0, "dist": 0.0}

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await physics_frame
	await physics_frame
	var bee := stage.bee
	var wave := stage.wave as BeeLevel01Controller
	bee.set_physics_process(false)
	bee.health.max_health = 100000
	bee.health.current_health = 100000
	var half := BeeLevel01Framing.half_width_max(BeeLevel01Framing.DESIGN_ASPECT)
	var rows: Array[Dictionary] = []
	var row := _new_row()
	var t := 0.0
	var next_sec := 1.0
	var fire_left := 0.0
	var motion := {"t": 0.0, "until": 0.0}
	wave.director_moment.connect(func(id: StringName): motion["until"] = maxf(float(motion["until"]), float(motion["t"]) + float(MOTION_SECONDS.get(str(id), 2.0))))
	# Attack cycles per unit: projectile bursts seen while it lived (a burst = shots within 0.5 s).
	var cycles := {}
	var last_shot := {}
	var seen_shots := {}
	var names := {}
	var life := {} # per unit: family, alive seconds, seconds on screen, shots fired / suppressed
	for i in 60 * 480:
		await physics_frame
		t += 1.0 / 60.0
		motion["t"] = t
		var cam_x := stage.camera.global_position.x
		row["frames"] += 1
		row["dist"] = stage.distance
		var on_screen_threats := 0
		for unit in wave.active_units + wave.swarm_units:
			if not is_instance_valid(unit):
				continue
			var uid := unit.get_instance_id()
			if not life.has(uid):
				life[uid] = {"family": str(unit.name).split("_")[0], "born": t, "end": t, "shots": 0, "suppressed": 0, "onscreen": 0.0}
			var rec: Dictionary = life[uid]
			rec["end"] = t
			rec["shots"] = int(unit.get("projectile_fire_count")) if "projectile_fire_count" in unit else 0
			rec["suppressed"] = int(unit.get("suppressed_shot_count")) if "suppressed_shot_count" in unit else 0
			if absf(unit.global_position.x - cam_x) <= half:
				rec["onscreen"] = float(rec["onscreen"]) + 1.0 / 60.0
		for unit in wave.active_units:
			if not is_instance_valid(unit) or bool(unit.get_meta("level_retreat", false)):
				continue
			if absf(unit.global_position.x - cam_x) <= half and unit.visible:
				on_screen_threats += 1
		row["threats"] = maxi(int(row["threats"]), on_screen_threats)
		if on_screen_threats > 0:
			row["threat"] = true
		var shots := 0
		for shot in get_nodes_in_group("alien_projectiles"):
			var s := shot as Node3D
			if absf(s.global_position.x - cam_x) <= half + 0.5:
				shots += 1
			var hitbox = s.get_node_or_null("Hitbox3D")
			var owner_node = hitbox.attacker if hitbox != null else null
			var sid := s.get_instance_id()
			if owner_node != null and is_instance_valid(owner_node) and not seen_shots.has(sid):
				seen_shots[sid] = true # Only the birth of each shot counts (not every frame it is alive).
				var oid: int = owner_node.get_instance_id()
				names[oid] = str(owner_node.name)
				if t - float(last_shot.get(oid, -9.0)) > 0.5:
					cycles[oid] = int(cycles.get(oid, 0)) + 1
				last_shot[oid] = t
		row["shots_peak"] = maxi(int(row["shots_peak"]), shots)
		row["shots_sum"] += shots
		if shots > 0:
			row["projectile"] = true
		if wave._waiting_for_human or wave.human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING or (wave.boss != null and wave.boss.is_active()):
			row["hazard"] = true
		for item in stage.get_node("Powerups").get_children():
			if not item.is_queued_for_deletion() and absf(item.global_position.x - cam_x) <= half:
				row["pickup"] = true
		var escalation := stage.get_node_or_null("AlienEscalation")
		if escalation != null and "flower_freed" in escalation and not escalation.flower_freed and escalation.device != null \
				and absf(escalation.device.global_position.x - cam_x) <= half:
			row["device"] = true
		if t < float(motion["until"]):
			row["motion"] = true
		# Bot.
		var target: Node3D
		var best := INF
		for unit in wave.active_units:
			if not is_instance_valid(unit):
				continue
			var d := absf(unit.global_position.x - (cam_x - 3.0))
			if d < best:
				best = d
				target = unit
		bee.global_position = Vector3(cam_x - 3.0, 4.0 if target == null else clampf(target.global_position.y, 0.9, 6.4), 0.0)
		fire_left -= 1.0 / 60.0
		if fire_left <= 0.0 and target != null and target.global_position.x < cam_x + 8.5:
			bee.fire()
			fire_left = fire_interval
		if t >= next_sec:
			row["active"] = bool(row["threat"] or row["projectile"] or row["hazard"] or row["pickup"] or row["device"] or row["motion"])
			row["t"] = next_sec
			rows.append(row)
			row = _new_row()
			next_sec += 1.0
		if wave.boss != null and wave.boss.is_active():
			break
	var n := rows.size()
	var active := 0
	var threat_s := 0
	var shot_s := 0
	var peak := 0
	var shot_sum := 0.0
	var frames := 0
	var windows: Array[int] = [] # consecutive seconds with a projectile on screen
	var run_len := 0
	for r in rows:
		active += 1 if r["active"] else 0
		threat_s += 1 if r["threat"] else 0
		shot_s += 1 if r["projectile"] else 0
		peak = maxi(peak, int(r["shots_peak"]))
		shot_sum += float(r["shots_sum"])
		frames += int(r["frames"])
		if r["projectile"]:
			run_len += 1
		elif run_len > 0:
			windows.append(run_len)
			run_len = 0
	var sustained := 0
	for w in windows:
		sustained += 1 if w >= 2 else 0
	# Low-activity gaps (>= 3 s inactive), split into designed respites and dead air.
	var gaps: Array[String] = []
	var dead: Array[int] = []
	var start := -1
	for k in n + 1:
		var idle: bool = k < n and not rows[k]["active"]
		if idle and start < 0:
			start = k
		if not idle and start >= 0:
			var length := k - start
			if length >= 3:
				var x0 := float(rows[start]["dist"])
				var x1 := float(rows[k - 1]["dist"])
				var respite := false
				for range_x in RESPITES:
					respite = respite or (x0 >= float(range_x[0]) - 1.0 and x1 <= float(range_x[1]) + 1.0)
				gaps.append("%ds-%ds (%ds, x=%d-%d)%s" % [start, k, length, int(x0), int(x1), " RESPITE" if respite else ""])
				if not respite:
					dead.append(length)
			start = -1
	dead.sort()
	var longest: int = dead.back() if not dead.is_empty() else 0
	var dead_total := 0
	for d in dead:
		dead_total += d
	print("PRESSURE fire=%.2f seconds_to_boss=%d active=%d%% threat=%d%% projectile=%d%% shots_avg=%.2f shots_peak=%d" % [
		fire_interval, n, roundi(100.0 * active / maxf(n, 1)), roundi(100.0 * threat_s / maxf(n, 1)), roundi(100.0 * shot_s / maxf(n, 1)), shot_sum / maxf(frames, 1), peak])
	print("PRESSURE_WINDOWS projectile_windows=%d sustained(>=2s)=%d longest=%ds" % [windows.size(), sustained, windows.max() if not windows.is_empty() else 0])
	print("DEAD_AIR gaps>=3s=%d total=%ds longest=%ds" % [dead.size(), dead_total, longest])
	print("GAPS ", " | ".join(gaps))
	# Per 20 s block: shots average / peak, threats.
	var block := 0
	while block < n:
		var end := mini(block + 20, n)
		var b_peak := 0
		var b_sum := 0.0
		var b_frames := 0
		var b_threat := 0
		var b_active := 0
		for k in range(block, end):
			b_peak = maxi(b_peak, int(rows[k]["shots_peak"]))
			b_sum += float(rows[k]["shots_sum"])
			b_frames += int(rows[k]["frames"])
			b_threat = maxi(b_threat, int(rows[k]["threats"]))
			b_active += 1 if rows[k]["active"] else 0
		print("BLOCK %3d-%3ds x=%3d-%3d active=%2d/%d maxThreats=%d shots_avg=%.1f peak=%d" % [block, end, int(rows[block]["dist"]), int(rows[end - 1]["dist"]), b_active, end - block, b_threat, b_sum / maxf(b_frames, 1), b_peak])
		block = end
	# Ranged attack cycles per unit (projectile bursts while alive).
	var single := 0
	var multi := 0
	var detail: Array[String] = []
	for oid in cycles:
		var label := str(names[oid])
		if label.begins_with("UfoBoss"):
			continue
		if int(cycles[oid]) <= 1:
			single += 1
		else:
			multi += 1
		detail.append("%s:%d" % [label, cycles[oid]])
	print("ATTACK_CYCLES ranged_units=%d single_cycle=%d multi_cycle=%d" % [single + multi, single, multi])
	print("CYCLE_DETAIL ", " ".join(detail))
	var families := {}
	for uid in life:
		var rec: Dictionary = life[uid]
		var f := str(rec["family"])
		if not families.has(f):
			families[f] = {"n": 0, "alive": 0.0, "onscreen": 0.0, "shots": 0, "suppressed": 0, "silent": 0}
		var agg: Dictionary = families[f]
		agg["n"] += 1
		agg["alive"] += float(rec["end"]) - float(rec["born"])
		agg["onscreen"] += float(rec["onscreen"])
		agg["shots"] += int(rec["shots"])
		agg["suppressed"] += int(rec["suppressed"])
		agg["silent"] += 1 if int(rec["shots"]) == 0 else 0
	for f in families:
		var agg: Dictionary = families[f]
		var count := float(agg["n"])
		print("FAMILY %-12s n=%2d alive=%.1fs onscreen=%.1fs shots=%.1f suppressed=%.1f never_fired=%d" % [f, agg["n"], agg["alive"] / count, agg["onscreen"] / count, agg["shots"] / count, agg["suppressed"] / count, agg["silent"]])
	print("SPAWNED ", wave.spawned_by_family, " total=", wave.spawn_history.size(), " events=", BeeLevel01Controller.EVENTS.size())
	var pickups: Array[String] = []
	for item in stage.get_node("Powerups").get_children():
		pickups.append("%s@%d" % [item.name, int(item.global_position.x)])
	print("POWERUPS_LEFT ", pickups)
	quit(0)
