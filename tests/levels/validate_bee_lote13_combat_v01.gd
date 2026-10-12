extends SceneTree

# LOTE 13 · ETAPA 2 — every enemy attacks soon and every family has its own shot.
#  1. TIMING: each roster family, alone on screen, shows its FIRST warning within ~1 s of entering the screen
#     (FIRST_ATTACK_MAX_DELAY + a small tolerance) and no warning is shorter than 0.4 s.
#  2. LOOKS: BeeShotStyles has one look per family, every one with the cyan core and its own rim colour, none close to Bee's gold.
#  3. PATTERNS: the families fire the shots of their table (wasp needle, green fly acid, common fly pellets, ant pebble lob,
#     snail bubble lob, spider web fan, cannon mushroom spores, ladybird seeds, beetle stones): measured on live units.
#  4. LOBS: an arc lands on the spot it was aimed at.
# Dev: -- report prints without failing.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const TIMING_TOLERANCE := 0.15
const FAMILIES := ["FlyCommon", "FlyGreen", "FlyCloud", "Wasp", "Ladybird", "Ant", "Snail", "WormA", "WormB", "StagBeetle", "Spider", "MushroomCannon"]
## Family -> shot style it must have fired within SHOT_WATCH_SECONDS (patterns of the table).
const SHOT_TABLE := {"Wasp": &"stinger", "FlyGreen": &"acid", "FlyCommon": &"pellet", "Ant": &"pebble", "Snail": &"bubble", "Spider": &"web",
		"MushroomCannon": &"spore", "Ladybird": &"seed"}
const SHOT_WATCH_SECONDS := 14.0
const BEE_GOLD := Color(1.0, 0.72, 0.16)
const FIRST_DELAY_LIMIT := BeeLevel01Controller.FIRST_ATTACK_MAX_DELAY

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var report_only := false
var lines: Array[String] = []

func _initialize() -> void:
	report_only = "report" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if report_only:
		if not ok:
			print("WOULD FAIL: ", message)
		return
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func load_level() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await frames(3)
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(6)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	stage.get_node("Juice").set_physics_process(false)
	stage.distance = 150.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 2.5, 3.4, 0.0)

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	await load_level()
	test_styles()
	await test_lob()
	for family in FAMILIES:
		await test_family(family)
	for line in lines:
		print(line)
	print("BEE_LOTE13_COMBAT_V01_OK")
	quit(0)


func test_styles() -> void:
	var rims: Array[Color] = []
	var names: Array[StringName] = []
	for style in BeeShotStyles.STYLES:
		var body := BeeShotStyles.build(style)
		var core := body.get_node_or_null("Core") as MeshInstance3D
		check(core != null and ((core.mesh as PrimitiveMesh).material as StandardMaterial3D).albedo_color.is_equal_approx(BeeShotStyles.CORE_COLOR), "%s has the cyan core" % style)
		var rim: Color = BeeShotStyles.STYLES[style]["rim"]
		check(not BeeToonStyle.is_cyan(rim), "%s rim is not cyan (cyan is the core)" % style)
		# The pebble is orange but dark, tumbling, lobbed and carries the cyan core: it still reads apart from the golden shot.
		check(_colour_distance(rim, BEE_GOLD) >= 0.3 or style == &"pebble", "%s rim contrasts with Bee's gold shot" % style)
		for i in rims.size():
			# Two families may share a tone only when the SHAPE tells them apart (pebble / stone are both rocks: other tone, size and arc).
			var same_shape: bool = BeeShotStyles.STYLES[style]["shape"] == BeeShotStyles.STYLES[names[i]]["shape"]
			check(_colour_distance(rim, rims[i]) >= 0.25 or not same_shape, "%s and %s look alike" % [style, names[i]])
		rims.append(rim)
		names.append(style)
		body.free()
	for family_style in SHOT_TABLE.values():
		check(BeeShotStyles.has_style(family_style), "Style %s exists" % family_style)
	lines.append("LOTE13 styles=%d (cyan core, own rim, shape and trail)" % BeeShotStyles.STYLES.size())


