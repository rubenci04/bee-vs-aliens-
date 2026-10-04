extends SceneTree
## DEV ONLY. Render performance of THREAT, CAMERA & BOSS REBUILD 03 by scenario, for camera preset D or E. Run WITHOUT
## --headless:  godot --path . --resolution 1152x648 --script res://dev/threat_camera_boss_v03_review/bench_scenes.gd -- preset=E
## First-appearance spike (first 30 frames) reported apart from the sustained numbers. Nothing in the game changes.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("preset="):
			BeeLevel01Framing.use_preset(StringName(arg.substr(7)))
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
	bee.hurtbox.monitorable = false
	wave.set_physics_process(false)
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x + BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.view_aspect(root)), 3.6, 0)

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
	var elapsed := 0.0
	while elapsed < seconds * 1000.0:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		elapsed += ms
		frames += 1
		bee.global_position.y = 3.6 + sin(elapsed / 1000.0 * 2.0) * 0.9
		if frames <= 30:
			spike = maxf(spike, ms)
			continue
		total += ms
		count += 1
		worst = maxf(worst, ms)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
	print("BENCH[%s] %-16s first_spike=%6.1fms sustained_avg=%5.2fms fps=%4.0f worst=%5.1fms render_cpu=%4.2fms" % [BeeLevel01Framing.preset_name, label, spike, total / maxf(count, 1), 1000.0 * count / maxf(total, 0.001), worst, cpu / maxf(count, 1)])

func spawn(family: String, slot := 0, extra := {}) -> Node3D:
	var request := {"family": family, "slot": slot, "event": 0, "hard": false}
	request.merge(extra, true)
	wave._spawn(request)
	return wave.active_units.back()

func run() -> void:
	root.size = Vector2i(1152, 648)
	await setup(30.0)
	await sample("garden_idle", 5.0)
	await setup(296.0)
	spawn("Walker", 0)
	spawn("EyeDrone", 1, {"y": 5.8})
	spawn("Wasp", 2, {"y": 3.0, "sting_shots": 2, "overload_enabled": true})
	spawn("Probe", 3, {"y": 4.6})
	await sample("four_threats", 8.0)
	await setup(188.0)
	stage.scroll_speed = 2.0
	stage.set_physics_process(true)
	wave.director_moment.emit(&"scale_event")
	await sample("frog", 6.0)
	await setup(340.0)
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	wave.set_physics_process(true)
	for i in 600:
		await physics_frame
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			break
	wave.boss.health.take_damage(wave.boss.health.current_health - int(wave.boss.max_hp * 0.6))
	await sample("boss_phase2", 10.0)
	quit(0)
