extends SceneTree

# LOTE 11 · ETAPA B — density: +35-40 % units over the 107 of Lote 10 (popcorn formations only, same families), caps
# 7 on the route / 10 in a combat zone, formations (V, sine wave, pincer, from behind) and kamikaze popcorn with a 0.5 s
# warning. Structure only; the pacing bot measures time, gaps and damage (validate_bee_pacing_v01).

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const BASE_UNITS := 107
const MIN_GAIN := 0.35
const MAX_GAIN := 0.40
const MIN_TELEGRAPH := 0.4

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer

func _initialize() -> void:
	BeeLevel01Controller.roster_only = false # LOTE 12: this test covers the pre-roster flow (alien enemies, frog, UFO), which stays intact behind LEVEL01_ROSTER_ONLY.
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func run() -> void:
	test_table()
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	for i in 5:
		await physics_frame
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	await test_kamikaze()
	await test_from_behind()
	print("BEE_LOTE11_DENSITY_V01_OK")
	quit(0)

func test_table() -> void:
	var total := 0
	var formations := {}
	for event: Dictionary in BeeLevel01Controller.EVENTS_LEGACY:
		total += (event["units"] as Array).size()
		for zone_wave: Dictionary in event.get("arena", []):
			total += (zone_wave["units"] as Array).size()
		if event.has("formation"):
			formations[str(event["formation"])] = true
		var sides: Array = event.get("sides", [])
		check(sides.is_empty() or sides.size() == (event["units"] as Array).size(), "sides size mismatch: %s" % event["label"])
		for side in sides:
			check(str(side) in ["left", "right"], "Unknown side %s" % side)
		if event.has("path"):
			check(str(event["path"]) in BeeLevel01Controller.SWARM_PATHS, "Unknown popcorn path %s" % event["path"])
	var gain := float(total) / float(BASE_UNITS) - 1.0
	check(gain >= MIN_GAIN and gain <= MAX_GAIN, "Unit gain %.1f %% outside %d-%d %% (%d units)" % [gain * 100.0, int(MIN_GAIN * 100.0), int(MAX_GAIN * 100.0), total])
	for name in ["v", "snake", "pincer", "from_behind", "kamikaze"]:
		check(formations.has(name), "Missing formation " + name)
	check(BeeLevel01Controller.MAX_ON_SCREEN == 7 and BeeLevel01Controller.MAX_ON_SCREEN_ARENA == 10, "Caps must be 7 route / 10 zone")
	check(BeeLevel01Controller.threat_cap(300.0) == BeeLevel01Controller.MAX_ROUTE_THREATS, "Threat cap changed")
	check(PopcornDrone.KAMIKAZE_WARNING >= MIN_TELEGRAPH and is_equal_approx(PopcornDrone.KAMIKAZE_WARNING, 0.5), "Kamikaze warning must be 0.5 s (>= 0.4)")
	for family in BeeLevel01Controller.LEVEL_HP:
		check(family != "Firefly", "No fireflies in Level 01")
	print("LOTE11_DENSITY table units=%d gain=%.1f%% formations=%s" % [total, gain * 100.0, str(formations.keys())])

func spawn_swarm(path: String, y: float, side := "right") -> PopcornDrone:
	wave._spawn({"family": "Swarm", "slot": 0, "event": 0, "hard": false, "y": y, "path": path, "shooter": false, "side": side})
	return wave.swarm_units.back() as PopcornDrone

func test_kamikaze() -> void:
	stage.distance = 100.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 4.0, 3.0, 0.0)
	var drone := spawn_swarm("kamikaze", 5.0)
	check(drone != null and drone.path == PopcornDrone.PathKind.KAMIKAZE, "Kamikaze path not applied")
	var locked := Vector2.ZERO
	var warn_frames := 0
	var warn_x := 0.0
	var moved_in_warning := 0.0
	var dash_started := false
	for i in 60 * 8:
		await physics_frame
		var state: int = drone.get("_kz_state")
		if state == 1:
			if warn_frames == 0:
				locked = drone.get("_kz_vel")
				warn_x = drone.global_position.x
			warn_frames += 1
			moved_in_warning = maxf(moved_in_warning, absf(drone.global_position.x - warn_x))
			bee.global_position = Vector3(bee.global_position.x, 6.5 if warn_frames < 15 else 0.8, 0.0) # Bee moves away: the dash must not follow.
		if state == 2 and not dash_started:
			dash_started = true
			check(Vector2(drone.get("_kz_vel")).is_equal_approx(locked), "The dash direction must stay locked from the start of the warning")
			check(is_equal_approx(Vector2(drone.get("_kz_vel")).length(), PopcornDrone.KAMIKAZE_SPEED), "Dash speed")
		if drone.escaped:
			break
	var warned := warn_frames / 60.0
	check(dash_started, "The kamikaze never dashed")
	check(warned >= MIN_TELEGRAPH and absf(warned - PopcornDrone.KAMIKAZE_WARNING) < 0.05, "Warning %.2f s (needs 0.5 s)" % warned)
	check(moved_in_warning < 0.2, "The kamikaze must hold still while it warns (%.2f m)" % moved_in_warning)
	check(drone.escaped, "A missed kamikaze must leave the screen")
	print("LOTE11_DENSITY kamikaze warning=%.2fs locked=%s dash=%.1fm/s escaped=OK" % [warned, str(locked), PopcornDrone.KAMIKAZE_SPEED])

func test_from_behind() -> void:
	wave.swarm_units.clear()
	var drone := spawn_swarm("straight", 3.0, "left")
	check(drone.from_left and not drone.shooter, "From-behind popcorn flag")
	var start_x := drone.global_position.x - stage.camera.global_position.x
	check(start_x < -5.0, "From-behind popcorn must be born past the LEFT edge (%.1f)" % start_x)
	drone.speed = 5.0
	var crossed := false
	for i in 60 * 10:
		await physics_frame
		if drone.global_position.x > stage.camera.global_position.x + 1.0:
			crossed = true
		if drone.escaped:
			break
	check(crossed and drone.escaped, "From-behind popcorn must cross the screen to the right and leave")
	var right := spawn_swarm("straight", 3.0, "right")
	check(right.global_position.x - stage.camera.global_position.x > 5.0 and not right.from_left, "Right-side popcorn unchanged")
	print("LOTE11_DENSITY from_behind crosses=OK escape=OK")
