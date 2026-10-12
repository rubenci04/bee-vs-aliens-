extends SceneTree

# LOTE 9 · ETAPA A — LIBERATE AND DAMAGE.
#   rule      every hit on a controlled animal damages its implant: body / shell / wings / legs at 1x, a direct hit on
#             the implant (or a shot lined up on it, Wasp / Spider) at 2x; the bomb (area damage) is 1x
#   timing    SIMULATED SHOTS with real hitboxes and the real HealthComponents of units spawned by the level director
#             (LEVEL_HP, NORMAL): 3 taps/s of 10 HP. Animal taps go body, implant, body, miss (normal aim, 30 effective
#             DPS); technology taps all hit at 1x (30 DPS). The time to liberate / destroy must be inside its target range
#   route     <= 70 units in EVENTS, every family appears, 3 combat zones of exactly 2 waves, on-screen caps 4 / 5,
#             the X=254 hard gate and the checkpoints unchanged
#   flapping  the moth flaps its wings (wide lift range), bobs and sways; the decorative butterflies too
# Prints BALANCE lines with every measured time (copied into docs/INFORME_LOTE_9.md).

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const TAPS_PER_SECOND := 3.0
const SHOT_DAMAGE := 10
const ANIMAL_PATTERN := [&"body", &"implant", &"body", &"miss"]
## The controlled dragonfly comes head-on and its implant sphere covers head + thorax: its taps land on the implant.
const DRAGONFLY_PATTERN := [&"implant", &"implant", &"implant", &"miss"]
## Target seconds [min, max] to liberate (animals) / destroy (technology) with the reference fire.
const TARGETS := {
	"Mosquito": [0.5, 0.9], "Wasp": [0.5, 0.9],
	"Ladybird": [1.4, 2.1], "Ant": [1.4, 2.1], "Moth": [1.4, 2.1], "Dragonfly": [1.4, 2.1], "WaveDragonfly": [1.4, 2.1],
	"MushroomCannon": [1.4, 2.1], "Spider": [1.8, 2.2],
	"StagBeetle": [3.0, 4.0], "Snail": [3.0, 4.0],
	"SeedCarrier": [6.0, 8.0],
	"Speeder": [0.8, 1.2], "EyeDrone": [1.0, 1.5], "Probe": [1.8, 2.2], "Turret": [1.8, 2.2], "AlienFighter": [1.8, 2.2], "Walker": [2.8, 3.5],
}
const TECH := ["SeedCarrier", "Speeder", "EyeDrone", "Probe", "Turret", "AlienFighter", "Walker"]

## Carries the hitbox like a Bee projectile does (DamageHurtbox3D reads `travel_direction` for the weak-point line).
class Mover extends Node3D:
	var travel_direction := Vector3.RIGHT

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var lines: Array[String] = []

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

func run() -> void:
	create_timer(240.0, true, false, true).timeout.connect(func(): quit(1))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.health.damage_blocked = true
	bee.set_physics_process(false)
	stage.scroll_speed = 0.0
	wave.set_physics_process(false) # No events: the test spawns every family itself.
	_route_checks()
	for family in TARGETS:
		await _measure(str(family))
	await _bomb_is_1x()
	await _flapping()
	for line in lines:
		print(line)
	print("BEE_BALANCE_LIBERATION_V04_OK")
	quit(0)

# --- route ---------------------------------------------------------------------------------------------------------

func _route_checks() -> void:
	var units := 0
	var families := {}
	var zones := 0
	for event: Dictionary in BeeLevel01Controller.EVENTS:
		for family in event["units"]:
			units += 1
			families[str(family)] = true
		if event.has("arena"):
			zones += 1
			for wave_def: Dictionary in event["arena"]:
				for family in wave_def["units"]:
					units += 1
					families[str(family)] = true
			check((event["arena"] as Array).size() == 3, "Combat zone at X=%s must have 3 waves" % event["at"])
	check(units >= 144 and units <= 150, "Route units %d outside 144-150 (LOTE 11)" % units)
	for family in ["Wasp", "Probe", "EyeDrone", "Turret", "Speeder", "Walker", "Dragonfly", "Swarm", "Spider", "Mosquito", "Ladybird",
			"WaveDragonfly", "Moth", "Ant", "StagBeetle", "Snail", "MushroomCannon", "SeedCarrier", "AlienFighter"]:
		check(families.has(family), "Family %s vanished from the route" % family)
	check(zones == 3, "Three combat zones (%d)" % zones)
	check(BeeLevel01Controller.MAX_ON_SCREEN == 7 and BeeLevel01Controller.MAX_ON_SCREEN_ARENA == 10, "On-screen caps must be 7 / 10 (LOTE 11)")
	var gate := BeeLevel01Controller.EVENTS.filter(func(e): return is_equal_approx(float(e["at"]), 254.0))
	check(gate.size() == 1 and bool(gate[0].get("hard", false)), "The X=254 hard gate must stay")
	var checkpoints := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	check(is_equal_approx(float(checkpoints.checkpoint_list()[0]), 190.0) and is_equal_approx(float(checkpoints.checkpoint_list()[1]), 281.0), "Checkpoints must stay at X=190 / 281 (%s)" % str(checkpoints.checkpoint_list()))
	lines.append("BALANCE route units=%d families=%d zones=%d caps=%d/%d" % [units, families.size(), zones, BeeLevel01Controller.MAX_ON_SCREEN, BeeLevel01Controller.MAX_ON_SCREEN_ARENA])

