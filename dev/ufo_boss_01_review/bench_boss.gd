extends SceneTree
## DEV ONLY. Render performance during the UFO fight (phase 3, the busiest), vs the same arena
## without the boss. Run WITHOUT --headless:
##   godot --path . --resolution 1152x648 --script res://dev/ufo_boss_01_review/bench_boss.gd
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func _initialize() -> void:
	call_deferred("run")

func sample(label: String, seconds: float, peak_group: StringName) -> void:
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var worst := 0.0
	var total := 0.0
	var count := 0
	var peak := 0
	var nodes := 0
	var last := Time.get_ticks_usec()
	var cpu := 0.0
	var gpu := 0.0
	while total < seconds * 1000.0:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		worst = maxf(worst, ms)
		total += ms
		count += 1
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		peak = maxi(peak, get_nodes_in_group(peak_group).size())
		nodes = maxi(nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("BENCH %s avg_frame_ms=%.2f fps=%.0f worst_ms=%.1f render_cpu_ms=%.2f render_gpu_ms=%.2f peak_projectiles=%d nodes=%d" % [label, total / count, 1000.0 * count / total, worst, cpu / count, gpu / count, peak, nodes])

func run() -> void:
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await process_frame
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	var wave := stage.wave as BeeLevel01Controller
	stage.distance = 352.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.distance - 4.0, 2.4, 0)
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	for i in 60:
		await process_frame
	await sample("arena_without_boss", 5.0, UfoBoss01.PROJECTILE_GROUP)
	stage.set_physics_process(true)
	wave.set_physics_process(true)
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	for i in 900:
		await physics_frame
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			break
	var boss := wave.boss
	boss.health.take_damage(boss.health.current_health - int(boss.max_hp * 0.3))
	for i in 120:
		await physics_frame
	await sample("boss_phase3", 20.0, UfoBoss01.PROJECTILE_GROUP)
	quit(0)