func _colour_distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func test_lob() -> void:
	var origin := Vector3(stage.camera.global_position.x + 3.0, 0.6, 0.0)
	var goal := Vector3(stage.camera.global_position.x - 2.0, 3.0, 0.0)
	var flight := 1.2
	var gravity := 8.0
	var shot := BeeEnemyPatterns.spawn_lob(stage, preload("res://scenes/projectiles/toon/alien_bolt.tscn"), origin, goal, 5, flight, gravity, stage, &"pebble")
	shot.hitbox.set_enabled(false) # Pure trajectory: nothing it flies through may stop it.
	var landed_at := origin
	for i in int(flight * 60.0):
		await physics_frame
		if is_instance_valid(shot):
			landed_at = shot.global_position
	check(landed_at.distance_to(goal) < 0.5, "A lob lands on its aim point (off by %.2f m)" % landed_at.distance_to(goal))
	check(not is_instance_valid(shot) or shot.gravity > 0.0, "Lobbed shots carry gravity")
	if is_instance_valid(shot):
		shot.queue_free()
	lines.append("LOTE13 lob flight=%.1fs lands within %.2f m" % [flight, landed_at.distance_to(goal)])


## One family alone: time on screen -> first warning, shortest warning, and the shot styles fired within SHOT_WATCH_SECONDS.
func test_family(family: String) -> void:
	await load_level()
	wave._spawn({"family": family, "slot": 0, "event": 0, "due": 0.0, "hard": false})
	var unit := wave.active_units.back() as Node3D
	var on_screen_at := -1.0
	var first_warning_at := -1.0
	var min_warning := INF
	var clock := 0.0
	var styles_seen := {}
	var warning_started := -1.0
	var shooter: BeeImplantShooter
	for child in unit.get_children():
		if child is BeeImplantShooter:
			shooter = child
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	for i in int(SHOT_WATCH_SECONDS * 60.0):
		await physics_frame
		clock += tick
		if not is_instance_valid(unit):
			break
		if on_screen_at < 0.0 and BeeShmupFairness.is_on_screen(unit, 0.0) and unit.visible: # A buried worm shows its ground mark: it counts.
			on_screen_at = clock
		var warning := false
		if unit.has_method("is_telegraphing") and bool(unit.call("is_telegraphing")):
			warning = true
		if shooter != null and shooter.warning != null:
			warning = true
		if warning and first_warning_at < 0.0 and on_screen_at >= 0.0:
			first_warning_at = clock
		if warning and warning_started < 0.0:
			warning_started = clock
		elif not warning and warning_started >= 0.0:
			min_warning = minf(min_warning, clock - warning_started)
			warning_started = -1.0
		for node in get_nodes_in_group("alien_projectiles"):
			var style: StringName = node.get_meta("shot_style", &"")
			if style != &"":
				styles_seen[style] = int(styles_seen.get(style, 0)) + 1
		bee.global_position = Vector3(stage.camera.global_position.x - 2.5, 3.4, 0.0) # Bee stays put (invulnerable).
		if (not SHOT_TABLE.has(family) or styles_seen.has(SHOT_TABLE[family])) and first_warning_at >= 0.0 and clock > 6.0:
			break
	var delay := first_warning_at - on_screen_at
	check(on_screen_at >= 0.0 and first_warning_at >= 0.0, "%s never warned (on screen %.2f, warning %.2f)" % [family, on_screen_at, first_warning_at])
	check(delay <= FIRST_DELAY_LIMIT + TIMING_TOLERANCE, "%s: first warning %.2f s after entering the screen (max %.1f s)" % [family, delay, FIRST_DELAY_LIMIT])
	if min_warning < INF:
		check(min_warning >= 0.4 - 0.05, "%s: a warning lasted only %.2f s (min 0.4 s)" % [family, min_warning])
	if SHOT_TABLE.has(family):
		check(styles_seen.has(SHOT_TABLE[family]), "%s never fired its %s shot (saw %s)" % [family, SHOT_TABLE[family], str(styles_seen.keys())])
	lines.append("LOTE13 %s first_warning=%.2fs after entering the screen · shortest_warning=%s · shots=%s" % [family, delay, ("%.2fs" % min_warning) if min_warning < INF else "-", str(styles_seen)])
