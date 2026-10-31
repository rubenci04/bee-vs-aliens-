extends SceneTree

# LOTE 9 · ETAPA B — SHOTS, ITEMS AND READABILITY.
#   shots     Bee fires a round gold plasma ball (white core, gold halo, short trail; the old toon bolt hidden); every enemy
#             shot of the level (regular and UFO) is a cold cyan orb with a violet rim; the two colours are far apart
#   cyan      every enemy family shows a visible cyan glow at dusk (implant, core or emitter); the crosshair turns cyan and
#             frames the hostile under it
#   items     a bomb pickup gives +3 bombs up to the cap (5); at the cap it stays on the ground; every item of the level has a
#             beacon (halo, ring, white outline, light column); item colours are far from the ochre soil, never cyan, and
#             far from each other
#   supply    a bomb pickup and a honey jar wait right before the X=340 gate

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const ENEMIES := ["Wasp", "Probe", "EyeDrone", "Turret", "Speeder", "Walker", "Dragonfly", "Spider", "Mosquito", "Ladybird",
		"WaveDragonfly", "Moth", "Ant", "StagBeetle", "Snail", "MushroomCannon", "SeedCarrier", "AlienFighter", "Swarm"]
const GROUND_KEYS := ["mulch", "mulch_dark", "mulch_light"]
const MIN_GLOW := BeeHostileGlow.MIN_GLOW

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var lines: Array[String] = []

func _initialize() -> void:
	BeeLevel01Controller.roster_only = false # LOTE 12: this test covers the pre-roster flow (alien enemies, frog, UFO), which stays intact behind LEVEL01_ROSTER_ONLY.
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

static func hue_distance(a: Color, b: Color) -> float:
	var d := absf(a.h - b.h)
	return minf(d, 1.0 - d) * 360.0

static func rgb_distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()

func goto(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 3.2, 0.0)
	await frames(4)

func spawn(family: String, y := 3.6, x := 0.0) -> Node3D:
	wave._spawn({"family": family, "slot": wave.active_units.size(), "event": 0, "due": 0.0, "hard": true, "y": y, "x": x})
	return wave.active_units.back() if family != "Swarm" else wave.swarm_units.back()

func clear() -> void:
	for unit in wave.active_units + wave.swarm_units:
		if is_instance_valid(unit):
			unit.queue_free()
	wave.active_units.clear()
	wave.swarm_units.clear()
	for node in get_nodes_in_group("alien_projectiles"):
		node.queue_free()
	await frames(2)

