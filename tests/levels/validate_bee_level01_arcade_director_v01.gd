extends SceneTree

# LEVEL 01 TRANSFORMATION PASS 01 — PHASE A: ARCADE DIRECTOR (structure, not fun).
#   order       thresholds ascending, five internal acts in order, checkpoint/human/gates where the blueprint puts them
#   cadence     no metronome: varied spacing, no long runs of identical spacing, max 16 m between events
#   formations  several readable shapes, per-unit data consistent (delays ascending, y/x arrays sized)
#   fans        EyeDrone fans only from FAN_FROM_X; earlier Eyes fire aimed bursts only
#   moments     enemy-free director moments are emitted in order exactly once
#   run         whole level with a fast harness: threat cap, projectile ceiling, no off-screen fire, Bomb reward moved,
#               checkpoint resume, UFO and Level Complete
# Dev filter: -- only=static|fans|run|checkpoint

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const FORMATIONS := ["pair", "escort", "staggered", "horizontal", "vertical", "top_bottom", "diagonal", "rock_turret", "wave", "v"]

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var only := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			only = arg.substr(5)
	call_deferred("run")

func wants(section: String) -> bool:
	return only.is_empty() or only == section

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func bind(value: Node) -> void:
	stage = value as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func reloaded(old: Node) -> void:
	for i in 120:
		await process_frame
		if current_scene != null and current_scene != old and current_scene.is_node_ready():
			break
	await frames(3)

# --- static structure ---------------------------------------------------------------------------------

func test_static() -> void:
	var events := BeeLevel01Controller.EVENTS
	var acts := BeeLevel01Controller.ACT_STARTS
	check(acts.size() == 5 and acts[0] == 0.0, "Five acts expected")
	var previous_at := -1.0
	var previous_act := 1
	var spacings: Array[float] = []
	var formations := {}
	var moments: Array[String] = []
	var total := 0
	var human_at := -1.0
	var hard: Array[float] = []
	var by_act := {1: 0, 2: 0, 3: 0, 4: 0}
	for event: Dictionary in events:
		var at := float(event["at"])
		var act := int(event.get("act", 0))
		check(at > previous_at, "Thresholds must ascend: " + str(event["label"]))
		check(act >= previous_act and act >= 1 and act <= 4, "Acts must be in order: " + str(event["label"]))
		check(at >= float(acts[act - 1]) and (act == 4 or at < float(acts[act])), "Event outside its act: %s (act %d at %.0f)" % [event["label"], act, at])
		if previous_at >= 0.0:
			spacings.append(at - previous_at)
		previous_at = at
		previous_act = act
		var units: Array = event["units"]
		total += units.size()
		by_act[act] += units.size()
		for key in ["delays", "y", "x"]:
			var values: Array = event.get(key, [])
			check(values.is_empty() or values.size() == units.size(), "%s size mismatch: %s" % [key, event["label"]])
		var delays: Array = event.get("delays", [])
		for i in range(1, delays.size()):
			check(float(delays[i]) >= float(delays[i - 1]), "Delays must ascend: " + str(event["label"]))
		if event.has("formation"):
			check(str(event["formation"]) in FORMATIONS, "Unknown formation " + str(event["formation"]))
			formations[str(event["formation"])] = true
		if event.has("moment"):
			moments.append(str(event["moment"]))
		if bool(event.get("human", false)):
			human_at = at
		if bool(event.get("hard", false)):
			hard.append(at)
	check(human_at == 140.0, "The Giant Human stays at X=140")
	check(hard == [254.0, 296.0, 340.0], "Hard gates moved: " + str(hard))
	check(float(events.back()["at"]) == 340.0, "The last defence stays at X=340 (UFO after it)")
	check(total >= 60 and total <= 72, "Enemy budget %d outside 60-72" % total)
	check(formations.size() >= 7, "Too few formation shapes: " + str(formations.keys()))
	check(moments == ["opening_can", "human_aftermath", "contaminated_garden", "bomb_reward"], "Director moments wrong: " + str(moments))
	# No metronome: varied spacing, short events, never more than 16 m without something happening.
	var distinct := {}
	var run := 1
	var longest_run := 1
	for i in spacings.size():
		distinct[snappedf(spacings[i], 0.5)] = true
		if i > 0 and is_equal_approx(spacings[i], spacings[i - 1]):
			run += 1
			longest_run = maxi(longest_run, run)
		else:
			run = 1
	check(distinct.size() >= 6, "Cadence still too regular: %d distinct spacings" % distinct.size())
	check(longest_run <= 3, "More than three identical spacings in a row (metronome)")
	check(spacings.max() <= 16.0 and spacings.min() >= 4.0, "Spacing outside 4-16 m")
	# Intensity grows by act (units per metre) without making act 1 a wall.
	check(float(by_act[1]) / 68.0 < float(by_act[4]) / 142.0, "Act 4 must be denser than act 1")
	print("DIRECTOR_STATIC events=%d enemies=%d formations=%s moments=%d spacing=%.0f..%.0f m distinct=%d acts=%s" % [events.size(), total, str(formations.keys()), moments.size(), spacings.min(), spacings.max(), distinct.size(), str(by_act)])

# --- fan introduction -------------------------------------------------------------------------------------

