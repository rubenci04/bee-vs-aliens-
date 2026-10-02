extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage = load("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.distance = 340
	stage._update_camera_and_bounds()
	stage.bee.hurtbox.monitorable = false
	stage.bee.global_position = Vector3(337, 5, 0)
	# Deliberate stress sample, not a progression/activation validation.
	for i in 3:
		stage.wave._spawn({"family": ["Walker", "Probe", "Turret"][i], "event": 23, "slot": i, "hard": true})
	var warmup := Time.get_ticks_msec()
	while Time.get_ticks_msec() - warmup < 1500:
		await process_frame
	var start := Time.get_ticks_usec()
	var last := start
	var count := 0
	var worst_ms := 0.0
	var min_fps := INF
	var peak_nodes := 0
	while Time.get_ticks_usec() - start < 5000000:
		await process_frame
		var now := Time.get_ticks_usec()
		worst_ms = maxf(worst_ms, float(now - last) / 1000.0)
		last = now
		count += 1
		min_fps = minf(min_fps, float(Engine.get_frames_per_second()))
		peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("RENDER_FPS_SAMPLE normal_speed=1 threats=3 seconds=5 mean_fps=", float(count) * 1000000.0 / float(last - start), " min_engine_fps=", min_fps, " worst_frame_ms=", worst_ms, " peak_nodes=", peak_nodes)
	quit(0)
