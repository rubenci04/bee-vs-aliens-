extends SceneTree
## DEV ONLY. Render performance of the Level 01 Transformation Pass by scenario. Run WITHOUT --headless:
##   godot --path . --resolution 1152x648 --script res://dev/level01_transformation_review/bench_scenes.gd
## Each scenario reports the first-appearance spike (first 30 frames: shader/pipeline compile) separately from the
## sustained numbers (the rest). Nothing in the game changes.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer

func _initialize() -> void:
	call_deferred("run")

func setup(distance: float) -> void:
	if stage != null:
		stage.queue_free()
		for i in 2:
			await process_frame
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4:
		await process_frame
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	wave.set_physics_process(false)
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 3.2, 3.6, 0)

func sample(label: String, seconds: float) -> void:
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var last := Time.get_ticks_usec()
	var frames := 0
	var spike := 0.0
	var total := 0.0
	var count := 0
	var worst := 0.0
	var cpu := 0.0
	var nodes := 0
	var elapsed := 0.0
	while elapsed < seconds * 1000.0:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		elapsed += ms
		frames += 1
		if frames <= 30:
			spike = maxf(spike, ms)
			continue
		total += ms
		count += 1
		worst = maxf(worst, ms)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		nodes = maxi(nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("BENCH %-14s first_spike=%6.1fms sustained_avg=%5.2fms fps=%4.0f worst=%5.1fms render_cpu=%4.2fms nodes=%d" % [label, spike, total / maxf(count, 1), 1000.0 * count / maxf(total, 0.001), worst, cpu / maxf(count, 1), nodes])

func spawn(family: String, slot := 0) -> Node3D:
	wave._spawn({"family": family, "slot": slot, "event": 0, "hard": false})
	return wave.active_units.back()

func run() -> void:
	root.size = Vector2i(1152, 648)
	await setup(100.0)
	await sample("garden_idle", 4.0)
	await setup(316.0)
	for family in ["Probe", "EyeDrone", "Turret"]:
		spawn(family, wave.active_units.size())
	await sample("dense_sunset", 8.0)
	await setup(120.0)
	spawn("Dragonfly")
	await sample("dragonfly", 8.0)
	await setup(140.0)
	(stage.get_node("GiantHuman") as GiantHumanCrossingHazard).begin_crossing(stage.camera)
	await sample("giant_human", 8.0)
	await setup(262.0)
	wave.director_moment.emit(&"contaminated_garden")
	spawn("Dragonfly")
	spawn("Probe", 1)
	await sample("contamination", 8.0)
	await setup(340.0)
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	wave.set_physics_process(true)
	await sample("last_silence", 4.0)
	for i in 600:
		await physics_frame
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			break
	wave.boss.health.take_damage(wave.boss.health.current_health - int(wave.boss.max_hp * 0.3))
	await sample("ufo_phase3", 10.0)
	quit(0)
