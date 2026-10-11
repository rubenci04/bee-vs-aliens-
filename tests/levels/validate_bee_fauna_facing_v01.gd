extends SceneTree

# LOTE 7 — ORIENTATION. Every Codex model looks along -X at yaw 0. Each AssetFauna family (and the decorative fireflies) must
# FACE WHERE IT MOVES: in every stretch where the body moves steadily (same direction for STABLE_FRAMES frames, faster than
# MIN_SPEED m/s, screen-relative for flyers / on the ground for walkers) the model's forward must match the motion.
# Measured from raw positions (not from the script's own smoothed value). Also: a liberated animal looks where it flies off.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const FAMILIES := ["Mosquito", "Ladybird", "WaveDragonfly", "Moth", "Ant", "StagBeetle", "Snail", "SeedCarrier"]
const MIN_SPEED := 1.6
const STABLE_FRAMES := 18
const FRAMES_PER_FAMILY := 720

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var report: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func arena(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 2.6, 0)

func clear() -> void:
	for unit in wave.active_units:
		unit.set_physics_process(false)
		unit.queue_free()
	wave.active_units.clear()
	for group in ["alien_projectiles", "ufo_boss_mines", "asset_mines"]:
		for node in get_nodes_in_group(group):
			node.queue_free()
	BeeAttackTokens.reset()
	await frames(2)

func test_family(family: String) -> void:
	arena(120.0)
	wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false, "y": 4.0})
	var unit := wave.active_units.back() as AssetFauna
	unit.max_cycles = 99
	var prev := unit.global_position.x
	var run_sign := 0.0
	var run := 0
	var checked := 0
	var wrong := 0
	for i in FRAMES_PER_FAMILY:
		await physics_frame
		# Bee drifts up and down so flyers keep repositioning in both directions.
		bee.global_position.y = 2.6 + 1.6 * sin(float(i) * 0.02)
		bee.global_position.x = stage.camera.global_position.x - 3.5 + 2.5 * sin(float(i) * 0.013)
		var x := unit.global_position.x
		var vx := (x - prev) * 60.0 # Camera static (scroll 0): world = screen-relative.
		prev = x
		var s := signf(vx) if absf(vx) >= (0.55 if family == "Snail" else MIN_SPEED) else 0.0 # The snail crawls at 0.7 m/s.
		if s != 0.0 and s == run_sign:
			run += 1
		else:
			run = 1 if s != 0.0 else 0
			run_sign = s
		if run >= STABLE_FRAMES and unit.state != AssetFauna.State.LIBERATED:
			checked += 1
			if unit.forward_x() != run_sign:
				wrong += 1
	check(checked >= 10, "%s barely moved (%d samples)" % [family, checked])
	check(wrong == 0, "%s faced away from its motion in %d of %d samples" % [family, wrong, checked])
	report.append("%s %d samples" % [family, checked])
	# Liberation: it looks where it flies / walks away.
	unit.health.take_damage(99999)
	await frames(20)
	if family != "SeedCarrier": # The machine (no implant) is destroyed in place.
		check(unit.forward_x() < 0.0 and unit.global_position.x < prev, "%s must look where it leaves (-X)" % family)
	await clear()

func test_fireflies() -> void:
	arena(220.0)
	var dressing := stage.get_node("AssetDressing") as BeeLevel01AssetDressing
	check(not BeeLevel01AssetDressing.FIREFLIES_ENABLED and dressing.fireflies.is_empty(), "Fireflies must stay disabled in Level 01")
	dressing._build_fireflies() # Exercise the reserved forest-level movement implementation without adding Level 01 decoration.
	var bug := dressing.fireflies[0]
	dressing.set_process(false) # Driven at a fixed 60 Hz below (headless process frames have no stable delta).
	var prev := bug.global_position.x
	var checked := 0
	for i in 600:
		dressing._process(1.0 / 60.0)
		var x := bug.global_position.x
		var dx := x - prev
		prev = x
		if absf(dx) < 0.004 or absf(dx) > 1.0: # NOCHE 01: >1 m in a frame = it wrapped back to the right edge.
			continue
		var forward := 1.0 if absf(bug.rotation.y - PI) < 0.01 else -1.0
		check(forward == signf(dx), "Firefly faces away from its drift (dx %.3f, yaw %.2f)" % [dx, bug.rotation.y])
		checked += 1
	check(checked > 100, "Firefly barely moved")
	report.append("fireflies %d samples" % checked)

func run() -> void:
	create_timer(600.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	for family in FAMILIES:
		await test_family(family)
	await test_fireflies()
	print("FAUNA_FACING ", " · ".join(report), " · MushroomCannon static (faces Bee)")
	print("BEE_FAUNA_FACING_V01_OK")
	quit(0)
