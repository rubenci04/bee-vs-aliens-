extends SceneTree
## DEV ONLY (GARDEN IDENTITY & AUDIO PASS 04). Render performance by scenario (camera E), run WITHOUT --headless:
##   godot --path . --resolution 1152x648 --script res://dev/garden_identity_04_review/bench_garden04.gd -- label=after
## Scenarios: opening, dense garden (leaf tunnel / watering can), human crossing, spider (when the family exists),
## post-checkpoint colour, boss phase 2. The first 30 frames (shader compilation) are reported apart. Also prints
## draw calls / objects in frame (RenderingServer monitors) to see what the new props cost.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var label := "after"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("label="):
			label = arg.substr(6)
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


func sample(name: String, seconds: float) -> void:
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var last := Time.get_ticks_usec()
	var frames := 0
	var spike := 0.0
	var total := 0.0
	var count := 0
	var worst := 0.0
	var cpu := 0.0
	var draws := 0.0
	var objects := 0.0
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
		draws += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		objects += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	print("BENCH[%s] %-15s first_spike=%6.1fms avg=%5.2fms fps=%4.0f worst=%5.1fms render_cpu=%4.2fms draws=%4d objects=%4d nodes=%d" % [label, name, spike,
			total / maxf(count, 1), 1000.0 * count / maxf(total, 0.001), worst, cpu / maxf(count, 1), int(draws / maxf(count, 1)), int(objects / maxf(count, 1)), get_node_count()])


func spawn(family: String, slot := 0, extra := {}) -> Node3D:
	var request := {"family": family, "slot": slot, "event": 0, "hard": false}
	request.merge(extra, true)
	wave._spawn(request)
	return wave.active_units.back()


func run() -> void:
	root.size = Vector2i(1152, 648)
	await setup(4.0)
	await sample("opening", 5.0)
	await setup(104.0)
	await sample("dense_garden", 5.0)
	await setup(126.0)
	await sample("watering_can", 4.0)
	await setup(140.0)
	wave.set_physics_process(true)
	while wave.event_index < BeeLevel01Controller.EVENTS.size() and not bool(BeeLevel01Controller.EVENTS[wave.event_index].get("human", false)):
		wave.event_index += 1
	await sample("human", 8.0)
	if ResourceLoader.exists("res://scenes/levels/controlled_spider.tscn"):
		await setup(92.0)
		spawn("Spider", 0, {"x": 1.0})
		spawn("EyeDrone", 1, {"y": 5.6})
		await sample("spider", 7.0)
	await setup(214.0)
	await sample("post_checkpoint", 5.0)
	await setup(340.0)
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	wave.set_physics_process(true)
	for i in 600:
		await physics_frame
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			break
	wave.boss.health.take_damage(wave.boss.health.current_health - int(wave.boss.max_hp * 0.6))
	await sample("boss_phase2", 8.0)
	quit(0)