# --- time to liberate ----------------------------------------------------------------------------------------------

func _spawn(family: String) -> Node3D:
	stage.distance = 120.0
	stage._update_camera_and_bounds()
	var before := wave.active_units.size()
	wave._spawn({"family": family, "slot": 0, "event": 0, "due": 0.0, "hard": true, "y": 3.6, "x": 0.0})
	check(wave.active_units.size() == before + 1, "%s did not spawn" % family)
	var unit := wave.active_units.back() as Node3D
	await frames(3)
	unit.set_physics_process(false) # Still: the shots are simulated where its areas are.
	return unit

func _areas(unit: Node3D) -> Dictionary:
	# body: the area a body shot lands on; implant: the implant area; point: where a shot lined up on the implant passes.
	if unit is AssetFauna:
		var fauna := unit as AssetFauna
		var body: DamageHurtbox3D = fauna.body_hurtbox if fauna.body_hurtbox != null else fauna.hurtbox
		return {"body": body, "implant": fauna.hurtbox, "point": fauna.hurtbox.global_position}
	if unit is ControlledDragonfly:
		var dragonfly := unit as ControlledDragonfly
		return {"body": dragonfly.body_shield, "implant": dragonfly.hurtbox, "point": dragonfly.hurtbox.global_position}
	var hurtbox := unit.get_node("Hurtbox3D") as DamageHurtbox3D
	var point: Vector3 = hurtbox.weak_point.global_position if hurtbox.weak_point != null else hurtbox.global_position
	return {"body": hurtbox, "implant": hurtbox, "point": point}

func _shoot(area: DamageHurtbox3D, line_y: float, line_x: float) -> int:
	var mover := Mover.new()
	root.add_child(mover)
	mover.global_position = Vector3(line_x - 0.6, line_y, 0.0)
	var hitbox := DamageHitbox3D.new()
	hitbox.team_id = &"bee"
	hitbox.damage = SHOT_DAMAGE
	mover.add_child(hitbox)
	hitbox.set_enabled(true)
	var applied := area.receive_hit(hitbox)
	mover.queue_free()
	return applied

func _measure(family: String) -> void:
	var unit := await _spawn(family)
	var health := unit.get_node("HealthComponent") as HealthComponent
	check(health.max_health == int(BeeLevel01Controller.LEVEL_HP[family]), "%s HP %d != LEVEL_HP" % [family, health.max_health])
	var areas := _areas(unit)
	var point: Vector3 = areas["point"]
	var animal := not (family in TECH)
	if animal:
		check(areas["body"] != areas["implant"] or (areas["implant"] as DamageHurtbox3D).weak_point != null, "%s needs a body area and an implant area / weak point" % family)
	var shot := 0
	var applied_log: Array[int] = []
	while health.current_health > 0 and shot < 60:
		var pattern: Array = DRAGONFLY_PATTERN if family == "Dragonfly" else ANIMAL_PATTERN
		var kind: StringName = pattern[shot % pattern.size()] if animal else &"body"
		var applied := 0
		match kind:
			&"implant":
				applied = _shoot(areas["implant"], point.y, point.x)
			&"body":
				# The shot line passes under the implant (legs, abdomen, shell): just outside its weak-point radius.
				applied = _shoot(areas["body"], point.y - maxf(0.5, (areas["body"] as DamageHurtbox3D).weak_point_radius + 0.1), point.x)
			_:
				applied = 0
		applied_log.append(applied)
		if health.current_health > 0:
			shot += 1
	var seconds := float(shot) / TAPS_PER_SECOND
	var target: Array = TARGETS[family]
	if not animal:
		check(applied_log[0] == SHOT_DAMAGE, "%s: technology takes 1x (%d)" % [family, applied_log[0]])
	check(seconds >= float(target[0]) - 0.001 and seconds <= float(target[1]) + 0.001, "%s frees / breaks in %.2f s, outside %.1f-%.1f s" % [family, seconds, target[0], target[1]])
	lines.append("BALANCE %-14s HP=%3d shots=%2d time=%.2fs target=%.1f-%.1fs %s" % [family, health.max_health, shot + 1, seconds, target[0], target[1], "animal" if animal else "tech"])
	await frames(2)
	_clear()
	if animal:
		await _rule(family)