func run() -> void:
	BeeLevel01Controller.instant_arrival = true # Tanda E
	create_timer(240.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_children().filter(func(n): return n.name != "SceneFade").back() # Tanda E: the scene-fade cover is added after the level
	await frames(6)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.health.damage_blocked = true
	wave.set_physics_process(false)
	await test_shots()
	await test_cyan()
	await test_crosshair()
	await test_bombs()
	await test_items()
	for line in lines:
		print(line)
	print("BEE_ITEMS_SHOTS_V04_OK")
	quit(0)

# --- shots ---------------------------------------------------------------------------------------------------------

func _halo_color(projectile: Node3D) -> Color:
	var ball := projectile.get_node(BeeShotPalette.PLASMA_NAME) as Node3D
	var halo := ball.get_node("Halo") as MeshInstance3D
	return (halo.mesh.surface_get_material(0) as StandardMaterial3D).albedo_color

func test_shots() -> void:
	await goto(100.0)
	bee.set_aim_point(bee.global_position + Vector3(4.0, 0.0, 0.0))
	var shot := bee.fire() as Node3D
	await frames(3)
	check(shot != null and is_instance_valid(shot) and shot.has_node(BeeShotPalette.PLASMA_NAME), "Bee must fire the plasma ball")
	var ball := shot.get_node(BeeShotPalette.PLASMA_NAME) as Node3D
	check(ball.has_node("Core") and ball.has_node("Halo") and ball.has_node("Outer") and (shot as BeeEnergyProjectile).trail.visible and (shot as BeeEnergyProjectile).trail.emitting, "Plasma ball: core + halo + outer + short trail")
	check(not (shot.get_node("Visual") as Node3D).visible, "The old toon bolt (arrow) must be hidden")
	var bee_halo := _halo_color(shot)
	check(bee_halo.is_equal_approx(Color(BeeShotPalette.BEE_SHOT_COLOR, BeeShotPalette.HALO_ALPHA * (preload("res://scripts/game/bee_hero_look_settings.gd").SHOT_GLOW if preload("res://scripts/game/bee_hero_look_settings.gd").HERO_LOOK_ENABLED else 1.0))), "Bee halo must be BEE_SHOT_COLOR (Tanda S: 60 %% glow)")
	var core := ((ball.get_node("Core") as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D).albedo_color
	check(core.v > 0.95 and core.s < 0.15, "Bee core must be white-hot")
	var trail_seconds := (shot as BeeEnergyProjectile).trail.lifetime
	check(is_equal_approx(trail_seconds, BeeEnergyProjectile.SHOOTING.SHOT_TRAIL_SECONDS), "Bee trail uses the configured Tanda 4c duration")
	# A regular enemy shot (Probe) and a UFO shot.
	var probe := spawn("Probe", 3.2, -2.0)
	var enemy_shot: Node3D
	for i in 600:
		await physics_frame
		for node in get_nodes_in_group("alien_projectiles"):
			if is_instance_valid(node) and (node as Node3D).has_node(BeeShotPalette.PLASMA_NAME):
				enemy_shot = node
		if enemy_shot != null:
			break
	check(enemy_shot != null, "The probe shot was never dressed as the cold orb")
	var enemy_halo := _halo_color(enemy_shot)
	check(BeeToonStyle.is_cyan(enemy_halo), "Enemy halo must be cyan (%s)" % enemy_halo)
	var outer := (((enemy_shot.get_node(BeeShotPalette.PLASMA_NAME) as Node3D).get_node("Outer") as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D).albedo_color
	check(hue_distance(outer, BeeShotPalette.ENEMY_SHOT_RIM) < 1.0, "Enemy rim must be violet")
	check(not BeeToonStyle.is_cyan(BeeShotPalette.BEE_SHOT_COLOR) and BeeToonStyle.is_cyan(BeeShotPalette.ENEMY_SHOT_COLOR), "Gold vs cyan")
	var apart := hue_distance(BeeShotPalette.BEE_SHOT_COLOR, BeeShotPalette.ENEMY_SHOT_COLOR)
	check(apart >= 90.0, "Shot colours too close (%.0f deg)" % apart)
	var ufo_shot := (load("res://scenes/levels/ufo_boss_projectile.tscn") as PackedScene).instantiate() as Node3D
	ufo_shot.add_to_group(UfoBoss01.PROJECTILE_GROUP)
	stage.add_child(ufo_shot)
	ufo_shot.global_position = stage.camera.global_position + Vector3(2.0, 0.0, 0.0)
	ufo_shot.set_physics_process(false)
	await frames(2)
	check(ufo_shot.has_node(BeeShotPalette.PLASMA_NAME) and is_equal_approx((ufo_shot.get_node(BeeShotPalette.PLASMA_NAME) as Node3D).scale.x, BeeShotPalette.BOSS_SHOT_SIZE), "UFO shots: bigger cold orb")
	ufo_shot.queue_free()
	lines.append("SHOTS bee halo=%s core=%s trail=%.2fs | enemy halo=%s rim=%s | hue apart=%.0f deg" % [bee_halo.to_html(false), core.to_html(false), trail_seconds, enemy_halo.to_html(false), outer.to_html(false), apart])
	probe.queue_free()
	await clear()

# --- cyan = hostile ------------------------------------------------------------------------------------------------

func test_cyan() -> void:
	await goto(300.0) # Dusk.
	var weakest := INF
	var report: Array[String] = []
	for family in ENEMIES:
		var unit := spawn(family, 3.6)
		await frames(3)
		var glow := BeeHostileGlow.strongest(unit)
		report.append("%s=%.2f" % [family, glow])
		weakest = minf(weakest, glow)
		check(glow >= MIN_GLOW, "%s has no readable cyan glow at dusk (%.2f)" % [family, glow])
		await clear()
	lines.append("CYAN at dusk (strongest glow per family): " + " ".join(report))

func test_crosshair() -> void:
	await goto(120.0)
	var crosshair := stage.get_node("CanvasLayer/Crosshair") as BeeLevel01Crosshair
	var target := spawn("Ladybird", 3.6, -2.0)
	target.global_position = Vector3(stage.camera.global_position.x + 1.0, 3.6, 0)
	target.show()
	target.set_physics_process(false)
	await frames(4)
	bee.set_aim_point(target.call("auto_aim_point"))
	bee.aim_direction() # Headless has no _draw(): explicitly refresh the Tanda 4a selector.
	await process_frame
	await process_frame
	check(crosshair.hovered == target, "The crosshair must lock on the hostile under it")
	bee.set_aim_point(target.global_position + Vector3(0.0, 3.0, 0.0))
	bee.aim_direction()
	await process_frame
	await process_frame
	check(crosshair.hovered == null, "Off target the crosshair is the normal warm ring")
	lines.append("CROSSHAIR uses actual assisted target; HOVER_RADIUS helper %.1f m" % BeeLevel01Crosshair.HOVER_RADIUS)
	await clear()

# --- items ---------------------------------------------------------------------------------------------------------

func _bomb_item(at: Vector3) -> BeePowerupPickup:
	var item := (load("res://scenes/items/toon/bomb.tscn") as PackedScene).instantiate() as BeePowerupPickup
	item.kind = BeePowerupPickup.Kind.BOMB
	stage.add_child(item)
	item.global_position = at
	return item

func test_bombs() -> void:
	await goto(60.0)
	check(bee.bomb_pickup_charges == 3 and bee.max_bomb_charges == 5, "Bomb pickup +3, cap 5")
	bee.bomb_charges = 0
	var first := _bomb_item(bee.global_position + Vector3(6.0, 0.0, 0.0))
	check(first.collect(bee) and bee.bomb_charges == 3, "A bomb pickup must give 3 bombs (%d)" % bee.bomb_charges)
	var second := _bomb_item(bee.global_position + Vector3(6.0, 0.0, 0.0))
	check(second.collect(bee) and bee.bomb_charges == 5, "Bombs must stop at the cap 5 (%d)" % bee.bomb_charges)
	var third := _bomb_item(bee.global_position + Vector3(6.0, 1.0, 0.0))
	check(not third.collect(bee) and bee.bomb_charges == 5 and is_instance_valid(third) and not third.was_collected, "At the cap the pickup stays for later")
	await frames(2)
	check(third.has_node("ItemBeacon"), "A pickup spawned later gets its beacon too")
	third.queue_free()
	lines.append("BOMBS pickup +%d, cap %d (0 -> 3 -> 5, refused at 5)" % [bee.bomb_pickup_charges, bee.max_bomb_charges])

func test_items() -> void:
	var beacons := {}
	for item in stage.find_children("*", "Area3D", true, false):
		if item is BeePowerupPickup or item is BeePollenPickup:
			var beacon := item.get_node_or_null("ItemBeacon") as BeeItemBeacon
			check(beacon != null, "Item without beacon: %s" % item.get_path())
			if item is BeePollenPickup:
				check(item.has_node("PollenGrains") and not beacon.visible, "T3m pollen uses three grains without a beacon")
			else:
				check(beacon.halo != null and beacon.ring != null and beacon.outline != null and beacon.column != null, "Beacon parts missing")
			beacons[beacon.kind] = beacon
	for kind in [&"pollen", &"spread", &"bomb", &"cluster"]: # LOTE 13: the honey jar became a pollen cluster
		check(beacons.has(kind), "No %s item with a beacon in the level" % kind)
	# T3i: pollen rotates slowly; other items retain their previous beacons.
	var probe: Node3D = beacons[&"pollen"].get_parent().get_node("PollenGrains")
	var low := INF
	var high := -INF
	for i in 40:
		await process_frame
		low = minf(low, probe.rotation.z)
		high = maxf(high, probe.rotation.z)
	check(high - low >= 0.05, "The pollen grains must rotate slowly")
	# Colour contrast: against the ochre soil (day palette) and between kinds; never cyan (hostile).
	var report: Array[String] = []
	for kind in BeeItemBeacon.COLORS:
		var colour: Color = BeeItemBeacon.COLORS[kind]
		check(not BeeToonStyle.is_cyan(colour), "%s item is cyan (hostile colour)" % kind)
		check(colour.s >= 0.6 and colour.v >= 0.9, "%s item colour not saturated / bright" % kind)
		var worst_rgb := INF
		var worst_hue := INF
		for key in GROUND_KEYS:
			var ground: Color = BeeLevel01VisualTarget.PALETTE[key]
			worst_rgb = minf(worst_rgb, rgb_distance(colour, ground))
			worst_hue = minf(worst_hue, hue_distance(colour, ground))
		check(worst_rgb >= 0.45 and worst_hue >= 30.0, "%s item too close to the ochre soil (rgb %.2f, hue %.0f deg)" % [kind, worst_rgb, worst_hue])
		for other in BeeItemBeacon.COLORS:
			if other != kind:
				check(hue_distance(colour, BeeItemBeacon.COLORS[other]) >= 45.0, "%s and %s items too alike" % [kind, other])
		report.append("%s=%s (soil rgb %.2f, hue %.0f deg)" % [kind, colour.to_html(false), worst_rgb, worst_hue])
	lines.append("ITEMS " + " · ".join(report))
	# Pre-boss supply before the X=340 gate.
	var supply := stage.get_node_or_null("PreBossSupply") as Node3D
	check(supply != null, "Pre-boss supply missing")
	var bomb := supply.get_node("SupplyBomb") as BeePowerupPickup
	var jar := supply.get_node("SupplyHealing") as Node3D
	check(bomb.kind == BeePowerupPickup.Kind.BOMB and bomb.global_position.x > 330.0 and bomb.global_position.x < 340.0, "Supply bomb before the gate")
	check(jar is BeePollenCluster and jar.global_position.x > 330.0 and jar.global_position.x < 340.0, "Supply pollen cluster before the gate")
	check(bomb.has_node("ItemBeacon") and jar.has_node("ItemBeacon"), "Supply items need beacons")
	lines.append("SUPPLY bomb (+3) at X=%.1f, pollen cluster at X=%.1f (gate X=340)" % [bomb.global_position.x, jar.global_position.x])
