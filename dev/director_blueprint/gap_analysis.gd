extends SceneTree
## DEV ONLY (LEVEL 01 ARCADE DIRECTOR BLUEPRINT 01). Baseline measurement of the real level: plays Level 01 with a
## passive bot (follows the nearest enemy's height, fires every `fire` seconds, never dodges, never dies) and logs,
## second by second, what the player has to DO. It changes nothing in the game.
##
## A second is a DECISION second when at least one of these holds (otherwise it is a DECISION GAP):
##   enemy      a hostile is alive on screen (priorities, aim, dodge)
##   projectile a hostile projectile is alive
##   hazard     the Giant Human is alerting / crossing, or the boss is active
##   pickup     pollen or a power-up capsule is within the visible window (a route/collect decision)
##   world      a crate or breakable rock is within the visible window and still standing (shoot / route decision)
##   moment     a designed visual moment is on screen: landmark, checkpoint, or the middle of a light transition
## godot --headless --fixed-fps 60 --path . --script res://dev/director_blueprint/gap_analysis.gd -- fire=0.6

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const WINDOW_BACK := 6.0
const WINDOW_FRONT := 7.0
const BLOCK := 12.0
## Designed visual moments (X, half width in metres of scroll where they count as on screen).
const MOMENTS := {"GiantBottle": [41.0, 7.0], "FallenLog": [55.0, 7.0], "DistantBottle": [188.0, 7.0], "Checkpoint": [190.0, 8.0],
		"MiddayLight": [140.0, 18.0], "SunsetLight": [250.0, 18.0], "BoulderRun": [96.0, 6.0]}

