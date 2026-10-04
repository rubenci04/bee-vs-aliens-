extends SceneTree
## DEV ONLY (THREAT, CAMERA & BOSS REBUILD 03). Measures whether enemies get to be a problem, not just whether they
## exist. Bot: follows the nearest threat's height, fires every `fire` seconds with auto-aim, never dodges, never dies
## (so every number is an upper bound on how fast a real player clears things). Nothing in the game changes.
##   per family   visible lifetime, TTK (first hit -> death), attack starts, died before 1st / 2nd attack
##   combat only  seconds with a threat on screen: projectile average / peak, attack occupancy, threat occupancy
##   boss         fight duration with the S+ overcharge collected at the reveal (boss=1)
## godot --headless --fixed-fps 60 --path . --script res://dev/threat_camera_boss_v03_review/threat_analysis.gd -- fire=0.3 boss=1

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
## States that count as "attacking" (telegraph included: the player has to read and react).
const ATTACK_STATES := ["WINDUP", "SHOOT", "AIM", "DASH", "TELEGRAPH", "PASS", "LUNGE", "STING", "OVERLOAD", "RANGED",
		"SWEEP", "SUMMON"]

var fire_interval := 0.3
var fight_boss := false
var ghost := false # ghost=1: shots pass through Bee (a dodging player sees them cross the whole screen).

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("fire="):
			fire_interval = float(arg.substr(5))
		elif arg == "ghost=1":
			ghost = true
		elif arg == "boss=1":
			fight_boss = true
	call_deferred("run")

static func state_name(unit: Object) -> String:
	var value = unit.get("current_state") if "current_state" in unit else unit.get("state")
	if value == null:
		return ""
	var script := unit.get_script() as Script
	while script != null:
		var constants := script.get_script_constant_map()
		for enum_name in ["State", "Phase"]:
			if constants.has(enum_name) and constants[enum_name] is Dictionary:
				for key in constants[enum_name]:
					if constants[enum_name][key] == value:
						return str(key)
		script = script.get_base_script()
	return ""

static func is_attacking(unit: Object) -> bool:
	if unit is PopcornDrone:
		return (unit as PopcornDrone).get("_flash_left") != null and float(unit.get("_flash_left")) >= 0.0 and not bool(unit.get("_fired"))
	return state_name(unit) in ATTACK_STATES

