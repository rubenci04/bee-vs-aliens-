extends SceneTree
## DEV ONLY. Passive-bot pacing simulation of the whole Level 01 timeline (no gameplay changes).
## Bee hangs 3 m behind the camera centre, follows the nearest enemy's height and shoots every
## FIRE_INTERVAL seconds (a ~70 % trigger-uptime player, no dodging, no pickups, huge HP so it never
## dies). It reports, per encounter and for the whole level:
##   spawn / clear time, time-to-kill, damage taken, simultaneous threats, long threat-free stretches.
## godot --headless --path . --script res://dev/arcade_pressure_review/sim_level.gd
## Optional user args:  -- fire=0.45 seed_label=before

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const FIRE_INTERVAL := 0.45
const BOT_OFFSET_X := -3.0

var stage: BeeShmupStage
var bee: BeePlayer
var wave: BeeLevel01Controller
var fire_interval := FIRE_INTERVAL
var label := "run"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("fire="):
			fire_interval = float(arg.substr(5))
		elif arg.begins_with("label="):
			label = arg.substr(6)
	call_deferred("run")

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await physics_frame
	await physics_frame
	bee = stage.bee
	wave = stage.wave as BeeLevel01Controller
	bee.set_physics_process(false)
	bee.health.max_health = 100000
	bee.health.current_health = 100000
	Engine.time_scale = 1.0 # Run with --fixed-fps 60: real-time sync off, normal 1/60 steps.
	var damage_by_event := {}
	var spawn_time := {}
	var clear_time := {}
	var alive_by_event := {}
	var units_by_event := {}
	var current_event := -1
	bee.health.health_changed.connect(func(_c: int, _m: int, change: int):
		if change < 0:
			damage_by_event[current_event] = int(damage_by_event.get(current_event, 0)) - change)
	var damage_by_family := {}
	var hits_by_family := {}
	var wired := {}
	var wire := func(box: DamageHitbox3D):
		if wired.has(box.get_instance_id()):
			return
		wired[box.get_instance_id()] = true
		box.hit_confirmed.connect(func(hurtbox: DamageHurtbox3D, applied: int):
			if hurtbox.owner_entity != bee:
				return
			var who := str(box.attacker.name).split("_")[0] if box.attacker != null else "?"
			damage_by_family[who] = int(damage_by_family.get(who, 0)) + applied
			hits_by_family[who] = int(hits_by_family.get(who, 0)) + 1)
	var t := 0.0
	var fire_left := 0.0
	var threat_free := 0.0
	var longest_free := 0.0
	var longest_free_at := 0.0
	var free_total := 0.0
	var max_units := 0
	var max_shots := 0
	var max_threat := 0
	var shot_sum := 0.0
	var shot_ids := {}
	var wasp_life := {}
	var stretches: Array[String] = []
	var frames_n := 0
	var ranged_time := 0.0
	var shot_hist := {}
	var human_seconds := 0.0
	var last_event_index := 0
	var dist_free_start := 0.0
	var longest_free_m := 0.0
	var started_boss := false
	var step := 1.0 / 60.0
	for i in 60 * 400:
		await physics_frame
		t += step
		var cam_x := stage.camera.global_position.x
		# Event bookkeeping: units carry their spawn event in the name "<Family>_<event>_<slot>".
		for unit in wave.active_units:
			var event := int(str(unit.name).split("_")[1])
			current_event = maxi(current_event, event)
			if not spawn_time.has(event):
				spawn_time[event] = t
			alive_by_event[event] = int(alive_by_event.get(event, 0))
		for unit in wave.active_units:
			for box in unit.find_children("*", "DamageHitbox3D", true, false):
				wire.call(box)
		for shot in get_nodes_in_group("alien_projectiles"):
			for box in shot.find_children("*", "DamageHitbox3D", true, false):
				wire.call(box)
		if wave.human.hitbox != null:
			wire.call(wave.human.hitbox)
		var counts := {}
		for unit in wave.active_units:
			var event := int(str(unit.name).split("_")[1])
			counts[event] = int(counts.get(event, 0)) + 1
			units_by_event[event] = maxi(int(units_by_event.get(event, 0)), int(counts[event]))
		for event in spawn_time:
			if not clear_time.has(event) and not counts.has(event) and wave._pending.is_empty():
				clear_time[event] = t
		max_units = maxi(max_units, wave.active_units.size())
		var shots := get_nodes_in_group("alien_projectiles").size()
		max_shots = maxi(max_shots, shots)
		shot_sum += shots
		for shot in get_nodes_in_group("alien_projectiles"):
			shot_ids[shot.get_instance_id()] = true
		for unit in wave.active_units:
			if str(unit.name).begins_with("Wasp"):
				var wid := unit.get_instance_id()
				if not wasp_life.has(wid):
					wasp_life[wid] = [t, t]
				wasp_life[wid][1] = t
		frames_n += 1
		shot_hist[shots] = int(shot_hist.get(shots, 0)) + 1
		var ranged_here := false
		for unit in wave.active_units:
			var fam := str(unit.name).split("_")[0]
			if fam in ["Probe", "EyeDrone", "Turret", "Walker"] and unit.global_position.x < cam_x + 6.0:
				ranged_here = true
		if ranged_here:
			ranged_time += step
		var threats := wave.active_units.size() + shots
		max_threat = maxi(max_threat, threats)
		if wave._waiting_for_human:
			human_seconds += step
		# Threat-free stretch: no unit, no hostile projectile, no human on screen.
		if threats == 0 and not wave._waiting_for_human and wave.human.current_phase != GiantHumanCrossingHazard.Phase.CROSSING:
			if threat_free == 0.0:
				dist_free_start = stage.distance
			threat_free += step
			free_total += step
			if threat_free > longest_free:
				longest_free = threat_free
				longest_free_at = stage.distance
				longest_free_m = stage.distance - dist_free_start
		else:
			if threat_free >= 2.5:
				stretches.append("%.0fm:%.1fs" % [dist_free_start, threat_free])
			threat_free = 0.0
		# Bot.
		var target: Node3D
		var best := INF
		for unit in wave.active_units:
			if not is_instance_valid(unit):
				continue
			var d := absf(unit.global_position.x - (cam_x + BOT_OFFSET_X))
			if d < best:
				best = d
				target = unit
		var want_y := 4.0 if target == null else clampf(target.global_position.y, 0.9, 6.4)
		bee.global_position = Vector3(cam_x + BOT_OFFSET_X, want_y, 0.0)
		fire_left -= step
		if fire_left <= 0.0 and target != null and target.global_position.x < cam_x + 8.5:
			bee.fire()
			fire_left = fire_interval
		if wave.boss != null and wave.boss.is_active() and not started_boss:
			started_boss = true
			break
		if last_event_index != wave.event_index:
			last_event_index = wave.event_index
	Engine.time_scale = 1.0
	var events := wave.EVENTS
	print("SIM_%s fire_interval=%.2f" % [label, fire_interval])
	var total_units := 0
	for e in events.size():
		var units: Array = events[e]["units"]
		total_units += units.size()
		var ttk := float(clear_time.get(e, -1.0)) - float(spawn_time.get(e, 0.0)) if clear_time.has(e) else -1.0
		print("EVENT %02d at=%3d %-34s units=%d spawn=%6.1fs ttk=%5.1fs damage_taken=%d" % [e, int(events[e]["at"]), str(events[e]["label"]), units.size(), float(spawn_time.get(e, -1.0)), ttk, int(damage_by_event.get(e, 0))])
	print("SIM_TOTAL enemies=%d events=%d time_to_boss=%.1fs human_wait=%.1fs max_active_units=%d max_enemy_shots=%d max_threats=%d" % [total_units, events.size(), t, human_seconds, max_units, max_shots, max_threat])
	print("SIM_FREE threat_free_total=%.1fs longest=%.1fs (%.1f m of scroll) at_distance=%.0f" % [free_total, longest_free, longest_free_m, longest_free_at])
	print("SIM_FAMILY_DAMAGE ", damage_by_family, " hits=", hits_by_family)
	var wasp_sum := 0.0
	for life in wasp_life.values():
		wasp_sum += float(life[1]) - float(life[0])
	print("SIM_EXTRA wasps=%d wasp_presence_avg=%.1fs shots_total=%d shots_per_encounter=%.1f" % [wasp_life.size(), wasp_sum / maxf(wasp_life.size(), 1), shot_ids.size(), float(shot_ids.size()) / 23.0])
	print("SIM_FIRE avg_enemy_shots=%.2f peak=%d ranged_threat_on_screen=%.1fs (%.0f%%) hist=%s" % [shot_sum / maxf(frames_n, 1), max_shots, ranged_time, 100.0 * ranged_time / maxf(t, 1.0), str(shot_hist)])
	print("SIM_STRETCHES >=2.5s: ", ", ".join(stretches))
	print("SIM_DAMAGE total=%d" % damage_by_event.values().reduce(func(a, b): return a + b, 0))
	quit(0)
