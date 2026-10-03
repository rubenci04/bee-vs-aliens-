extends SceneTree
## DEV ONLY. Render performance of the busiest stretch of Level 01 (distance 290 -> boss), grouped by
## how many enemies are alive. Passive invulnerable bot (see sim_level.gd). Run WITHOUT --headless:
##   godot --path . --resolution 1152x648 --script res://dev/level01_challenge_review/bench_density.gd
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(func(): quit(1))
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await process_frame
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	var wave := stage.wave as BeeLevel01Controller
	stage.distance = 290.0
	stage._update_camera_and_bounds()
	wave.resume_after_checkpoint(290.0)
	for i in 30:
		await process_frame
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var groups := {}
	var last := Time.get_ticks_usec()
	var fire_left := 0.0
	var all_ms := 0.0
	var all_count := 0
	var all_worst := 0.0
	for i in 60 * 120:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		var key := "units_%d" % wave.active_units.size()
		var entry: Dictionary = groups.get(key, {"n": 0, "ms": 0.0, "worst": 0.0, "cpu": 0.0, "gpu": 0.0, "nodes": 0, "shots": 0})
		entry["n"] += 1
		entry["ms"] += ms
		entry["worst"] = maxf(entry["worst"], ms)
		entry["cpu"] += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		entry["gpu"] += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		entry["nodes"] = maxi(entry["nodes"], int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		entry["shots"] = maxi(entry["shots"], get_nodes_in_group("alien_projectiles").size())
		groups[key] = entry
		if ms > 40.0:
			var names := []
			for unit in wave.active_units:
				names.append(str(unit.name))
			print("HITCH %.0f ms at distance %.1f units=%s frame=%d" % [ms, stage.distance, names, i])
		all_ms += ms
		all_count += 1
		all_worst = maxf(all_worst, ms)
		# Bot.
		var cam_x := stage.camera.global_position.x
		var target: Node3D
		for unit in wave.active_units:
			if target == null or absf(unit.global_position.x - (cam_x - 3.0)) < absf(target.global_position.x - (cam_x - 3.0)):
				target = unit
		bee.global_position = Vector3(cam_x - 3.0, 4.0 if target == null else clampf(target.global_position.y, 0.9, 6.4), 0)
		fire_left -= ms / 1000.0
		if fire_left <= 0.0 and target != null and target.global_position.x < cam_x + 8.5:
			bee.fire()
			fire_left = 0.45
		if wave.boss != null and wave.boss.is_active():
			break
	for key in groups:
		var e: Dictionary = groups[key]
		print("BENCH %s frames=%d avg_ms=%.2f fps=%.0f worst_ms=%.1f render_cpu_ms=%.2f render_gpu_ms=%.2f peak_nodes=%d peak_enemy_shots=%d" % [key, e["n"], e["ms"] / e["n"], 1000.0 * e["n"] / e["ms"], e["worst"], e["cpu"] / e["n"], e["gpu"] / e["n"], e["nodes"], e["shots"]])
	print("BENCH ALL frames=%d avg_ms=%.2f fps=%.0f worst_ms=%.1f" % [all_count, all_ms / all_count, 1000.0 * all_count / all_ms, all_worst])
	quit(0)
