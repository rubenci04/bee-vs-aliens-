extends SceneTree

# NOCHE 01 · ETAPA 1 — LIBERATION. Controlled animals are FREED, never killed; technology explodes.
#   animals   implant at 0 -> still there (not freed from the tree at once), warm, "LIBERADO" text, no live hitbox,
#             out of the director's threats at once, counted in LIBERADOS n/N, then it leaves (moves away) and is released
#   tech      Probe / seed carrier explode (not counted); the mushroom cannon loses only its cannon (mushroom stays, harmless)
#   organism  the purple one-eyed organism is out of the normal events; the UFO brings it (ORGANIC_EVERY) and it explodes
#   sizes     every animal measures BeeFaunaSizes.SIZE x Bee's length (+-15 %); Bee's length matches BEE_LENGTH
#   mosquito  smooth flight: speed and acceleration bounded while it is not attacking
#   fireflies far ones are body-less light points (GPU, no gravity); the turtle has hexagonal plates + an implant and is freeable
# With a rendering window it saves res://dev/visual_target/noche_liberation_*.png.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/visual_target/"
const ANIMALS := ["Wasp", "Mosquito", "Ladybird", "WaveDragonfly", "Moth", "Ant", "StagBeetle", "Snail", "Spider", "Dragonfly"]
const SIZE_KEYS := {"Mosquito": &"mosquito", "Ladybird": &"ladybird", "WaveDragonfly": &"dragonfly", "Moth": &"moth", "Ant": &"ant",
		"StagBeetle": &"stag_beetle", "Snail": &"snail", "Spider": &"spider"}

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

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "noche_liberation_" + label + ".png"))

func arena(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 3.0, 0)

func clear() -> void:
	for unit in wave.active_units:
		unit.set_physics_process(false)
		unit.queue_free()
	wave.active_units.clear()
	for group in ["alien_projectiles", "ufo_boss_mines", "asset_mines", "bee_liberated_text"]:
		for node in get_nodes_in_group(group):
			node.queue_free()
	BeeAttackTokens.reset()
	await frames(2)

func spawn(family: String, y := 3.6) -> Node3D:
	wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false, "y": y})
	return wave.active_units.back()

static func length_x(node: Node3D) -> float:
	var first := true
	var box := AABB()
	for m: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null or not m.visible or m.name in ["Glow", "Thread", "Column", "Ring"]:
			continue
		if m.get_parent() is WaspImplant or m.find_parent("Implant") != null or m.find_parent("AlienControlDevice") != null:
			continue
		var b: AABB = m.global_transform * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box.size.x

func live_hitboxes(unit: Node) -> int:
	var n := 0
	for area in unit.find_children("*", "Area3D", true, false):
		if area is DamageHitbox3D and (area as DamageHitbox3D).enabled:
			n += 1
	return n

# --- tests -------------------------------------------------------------------------------------------------------

func test_sizes() -> void:
	arena(60.0)
	bee.facing_x = 1.0
	bee.visual_root.rotation.y = -PI * 0.5
	await frames(1)
	var bee_len := length_x(bee.visual_root)
	check(absf(bee_len - BeeFaunaSizes.BEE_LENGTH) / BeeFaunaSizes.BEE_LENGTH < 0.1, "Bee length %.2f m drifted from BEE_LENGTH" % bee_len)
	var lines: Array[String] = []
	for family in SIZE_KEYS:
		var unit := spawn(family)
		unit.set_physics_process(false)
		unit.show()
		unit.rotation = Vector3.ZERO
		if unit is AssetFauna:
			(unit as AssetFauna).rig.rotation.y = 0.0
		await frames(1)
		var ratio := length_x((unit as ControlledSpider)._model if unit is ControlledSpider else unit) / BeeFaunaSizes.BEE_LENGTH # The spider: its body only (no silk).
		var wanted := float(BeeFaunaSizes.SIZE[SIZE_KEYS[family]])
		check(absf(ratio - wanted) / wanted < 0.15, "%s measures %.2f x Bee (wanted %.2f)" % [family, ratio, wanted])
		lines.append("%s %.2f" % [family, ratio])
		await clear()
	report.append("sizes (x Bee): " + ", ".join(lines))

func test_animals() -> void:
	for family in ANIMALS:
		arena(130.0)
		var before := wave.liberated_count
		var unit := spawn(family, 4.0)
		await frames(40)
		var start := unit.global_position
		(unit.get_node("HealthComponent") as HealthComponent).take_damage(99999)
		await frames(3)
		check(is_instance_valid(unit) and unit.is_inside_tree() and unit.visible, "%s must not vanish: it is freed and leaves" % family)
		check(not wave.active_units.has(unit), "%s must stop counting as a threat at once" % family)
		check(wave.liberated_count == before + 1, "%s must count in LIBERADOS" % family)
		check(unit.is_in_group("bee_liberated"), "%s must be marked as freed" % family)
		check(live_hitboxes(unit) == 0, "%s must not hurt anymore (live hitbox)" % family)
		check(not get_nodes_in_group("bee_liberated_text").is_empty() or family == "Dragonfly", "%s: no LIBERADO text" % family)
		if family == "Ant" or family == "Mosquito":
			await capture(family.to_lower())
		await frames(100)
		check(unit.global_position.distance_to(start) > 1.0, "%s must move away after being freed" % family)
		check(live_hitboxes(unit) == 0, "%s hurt while leaving" % family)
		report.append("%s freed (moved %.1f m)" % [family, unit.global_position.distance_to(start)])
		await clear()