var fire_interval := 0.6

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("fire="):
			fire_interval = float(arg.substr(5))
	call_deferred("run")

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
	var rows: Array[Dictionary] = []   # one per game second
	var sec := {"decision": false, "enemy": false, "projectile": false, "hazard": false, "pickup": false, "pollen": false, "world": false, "moment": false,
			"threats": 0, "shots": 0.0, "frames": 0, "families": {}, "dist": 0.0}
	var t := 0.0
	var next_sec := 1.0
	var fire_left := 0.0
	var checkpoint_x := 190.0
	var fam_seen := {}
	for i in 60 * 420:
		await physics_frame
		t += 1.0 / 60.0
		var cam_x := stage.camera.global_position.x
		var lo := cam_x - WINDOW_BACK
		var hi := cam_x + WINDOW_FRONT
		sec["frames"] += 1
		sec["dist"] = stage.distance
		var threats := wave.active_units.size()
		sec["threats"] = maxi(int(sec["threats"]), threats)
		var shots := get_nodes_in_group("alien_projectiles").size()
		sec["shots"] += shots
		for unit in wave.active_units:
			if unit.global_position.x < hi:
				sec["enemy"] = true
				var fam := str(unit.name).split("_")[0]
				sec["families"][fam] = true
		if shots > 0:
			sec["projectile"] = true
		if wave._waiting_for_human or wave.human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING or (wave.boss != null and wave.boss.is_active()):
			sec["hazard"] = true
		for group_name in ["Pollen", "Powerups"]:
			for item in stage.get_node(group_name).get_children():
				if not item.is_queued_for_deletion() and item.global_position.x > lo and item.global_position.x < hi:
					sec["pickup" if group_name == "Powerups" else "pollen"] = true
		for crate in stage.get_node("Destructibles").get_children():
			if not crate.is_destroyed and crate.global_position.x > lo and crate.global_position.x < hi:
				sec["world"] = true
		for rock in get_nodes_in_group("breakable_rocks"):
			if not rock.is_destroyed and rock.global_position.x > lo and rock.global_position.x < hi:
				sec["world"] = true
		for key in MOMENTS:
			if absf(stage.distance - float(MOMENTS[key][0])) <= float(MOMENTS[key][1]):
				sec["moment"] = true
				fam_seen[key] = true
		# Bot.
		var target: Node3D
		var best := INF
		for unit in wave.active_units:
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
			sec["decision"] = bool(sec["enemy"] or sec["projectile"] or sec["hazard"] or sec["pickup"] or sec["world"] or sec["moment"])
			sec["t"] = next_sec
			sec["shots"] = float(sec["shots"]) / maxf(float(sec["frames"]), 1.0)
			rows.append(sec)
			sec = {"decision": false, "enemy": false, "projectile": false, "hazard": false, "pickup": false, "pollen": false, "world": false, "moment": false,
					"threats": 0, "shots": 0.0, "frames": 0, "families": {}, "dist": 0.0}
			next_sec += 1.0
		if wave.boss != null and wave.boss.is_active():
			break
	print("GAP fire=%.2f seconds_to_boss=%d" % [fire_interval, rows.size()])
	# Timeline blocks.
	var block_start := 0
	while block_start < rows.size():
		var block_end := mini(block_start + int(BLOCK), rows.size())
		var enemy_s := 0
		var shot_s := 0
		var world_s := 0
		var pick_s := 0
		var moment_s := 0
		var hazard_s := 0
		var gap_s := 0
		var max_threats := 0
		var shot_sum := 0.0
		var peak := 0.0
		var fams := {}
		for k in range(block_start, block_end):
			var r: Dictionary = rows[k]
			enemy_s += 1 if r["enemy"] else 0
			shot_s += 1 if r["projectile"] else 0
			world_s += 1 if r["world"] else 0
			pick_s += 1 if r["pickup"] else 0
			moment_s += 1 if r["moment"] else 0
			hazard_s += 1 if r["hazard"] else 0
			gap_s += 0 if r["decision"] else 1
			max_threats = maxi(max_threats, int(r["threats"]))
			shot_sum += float(r["shots"])
			peak = maxf(peak, float(r["shots"]))
			for f in r["families"]:
				fams[f] = true
		var n := block_end - block_start
		print("BLOCK %3d-%3ds x=%3d-%3d enemy=%2d shots=%2d world=%2d pickup=%2d moment=%2d hazard=%2d GAP=%2d/%d maxThreats=%d shots_avg=%.1f families=%s" % [
			block_start, block_end, int(rows[block_start]["dist"]), int(rows[block_end - 1]["dist"]), enemy_s, shot_s, world_s, pick_s, moment_s, hazard_s, gap_s, n, max_threats, shot_sum / float(n), ",".join(fams.keys())])
		block_start = block_end
	# Decision gaps (>= 2 consecutive seconds with nothing to decide).
	var gaps: Array[String] = []
	var gap_total := 0
	var strict_total := 0
	var run_start := -1
	for k in rows.size() + 1:
		var is_gap: bool = k < rows.size() and not rows[k]["decision"]
		if is_gap and run_start < 0:
			run_start = k
		if not is_gap and run_start >= 0:
			var length := k - run_start
			strict_total += length
			if length >= 2:
				gap_total += length
				gaps.append("%ds-%ds (%ds, x=%d-%d)" % [run_start, k, length, int(rows[run_start]["dist"]), int(rows[k - 1]["dist"])])
			run_start = -1
	# No-threat stretches (>= 3 s without enemy, projectile or hazard) and what fills them.
	var stretches: Array[String] = []
	var boring := 0
	var start := -1
	for k in rows.size() + 1:
		var quiet: bool = k < rows.size() and not (rows[k]["enemy"] or rows[k]["projectile"] or rows[k]["hazard"])
		if quiet and start < 0:
			start = k
		if not quiet and start >= 0:
			var length := k - start
			if length >= 3:
				var world := false
				var power := false
				var moment := false
				var pollen := false
				for j in range(start, k):
					world = world or rows[j]["world"]
					power = power or rows[j]["pickup"]
					moment = moment or rows[j]["moment"]
					pollen = pollen or rows[j]["pollen"]
				var content := ("world " if world else "") + ("powerup " if power else "") + ("moment " if moment else "") + ("pollen " if pollen else "")
				var is_boring := not (world or power or moment)
				boring += length if is_boring else 0
				stretches.append("%ds-%ds (%ds, x=%d-%d) [%s]%s" % [start, k, length, int(rows[start]["dist"]), int(rows[k - 1]["dist"]), content.strip_edges(), " BORING" if is_boring else ""])
			start = -1
	print("QUIET_STRETCHES >=3s: ", " | ".join(stretches))
	print("QUIET_SUMMARY stretches=%d boring_seconds=%d" % [stretches.size(), boring])
	var no_threat := 0
	for r in rows:
		no_threat += 0 if (r["enemy"] or r["projectile"] or r["hazard"]) else 1
	print("GAP_SUMMARY decision_gaps>=2s=%d total_gap_seconds=%d (%.0f%% of %ds) any_gap_seconds=%d no_threat_seconds=%d (%.0f%%)" % [gaps.size(), gap_total, 100.0 * gap_total / rows.size(), rows.size(), strict_total, no_threat, 100.0 * no_threat / rows.size()])
	print("GAP_LIST ", " | ".join(gaps))
	quit(0)