func run() -> void:
	create_timer(1500.0, true, false, true).timeout.connect(func(): quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await physics_frame
	await physics_frame
	var bee := stage.bee
	var wave := stage.wave as BeeLevel01Controller
	bee.set_physics_process(false)
	bee.health.max_health = 1000000
	bee.health.current_health = 1000000
	if ghost:
		bee.hurtbox.monitorable = false
	var units := {} # id -> record
	var t := 0.0
	var fire_left := 0.0
	var combat_frames := 0
	var combat_shots := 0
	var combat_peak := 0
	var attack_frames := 0
	var threat_sum := 0
	var max_threats := 0
	var total_frames := 0
	var boss_start := -1.0
	var boss_end := -1.0
	var boss_shots_peak := 0
	var minions_seen := 0
	var gave_overcharge := false
	for i in 60 * 600:
		await physics_frame
		t += 1.0 / 60.0
		total_frames += 1
		var cam_x := stage.camera.global_position.x
		var on_screen: Array = []
		for unit in wave.active_units + wave.swarm_units:
			if not is_instance_valid(unit) or bool(unit.get_meta("level_retreat", false)):
				continue
			var id: int = unit.get_instance_id()
			if not units.has(id):
				units[id] = {"family": str(unit.name).split("_")[0], "seen": -1.0, "hit": -1.0, "end": -1.0, "attacks": 0, "attacking": false, "minion": unit.has_meta("boss_minion")}
				if unit.has_meta("boss_minion"):
					minions_seen += 1
			var rec: Dictionary = units[id]
			var visible := BeeShmupFairness.is_on_screen(unit, 0.0) and unit.visible and not CinematicDepthEntry.is_in_depth(unit)
			if visible:
				on_screen.append(unit)
				if float(rec["seen"]) < 0.0:
					rec["seen"] = t
				rec["end"] = t
			var health := unit.get_node_or_null("HealthComponent") as HealthComponent
			if health != null and float(rec["hit"]) < 0.0 and health.current_health < health.max_health:
				rec["hit"] = t
			var attacking := is_attacking(unit)
			if attacking and not bool(rec["attacking"]):
				rec["attacks"] = int(rec["attacks"]) + 1
			rec["attacking"] = attacking
		var boss_on := wave.boss != null and is_instance_valid(wave.boss) and wave.boss.is_active()
		var threats := on_screen.size() + (1 if boss_on else 0)
		var shots := 0
		for shot in get_nodes_in_group("alien_projectiles"):
			if BeeShmupFairness.is_on_screen(shot as Node3D, 0.5):
				shots += 1
		if threats > 0:
			combat_frames += 1
			combat_shots += shots
			combat_peak = maxi(combat_peak, shots)
			threat_sum += threats
			max_threats = maxi(max_threats, threats)
			var any_attack := boss_on and str(wave.boss.get("_attack_step")) in ["telegraph", "burst"]
			for unit in on_screen:
				any_attack = any_attack or is_attacking(unit)
			attack_frames += 1 if any_attack else 0
		# Bot: nearest threat (boss included), auto-aimed shots.
		var target: Node3D
		var best := INF
		for unit in on_screen:
			var d := absf(unit.global_position.x - bee.global_position.x)
			if d < best:
				best = d
				target = unit
		if target == null and boss_on:
			target = wave.boss
		var anchor_x := cam_x + BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.DESIGN_ASPECT)
		bee.global_position = Vector3(anchor_x, 4.0 if target == null else clampf(target.global_position.y, bee.flight_min.y, bee.flight_max.y), 0.0)
		fire_left -= 1.0 / 60.0
		if fire_left <= 0.0 and target != null:
			bee.fire()
			fire_left = fire_interval
		if wave.boss != null and is_instance_valid(wave.boss):
			if boss_on and boss_start < 0.0:
				boss_start = t
				if not gave_overcharge:
					bee.collect_spread_overcharge() # "S+ available": the pre-boss capsule was taken.
					gave_overcharge = true
			if boss_on:
				boss_shots_peak = maxi(boss_shots_peak, shots)
			if boss_on and not fight_boss:
				break
		if wave.boss_defeated and boss_end < 0.0:
			boss_end = t
			break
	# Per family.
	var families := {}
	for id in units:
		var rec: Dictionary = units[id]
		if float(rec["seen"]) < 0.0:
			continue
		var f := str(rec["family"]) + (" (minion)" if bool(rec["minion"]) else "")
		if not families.has(f):
			families[f] = {"n": 0, "life": 0.0, "ttk": 0.0, "ttk_n": 0, "attacks": 0, "none": 0, "one": 0}
		var agg: Dictionary = families[f]
		agg["n"] += 1
		agg["life"] += float(rec["end"]) - float(rec["seen"])
		if float(rec["hit"]) >= 0.0:
			agg["ttk"] += float(rec["end"]) - float(rec["hit"])
			agg["ttk_n"] += 1
		agg["attacks"] += int(rec["attacks"])
		agg["none"] += 1 if int(rec["attacks"]) == 0 else 0
		agg["one"] += 1 if int(rec["attacks"]) <= 1 else 0
	print("THREAT fire=%.2f seconds=%.0f units_seen=%d" % [fire_interval, t, units.size()])
	for f in families:
		var agg: Dictionary = families[f]
		var n := float(agg["n"])
		print("FAMILY %-20s n=%2d visible=%4.1fs ttk=%4.1fs attacks=%3.1f died_before_1st=%d before_2nd=%d" % [f, agg["n"], agg["life"] / n,
				agg["ttk"] / maxf(agg["ttk_n"], 1), agg["attacks"] / n, agg["none"], agg["one"]])
	var cf := maxf(combat_frames, 1)
	print("COMBAT seconds=%.0f (%.0f%% of run) shots_avg=%.2f shots_peak=%d attack_occupancy=%.0f%% threats_avg=%.2f threats_max=%d" % [
		combat_frames / 60.0, 100.0 * combat_frames / maxf(total_frames, 1), combat_shots / cf, combat_peak, 100.0 * attack_frames / cf, threat_sum / cf, max_threats])
	if boss_start >= 0.0:
		print("BOSS start=%.0fs duration=%s minions=%d shots_peak=%d" % [boss_start, ("%.1fs" % (boss_end - boss_start)) if boss_end > 0.0 else "n/a", minions_seen, boss_shots_peak])
	quit(0)