func test_tech() -> void:
	arena(130.0)
	var before := wave.liberated_count
	var probe := spawn("Probe", 4.4)
	await frames(10)
	(probe.get_node("HealthComponent") as HealthComponent).take_damage(99999)
	await frames(3)
	check(wave.liberated_count == before and not probe.is_in_group("bee_liberated"), "Technology is not freed")
	await clear()
	var seed := spawn("SeedCarrier", 4.4) as AssetFauna
	await frames(10)
	seed.health.take_damage(99999)
	await frames(3)
	check(wave.liberated_count == before and not seed.is_in_group("bee_liberated"), "The seed carrier explodes, it is not freed")
	await clear()
	var mushroom := spawn("MushroomCannon", -0.2) as AssetFauna
	mushroom.global_position = Vector3(stage.camera.global_position.x + 2.0, -0.2, 0)
	await frames(10)
	mushroom.health.take_damage(99999)
	await frames(70)
	var device := mushroom.visual.find_child("AlienControlDevice", true, false) as Node3D
	check(is_instance_valid(mushroom) and mushroom.visible and mushroom.spent, "The mushroom must stay after its cannon explodes")
	check(device != null and not device.visible, "Only the cannon (device) blows up")
	check(live_hitboxes(mushroom) == 0 and wave.liberated_count == before, "The mushroom is harmless and not a freed animal")
	await capture("mushroom")
	await clear()
	report.append("tech: probe + seed carrier explode, mushroom keeps growing without its cannon")

func test_organism() -> void:
	for event: Dictionary in BeeLevel01Controller.EVENTS:
		check(not ("OrganicAlien" in event["units"]), "OrganicAlien still in a normal event: " + str(event["label"]))
		for zone_wave: Dictionary in event.get("arena", []):
			check(not ("OrganicAlien" in zone_wave["units"]), "OrganicAlien still in a combat zone")
	check(UfoBoss01.ORGANIC_EVERY >= 2, "The UFO must bring the organism every few summons")
	report.append("organism: only as a UFO minion (every %d summons, phases 2-3)" % UfoBoss01.ORGANIC_EVERY)

func test_mosquito_smooth() -> void:
	arena(60.0)
	var unit := spawn("Mosquito", 4.0) as AssetFauna
	unit.max_cycles = 99
	var prev := unit.global_position
	var prev_v := Vector3.ZERO
	var max_speed := 0.0
	var max_accel := 0.0
	var samples := 0
	for i in 400:
		await physics_frame
		bee.global_position.y = 3.0 + 1.5 * sin(float(i) * 0.02)
		var v := (unit.global_position - prev) * 60.0
		prev = unit.global_position
		if unit.state in [AssetFauna.State.IDLE, AssetFauna.State.TELEGRAPH] and i > 60:
			max_speed = maxf(max_speed, v.length())
			if samples > 0:
				max_accel = maxf(max_accel, (v - prev_v).length() * 60.0)
			samples += 1
		else:
			samples = 0
		prev_v = v
	check(max_speed <= AssetFauna.MOSQUITO_SPEED + 0.3, "Mosquito too fast while hovering (%.1f m/s)" % max_speed)
	check(max_accel <= AssetFauna.MOSQUITO_ACCEL * 1.6 + 0.5, "Mosquito jerks while hovering (%.1f m/s2)" % max_accel)
	report.append("mosquito smooth: max %.1f m/s, max accel %.1f m/s2 while hovering" % [max_speed, max_accel])
	await clear()

func test_fireflies_and_turtle() -> void:
	var dressing := stage.get_node("AssetDressing") as BeeLevel01AssetDressing
	check(dressing.far_lights != null and (dressing.far_lights.process_material as ParticleProcessMaterial).gravity == Vector3.ZERO, "Far fireflies must be GPU light points with no gravity")
	check(dressing.far_lights.draw_pass_1 is QuadMesh, "Far fireflies have no body")
	var turtle := BeeAftermathTurtle.new()
	stage.add_child(turtle)
	await frames(2)
	check(turtle.plates >= 12, "Turtle shell needs hexagonal plates (%d)" % turtle.plates)
	check(turtle.implant != null and turtle.legs.size() == 4 and turtle.find_child("Eye", true, false) != null, "Turtle: implant, 4 legs and an eye")
	var animals := wave.animals_total
	wave.register_extra_animal()
	turtle.liberated_now.connect(func(_t): wave.note_extra_liberated())
	var freed := wave.liberated_count
	turtle.health.take_damage(999)
	await frames(2)
	check(turtle.liberated and wave.liberated_count == freed + 1 and wave.animals_total == animals + 1, "The turtle is freed and counted")
	check(wave.liberation_text() == "LIBERADOS %d/%d" % [wave.liberated_count, wave.animals_total], "Liberation text format")
	turtle.queue_free()
	report.append("fireflies far=light points, turtle plates=%d freeable, text '%s'" % [turtle.plates, wave.liberation_text()])

func run() -> void:
	create_timer(600.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	await test_sizes()
	await test_animals()
	await test_tech()
	test_organism()
	await test_mosquito_smooth()
	await test_fireflies_and_turtle()
	for line in report:
		print("LIBERATION ", line)
	print("BEE_LIBERATION_V01_OK")
	quit(0)