func test_fans() -> void:
	stage.scroll_speed = 0.0
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	for entry in [[80.0, false], [100.0, true]]:
		stage.distance = float(entry[0])
		stage._update_camera_and_bounds()
		bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 3.5, 0)
		wave._spawn({"family": "EyeDrone", "slot": 0, "event": 0, "hard": false})
		var eye := wave.active_units.back() as EyeDroneEnemy
		check((eye.fan_every > 0) == bool(entry[1]), "EyeDrone fan gating wrong at X=%.0f (fan_every=%d)" % [entry[0], eye.fan_every])
		for i in 60 * 9:
			bee.global_position.y = 3.5 + sin(float(i) / 60.0 * 2.2) * 0.6
			await physics_frame
		if bool(entry[1]):
			check(eye.fan_shot_count >= 1, "No fan after X=%.0f" % entry[0])
		else:
			check(eye.fan_shot_count == 0 and eye.projectile_fire_count >= 3, "A fan appeared before FAN_FROM_X (X=%.0f)" % entry[0])
		wave.active_units.erase(eye)
		eye.queue_free()
		for shot in get_nodes_in_group("alien_projectiles"):
			shot.queue_free()
		await frames(2)
	print("DIRECTOR_FANS aimed_only_before=%.0f fans_after=OK" % BeeLevel01Controller.FAN_FROM_X)

# --- whole level ------------------------------------------------------------------------------------------

func test_run() -> void:
	var moments_seen: Array[String] = []
	wave.director_moment.connect(func(id: StringName): moments_seen.append(str(id)))
	var bomb := stage.get_node("Powerups/BombRecharge") as Node3D
	check(absf(bomb.global_position.x - 302.0) < 0.5, "Bomb reward should sit after the Walker gate (X=302)")
	bee.set_physics_process(false)
	bee.hurtbox.monitorable = false # Structure run, not survival.
	Engine.time_scale = 3.0
	var seen := {}
	var peak := 0
	var acts_seen := {}
	var offscreen_fire := 0
	for frame in 30000:
		await physics_frame
		bee.global_position.y = 7.0
		bee.global_position.x = stage.distance - 4.8
		acts_seen[wave.current_act] = true
		var cap := 3 if stage.distance >= BeeLevel01Controller.THREE_AT_ONCE_FROM else 2
		check(wave.active_units.size() <= cap, "Threat cap exceeded at X=%.0f" % stage.distance)
		var shots := get_nodes_in_group("alien_projectiles").size()
		peak = maxi(peak, shots)
		for unit in wave.active_units.duplicate():
			var id: int = unit.get_instance_id()
			if not seen.has(id):
				seen[id] = wave._clock
			var full: bool = wave.active_units.size() >= cap
			if (wave._pending.is_empty() or full) and wave._clock - float(seen[id]) > 2.0:
				unit.get_node("HealthComponent").take_damage(9999)
		if wave._waiting_for_human:
			bee.global_position = Vector3(stage.distance - 5.1, 7.0, 0)
		if wave.boss != null and wave.boss.is_active():
			wave.boss.health.take_damage(99999)
		if stage.sector_complete:
			break
	Engine.time_scale = 1.0
	check(stage.sector_complete and stage.status.text == "SECTOR DESPEJADO" and wave.boss_defeated, "Level Complete missing")
	check(wave.event_index == BeeLevel01Controller.EVENTS.size(), "Not every event ran")
	check(moments_seen == ["opening_can", "human_aftermath", "contaminated_garden", "bomb_reward", "last_silence"], "Moments emitted wrong: " + str(moments_seen))
	check(acts_seen.has(1) and acts_seen.has(2) and acts_seen.has(3) and acts_seen.has(4) and acts_seen.has(5), "Acts not all reached: " + str(acts_seen.keys()))
	check(peak <= 14, "Projectile ceiling exceeded during the level (%d)" % peak)
	var spawned := 0
	for family in wave.spawned_by_family:
		spawned += int(wave.spawned_by_family[family])
	var planned := 0
	for event: Dictionary in BeeLevel01Controller.EVENTS:
		planned += (event["units"] as Array).size()
	check(spawned == planned, "Spawned %d of %d planned units" % [spawned, planned])
	print("DIRECTOR_RUN complete=OK moments=%s acts=%s peak_shots=%d spawned=%d" % [str(moments_seen), str(acts_seen.keys()), peak, spawned])

func test_checkpoint() -> void:
	var expected := 0
	for event: Dictionary in BeeLevel01Controller.EVENTS:
		if float(event["at"]) < 190.0:
			expected += 1
	stage.distance = 190.05
	stage.checkpoint.activate_checkpoint()
	var old_stage := stage
	stage.checkpoint.restart_level(false)
	await reloaded(old_stage)
	bind(current_scene)
	check(wave.event_index == expected and wave.current_act == 3, "Checkpoint must resume at the first event after X=190 in act 3 (index %d, act %d)" % [wave.event_index, wave.current_act])
	check(wave.human.current_phase == GiantHumanCrossingHazard.Phase.EXITED, "Human repeated after the checkpoint")
	print("DIRECTOR_CHECKPOINT resume_index=%d act=3" % expected)

func run() -> void:
	create_timer(600.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	bind(current_scene)
	if wants("static"):
		test_static()
	if wants("fans"):
		await test_fans()
		if only.is_empty():
			var old := stage
			stage.checkpoint.restart_level(true)
			await reloaded(old)
			bind(current_scene)
	if wants("checkpoint"):
		await test_checkpoint()
		if only.is_empty():
			var old2 := stage
			stage.checkpoint.restart_level(true)
			await reloaded(old2)
			bind(current_scene)
	if wants("run"):
		await test_run()
	print("BEE_LEVEL01_ARCADE_DIRECTOR_V01_OK")
	quit(0)
