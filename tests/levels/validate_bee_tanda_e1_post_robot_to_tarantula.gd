extends SceneTree
## Tanda E1 — real level: the robot falls, the post-robot supplies appear and are collected, the camera scrolls on, Bee
## advances to the tarantula, its four phases play out until it is freed. Counts engine errors (Logger): must be 0.
## It also checks the cosmetic metal drill stinger stays visible and that no old stinger hitbox exists.
class ErrorCounter extends Logger:
	var count := 0
	var samples: Array[String] = []
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _backtraces: Array) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING:
			return
		count += 1
		if samples.size() < 5: samples.append("%s:%d %s %s" % [file, line, code, rationale])

var failures := 0
var errors := ErrorCounter.new()

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func gate_event() -> Dictionary:
	for event: Dictionary in BeeLevel01Controller.EVENTS_ROSTER:
		if bool(event.get("miniboss", false)):
			return event
	return {}

func stinger_ok(bee: BeePlayer) -> bool:
	var stinger := bee.get_node("VisualRoot/BeeVisual").model.find_child("Stinger", true, false) as Node3D
	return stinger != null and stinger.is_visible_in_tree() and stinger.find_children("*", "Area3D", true, false).is_empty()

func run() -> void:
	create_timer(1500.0, true, false, true).timeout.connect(func(): quit(1))
	OS.add_logger(errors)
	Engine.max_physics_steps_per_frame = 16
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 6: await physics_frame
	var wave := stage.wave as BeeLevel01Controller
	var bee := stage.bee
	check(stinger_ok(bee), "Metal drill stinger visible at the start")
	stage.set_physics_process(true)
	stage.scroll_speed = 0.0
	stage.distance = 294
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 3.0, 0)
	bee.health.damage_blocked = true
	var gate := gate_event()
	wave._spawn({"family": "Walker", "slot": 0, "event": 0, "hard": true, "miniboss": true, "escort_wave": gate["escort_wave"]})
	var robot := wave.miniboss
	check(robot != null, "Robot spawned")
	wave.event_index = BeeLevel01Controller.EVENTS_ROSTER.size() # The gate is the last event: after the robot nothing else is scheduled.
	# Late escorts and a unit mid-teleport that dies during the sequence must not break anything.
	for i in 120: await physics_frame
	robot.health.take_damage(99999)
	for i in 60 * 40:
		await physics_frame
		if wave._tarantula_breather_left >= 0.0: break
	check(wave._tarantula_breather_left >= 0.0, "Breather starts after the robot falls")
	await physics_frame
	# Supplies: bomb + spread medallions and the healing item exist, then Bee collects them.
	var pickups: Array[Node3D] = []
	for node in stage.get_children():
		if node is BeePowerupPickup: pickups.append(node)
	check(pickups.size() >= 2, "Post-robot bomb and Spread medallions appear (%d)" % pickups.size())
	bee.bomb_charges = 0
	for i in 60 * 8:
		if stage.camera.global_position.x >= wave._post_robot_target_x - 0.1: break
		await physics_frame # Tanda E: the medallions wait where the advance ends, in view; Bee reaches them with the scroll
	for p in pickups:
		if is_instance_valid(p):
			bee.global_position = p.global_position
			for i in 10: await physics_frame
	check(bee.bomb_charges >= 1, "Bomb medallion collected (%d)" % bee.bomb_charges)
	check(bee.spread_ammo > 0.0, "Spread medallion collected")
	# Camera scrolls on, Bee advances right towards the tarantula.
	var cam_start := stage.camera.global_position.x
	var boss: TarantulaBoss01
	for i in 60 * 60:
		await physics_frame
		bee.global_position.x = minf(stage.camera.global_position.x + 1.0, bee.global_position.x + 0.05)
		bee.global_position.y = clampf(bee.global_position.y, 1.5, 5.0)
		boss = wave.tarantula
		if boss != null and boss.state == TarantulaBoss01.State.PHASE_1: break
	check(stage.camera.global_position.x >= wave._post_robot_target_x - 0.1, "The camera scrolled on after the robot")
	check(boss != null and boss.state == TarantulaBoss01.State.PHASE_1, "The tarantula walks in and starts phase 1")
	if boss == null:
		finish(stage)
		return
	# Four phases: push its life across each ratio and let the transitions play.
	for target in [TarantulaBoss01.State.PHASE_2, TarantulaBoss01.State.PHASE_3, TarantulaBoss01.State.PHASE_4]:
		var ratio: float = {TarantulaBoss01.State.PHASE_2: 0.74, TarantulaBoss01.State.PHASE_3: 0.48, TarantulaBoss01.State.PHASE_4: 0.18}[target]
		boss.health.current_health = int(boss.max_hp * ratio) + 1
		boss.health.take_damage(1)
		for i in 60 * 25:
			await physics_frame
			bee.health.restore_health(1000)
			bee.global_position.x = clampf(bee.global_position.x, stage.camera.global_position.x - 6.0, stage.camera.global_position.x + 6.0)
			if boss.state == target: break
		check(boss.state == target, "Phase %d reached (state %d)" % [target, boss.state])
		for i in 60 * 6: await physics_frame # let attacks, spiders, nets and rain spawn
	check(boss.phases_seen.size() >= 4, "All four phases were seen (%d)" % boss.phases_seen.size())
	check(stinger_ok(bee), "Metal drill stinger still visible mid-fight")
	boss.health.take_damage(99999)
	for i in 60 * 20:
		await physics_frame
		if stage.sector_complete: break
	check(wave.tarantula_freed, "The tarantula was freed")
	check(stage.sector_complete and stage.has_node("ResultsScreen"), "Level completes with the results screen")
	finish(stage)

func finish(stage: Node) -> void:
	check(errors.count == 0, "0 engine/script errors (found %d: %s)" % [errors.count, str(errors.samples)])
	Engine.time_scale = 1.0
	print("BEE_TANDA_E1_POST_ROBOT_OK" if failures == 0 else "BEE_TANDA_E1_FAILED %d" % failures)
	quit(0 if failures == 0 else 1)