## One body hit (1x), one implant hit (2x) and one shot along the auto-aim line (the body, 1x; the dragonfly's implant
## sphere covers its front, so its auto-aim stays on the implant) on a fresh unit.
func _rule(family: String) -> void:
	var unit := await _spawn(family)
	var health := unit.get_node("HealthComponent") as HealthComponent
	health.max_health = 1000 # Room for three shots on the lightest animal.
	health.current_health = 1000
	var areas := _areas(unit)
	var point: Vector3 = areas["point"]
	var body := _shoot(areas["body"], point.y - maxf(0.5, (areas["body"] as DamageHurtbox3D).weak_point_radius + 0.1), point.x)
	var implant := _shoot(areas["implant"], point.y, point.x)
	check(body == SHOT_DAMAGE, "%s: a body hit must do 1x (%d)" % [family, body])
	check(implant == SHOT_DAMAGE * 2, "%s: an implant hit must do 2x (%d)" % [family, implant])
	var aim: Vector3 = bee._target_point(unit)
	var auto := _shoot(areas["body"] if family != "Dragonfly" else areas["implant"], aim.y, aim.x)
	var expected := SHOT_DAMAGE * 2 if family == "Dragonfly" else SHOT_DAMAGE
	check(auto == expected, "%s: the auto-aim line must hit the %s (%d)" % [family, "implant" if family == "Dragonfly" else "body at 1x", auto])
	lines.append("BALANCE %-14s rule body=%d implant=%d auto-aim=%d" % [family, body, implant, auto])
	await frames(2)
	_clear()

func _bomb_is_1x() -> void:
	var unit := await _spawn("Ladybird")
	var fauna := unit as AssetFauna
	var health := fauna.health
	var before := health.current_health
	var bomb := (load("res://scenes/bee_prototype/bee_alien_bomb.tscn") as PackedScene).instantiate() as BeeAlienBomb
	stage.add_child(bomb)
	bomb.global_position = fauna.hurtbox.global_position
	bomb.activate(bee, 3.0, 32)
	bomb.detonate()
	await frames(18)
	check(before - health.current_health == 32, "The bomb must hit an animal once at 1x (took %d)" % (before - health.current_health))
	lines.append("BALANCE bomb on an animal: %d (1x, once even over body + implant)" % (before - health.current_health))
	_clear()

func _clear() -> void:
	for unit in wave.active_units:
		if is_instance_valid(unit):
			unit.set_physics_process(false)
			unit.queue_free()
	wave.active_units.clear()

# --- flapping ------------------------------------------------------------------------------------------------------

func _flapping() -> void:
	var moth := await _spawn("Moth") as AssetFauna
	moth.set_physics_process(true)
	check(moth.wings.size() == 4, "The moth must flap its 4 wings (%d)" % moth.wings.size())
	var lift_min := INF
	var lift_max := -INF
	var y_min := INF
	var y_max := -INF
	var sway_max := 0.0
	for i in 90:
		await physics_frame
		var lift := moth.wing_lift()
		lift_min = minf(lift_min, lift)
		lift_max = maxf(lift_max, lift)
		y_min = minf(y_min, moth.visual.position.y)
		y_max = maxf(y_max, moth.visual.position.y)
		sway_max = maxf(sway_max, absf(moth.visual.rotation.z))
	check(lift_max - lift_min >= 0.9, "Moth wings barely move (%.2f rad)" % (lift_max - lift_min))
	check(y_max - y_min >= 0.12, "Moth body must bob (%.2f m)" % (y_max - y_min))
	check(sway_max >= 0.05, "Moth body must sway (%.2f rad)" % sway_max)
	lines.append("BALANCE moth flap lift=%.2f..%.2f rad bob=%.2f m sway=%.2f rad" % [lift_min, lift_max, y_max - y_min, sway_max])
	_clear()
	var garden := stage.find_child("LivingGarden", true, false) as BeeLevel01LivingGarden
	if garden == null:
		for node in stage.find_children("*", "Node3D", true, false):
			if node is BeeLevel01LivingGarden:
				garden = node
				break
	check(garden != null and not garden.butterflies.is_empty(), "Living garden butterflies missing")
	var fly := garden.butterflies[0]
	fly.set_meta("home", Vector3(stage.camera.global_position.x + 2.0, 3.6, -3.2))
	var wing_min := INF
	var wing_max := -INF
	var fy_min := INF
	var fy_max := -INF
	var roll := 0.0
	for i in 60:
		await process_frame
		var r := (fly.get_child(0) as Node3D).rotation.x
		wing_min = minf(wing_min, r)
		wing_max = maxf(wing_max, r)
		fy_min = minf(fy_min, fly.global_position.y)
		fy_max = maxf(fy_max, fly.global_position.y)
		roll = maxf(roll, absf(fly.rotation.z))
	check(wing_max - wing_min >= 1.2, "Butterfly wings barely move (%.2f rad)" % (wing_max - wing_min))
	check(fy_max - fy_min >= 0.1, "Butterfly must ride a wavy path (%.2f m)" % (fy_max - fy_min))
	check(roll >= 0.05, "Butterfly body must sway (%.2f rad)" % roll)
	lines.append("BALANCE butterfly wing=%.2f..%.2f rad wave=%.2f m roll=%.2f rad" % [wing_min, wing_max, fy_max - fy_min, roll])
