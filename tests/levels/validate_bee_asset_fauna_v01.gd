extends SceneTree

# LOTE 6 — enemies built from the Codex GLB assets (scripts/levels/asset_fauna.gd), integrated in Level 01.
# For each family: it spawns through the Level 01 director, shows a warning >= 0.4 s before anything can hurt, performs ITS attack,
# and the implant (not the animal) is what takes damage and liberates it. Also checks the event table, HP/roles and the toon look.
#   Mosquito (fast, erratic dash) · Ladybird (slow, resistant sweep) · WaveDragonfly (fast sine sweep) · Moth (stationary bombs)
#   Ant (lunge) · StagBeetle (armored charge) · Snail (slow spit) · MushroomCannon (static, telegraphed fan) · SeedCarrier (mini-boss)
# With a rendering window it saves captures in res://dev/visual_target/ (lote6_*.png).
# Dev filter: -- only=mosquito|ladybird|dragonfly|moth|ant|stag|snail|mushroom|seed|static

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/visual_target/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var only := ""
var report: Array[String] = []

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

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "lote6_" + label + ".png"))

func arena(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 3.0, 0)
	bee.facing_x = 1.0

func clear() -> void:
	for unit in wave.active_units + wave.swarm_units:
		unit.set_physics_process(false)
		unit.queue_free()
	wave.active_units.clear()
	wave.swarm_units.clear()
	for group in ["alien_projectiles", "ufo_boss_mines", "asset_mines"]:
		for node in get_nodes_in_group(group):
			node.queue_free()
	BeeAttackTokens.reset()
	await frames(2)

func spawn(family: String, y := 3.6, rel_x := 3.0) -> AssetFauna:
	wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false, "y": y})
	var unit := wave.active_units.back() as AssetFauna
	check(unit != null, "%s is not an AssetFauna" % family)
	unit.global_position = Vector3(stage.camera.global_position.x + rel_x, y if not unit.is_ground() else -0.2, 0)
	return unit

func wait_for(condition: Callable, limit := 600) -> int:
	for i in limit:
		if condition.call():
			return i
		await frames(1)
	return -1

func telegraph_ok(unit: AssetFauna, label: String) -> void:
	var seen := await wait_for(func(): return not unit.telegraphs.is_empty(), 1200)
	check(seen >= 0, "%s never telegraphed/attacked" % label)
	var seconds := unit.telegraphs[0]
	check(seconds >= AssetFauna.MIN_TELEGRAPH - 0.03, "%s telegraph %.2fs < 0.4 s" % [label, seconds])
	report.append("%s telegraph=%.2fs hp=%d" % [label, seconds, unit.health.max_health])

func common_checks(unit: AssetFauna, label: String) -> void:
	check(unit.hurtbox != null and (unit.hurtbox.get_child(0) as CollisionShape3D).shape.get("radius") < 1.3, "%s hurtbox too large" % label)
	check(unit.is_in_group("bee_auto_aim_targets"), "%s must be auto-aim target" % label)
	check(unit.has_meta("level_born"), "%s must be a director-spawned unit" % label)

# --- static data ----------------------------------------------------------------------------------------------

func test_static() -> void:
	var families := ["Mosquito", "Ladybird", "WaveDragonfly", "Moth", "Ant", "StagBeetle", "Snail", "MushroomCannon", "SeedCarrier"]
	for family in families:
		check(BeeLevel01Controller.LEVEL_HP.has(family) and BeeLevel01Controller.ROLES.has(family), "%s missing HP/role" % family)
		check(BeeLevel01Controller.ASSET_FAUNA.has(family), "%s missing scene" % family)
	var used := {}
	var last := -1.0
	for event in BeeLevel01Controller.EVENTS:
		check(float(event["at"]) >= last, "Events must stay sorted by 'at' (%s)" % event["label"])
		last = float(event["at"])
		for unit in event["units"]:
			used[unit] = true
		for wave_def in event.get("arena", []): # LOTE 9: the combat-zone waves are Level 01 events too.
			for unit in wave_def["units"]:
				used[unit] = true
	for family in families:
		check(used.has(family), "%s never appears in the Level 01 events" % family)
	check(float(BeeLevel01Controller.LEVEL_HP["Ladybird"]) >= float(BeeLevel01Controller.LEVEL_HP["Mosquito"]) * 1.8, "Ladybird must be clearly more resistant than the mosquito (LOTE 9: 1.5-2 s vs 0.7 s)")
	check(float(BeeLevel01Controller.LEVEL_HP["Snail"]) >= 90 and float(BeeLevel01Controller.LEVEL_HP["StagBeetle"]) >= 90, "Armored ground units need HP")
	for kind in AssetFauna.KINDS:
		check(float(AssetFauna.KINDS[kind]["telegraph"]) >= AssetFauna.MIN_TELEGRAPH, "%s configured telegraph < 0.4 s" % kind)
	report.append("static: 9 families in events/HP/roles, telegraph config >= 0.4 s")

# --- per family -------------------------------------------------------------------------------------------------

func test_mosquito() -> void:
	arena(60.0)
	var unit := spawn("Mosquito", 4.0)
	common_checks(unit, "Mosquito")
	await frames(30)
	await capture("mosquito_idle")
	var p1 := unit.global_position
	await frames(25)
	var p2 := unit.global_position
	check(p1.distance_to(p2) > 0.2, "Mosquito must move erratically while hovering")
	await telegraph_ok(unit, "Mosquito")
	check(unit.attack_hitbox.enabled, "Mosquito dash must hurt once the warning is over")
	await capture("mosquito_dash")
	await clear()

func test_ladybird() -> void:
	arena(200.0)
	var unit := spawn("Ladybird", 4.4)
	common_checks(unit, "Ladybird")
	await wait_for(func(): return unit.state == AssetFauna.State.TELEGRAPH, 1200)
	await capture("ladybird_warning")
	await telegraph_ok(unit, "Ladybird")
	check(float(unit.telegraphs[0]) >= 0.75, "Ladybird warning is its slow, readable tell (>= 0.75 s)")
	check(unit.health.max_health >= 64, "Ladybird must be resistant (LOTE 9: 1.5-2 s of Base fire)")
	await frames(30)
	await capture("ladybird_sweep")
	await clear()

func test_dragonfly() -> void:
	arena(130.0)
	var unit := spawn("WaveDragonfly", 3.6, 5.2)
	common_checks(unit, "WaveDragonfly")
	await wait_for(func(): return unit.state == AssetFauna.State.TELEGRAPH, 1200)
	await capture("dragonfly_lane")
	await telegraph_ok(unit, "WaveDragonfly")
	var y0 := unit.global_position.y
	await frames(20)
	var y1 := unit.global_position.y
	await frames(10)
	var y2 := unit.global_position.y
	check(absf(y0 - y1) + absf(y1 - y2) > 0.2, "Dragonfly must fly a wave")
	await capture("dragonfly_wave")
	await clear()

func test_moth() -> void:
	arena(260.0)
	var unit := spawn("Moth", 5.0)
	common_checks(unit, "Moth")
	var dropped := await wait_for(func(): return unit.bombs_dropped >= 1, 1200)
	check(dropped >= 0, "Moth never dropped a bomb")
	var mine := get_nodes_in_group("asset_mines")[0] as UfoBossMine
	check(mine.fuse >= 1.5, "Moth bomb fuse must give time to leave")
	await frames(40)
	var parked := mine.global_position
	await frames(30)
	check(mine.global_position.distance_to(parked) < 0.05 and not mine.exploded, "Moth bombs must stay still until they explode")
	check(mine.find_child("WarningRing", true, false) != null, "Moth bomb needs its shrinking warning ring")
	await capture("moth_bomb")
	report.append("moth bomb fuse=%.1fs radius=%.1fm (ring shown from landing)" % [mine.fuse, mine.radius])
	var exploded := await wait_for(func(): return mine.exploded or not is_instance_valid(mine), 240)
	check(exploded >= 0, "Moth bomb must explode")
	await clear()

func test_ant() -> void:
	arena(110.0)
	var unit := spawn("Ant", -0.2, 3.0)
	common_checks(unit, "Ant")
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 1.4, 0)
	await telegraph_ok(unit, "Ant")
	check(unit.attack_hitbox.enabled, "Ant lunge must hurt once the warning is over")
	check(absf(unit.global_position.y + 0.2) < 0.05, "Ant stays on the ground")
	await capture("ant_lunge")
	await clear()

func test_stag() -> void:
	arena(225.0)
	var unit := spawn("StagBeetle", -0.2, 3.0)
	common_checks(unit, "StagBeetle")
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 1.4, 0)
	await wait_for(func(): return unit.state == AssetFauna.State.TELEGRAPH, 1500)
	await capture("stag_warning")
	await telegraph_ok(unit, "StagBeetle")
	check(float(unit.telegraphs[0]) >= 0.75, "Stag beetle charge needs a long warning")
	check(unit.health.max_health >= 100, "Stag beetle is armored (HP)")
	await frames(20)
	await capture("stag_charge")
	await clear()

func test_snail() -> void:
	arena(240.0)
	var unit := spawn("Snail", -0.2, 3.5)
	common_checks(unit, "Snail")
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 1.8, 0)
	var shot := await wait_for(func(): return unit.shots_fired >= 1, 1500)
	check(shot >= 0, "Snail never spat")
	check(unit.telegraphs[0] >= AssetFauna.MIN_TELEGRAPH - 0.03, "Snail spit warned < 0.4 s")
	var orb := get_nodes_in_group("alien_projectiles")[0] as AlienEnemyProjectile
	check(orb.speed <= 5.0, "Snail spit is slow")
	await capture("snail_spit")
	report.append("Snail telegraph=%.2fs spit speed=%.1f" % [unit.telegraphs[0], orb.speed])
	await clear()

func test_mushroom() -> void:
	arena(280.0)
	var unit := spawn("MushroomCannon", -0.2, 3.0)
	common_checks(unit, "MushroomCannon")
	var at := unit.global_position
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 2.4, 0)
	await wait_for(func(): return unit.state == AssetFauna.State.TELEGRAPH, 1500)
	await capture("mushroom_charge")
	await telegraph_ok(unit, "MushroomCannon")
	await wait_for(func(): return unit.shots_fired >= 3, 120)
	check(unit.shots_fired == 3, "Mushroom cannon fires a fan of 3 (%d)" % unit.shots_fired)
	check(unit.global_position.distance_to(at) < 0.01, "Mushroom cannon is static")
	await capture("mushroom_fan")
	await clear()

func test_seed() -> void:
	arena(320.0)
	var unit := spawn("SeedCarrier", 4.4, 4.6)
	common_checks(unit, "SeedCarrier")
	check(unit.health.max_health >= 200, "Seed carrier is a mini-boss")
	await wait_for(func(): return unit.state == AssetFauna.State.TELEGRAPH, 1500)
	await capture("seed_charge")
	await telegraph_ok(unit, "SeedCarrier")
	await wait_for(func(): return unit.shots_fired >= 3, 120)
	check(unit.shots_fired == 3, "Seed carrier fires 3 seed orbs")
	var orbs := get_nodes_in_group("alien_projectiles")
	check(not orbs.is_empty() and (orbs[0] as AlienEnemyProjectile).get_node_or_null("OrbSplitter") != null, "Seed orbs split (AlienOrbSplitter)")
	await capture("seed_orbs")
	await clear()

# --- implant liberation + toon look -------------------------------------------------------------------------------

func test_liberation() -> void:
	arena(60.0)
	var unit := spawn("Mosquito", 4.0)
	var freed := [false]
	unit.liberated_now.connect(func(_u): freed[0] = true)
	# LOTE 9: the body area feeds the implant's health at 1x (it was a separate, never-hurt BodyHealth).
	check(unit.get_node_or_null("BodyHealth") == null and unit.body_hurtbox != null and unit.body_hurtbox.health_component == unit.health \
			and is_equal_approx(unit.body_hurtbox.damage_multiplier, 1.0) and is_equal_approx(unit.hurtbox.damage_multiplier, 2.0), "Body 1x / implant 2x on the same health")
	unit.health.take_damage(9999)
	await frames(2)
	check(freed[0] and unit.liberated and not unit.is_in_group("bee_auto_aim_targets"), "Breaking the implant must liberate the animal")
	var device := unit.visual.find_child("AlienControlDevice", true, false) as Node3D
	check(device != null and not device.visible, "The control device must disappear when liberated")
	var gone := await wait_for(func(): return not wave.active_units.has(unit), 300)
	check(gone >= 0, "A liberated animal stops counting as a threat")
	var machine := spawn("SeedCarrier", 4.4, 4.6)
	machine.health.take_damage(9999)
	await frames(2)
	check(machine.liberated, "The machine (no implant) is destroyed by its own HP")
	await clear()
	report.append("liberation: body 1x + implant 2x on one health, implant break frees the animal, machine dies by HP")

func test_dressing() -> void:
	arena(10.0)
	var dressing := stage.get_node_or_null("AssetDressing") as BeeLevel01AssetDressing
	check(dressing != null, "AssetDressing missing")
	await frames(3)
	var escalation: BeeLevel01AlienEscalation = null
	for node in stage.get_children():
		if node is BeeLevel01AlienEscalation:
			escalation = node
	check(escalation != null and dressing.relays.size() == escalation.pylons.size(), "Every alien pylon must carry a signal relay")
	for pylon in escalation.pylons:
		for part in ["Column", "Ring", "Tip"]:
			check(not (pylon.get_node(part) as Node3D).visible, "Old pylon %s must be hidden under the relay" % part)
	check(dressing.litter.size() >= 12, "Garden litter missing")
	for item in dressing.litter:
		check(item.global_position.z < -2.0, "Litter must stay behind the flight plane (%s)" % item.name)
	check(dressing.find_children("*", "CollisionObject3D", true, false).is_empty(), "Dressing must have no collision")
	check(dressing.fireflies.is_empty() and dressing.far_lights == null, "Level 01 firefly enemies and decoration must be disabled")
	check(dressing.sun != null and dressing.sun.visible, "The toon sun must be visible at the start")
	var sun_meshes := dressing.sun.find_children("*", "MeshInstance3D", true, false)
	check(sun_meshes.size() > 0 and (sun_meshes[0] as MeshInstance3D).get_surface_override_material(0) is ShaderMaterial, "Sun must retain its toon material")
	check(dressing.sun_halo != null, "Sun soft halo missing")
	check(BeeLevel01AssetDressing.sun_screen_y_at(0.0) > BeeLevel01AssetDressing.sun_screen_y_at(180.0), "Sun should climb from low morning to high midday")
	check(BeeLevel01AssetDressing.sun_screen_y_at(300.0) > BeeLevel01AssetDressing.sun_screen_y_at(180.0), "Sun should lower again at sunset")
	check(BeeLevel01AssetDressing.sun_visibility_at(300.0) < BeeLevel01AssetDressing.sun_visibility_at(0.0), "Sun should dim as the moon comes up")
	arena(200.0)
	await frames(3)
	check(dressing.fireflies.is_empty() and not dressing.moon.visible, "Fireflies remain reserved for a future forest level")
	arena(325.0)
	await frames(3)
	check(dressing.moon.visible and dressing.stars[0].visible and not dressing.sun.visible, "Moon/stars must replace the dimmed sun in the final sky")
	await capture("night_sky")
	report.append("dressing: %d relays, %d litter props (z<-2), fireflies disabled, sun->moon sky cycle" % [dressing.relays.size(), dressing.litter.size()])
	arena(60.0)
	await frames(2)

func test_toon() -> void:
	arena(60.0)
	var unit := spawn("Ant", -0.2, 3.0)
	var checked := 0
	for node: MeshInstance3D in unit.visual.find_children("*", "MeshInstance3D", true, false):
		for surface in node.mesh.get_surface_count():
			var material := node.get_surface_override_material(surface)
			if material is ShaderMaterial:
				checked += 1
			else:
				check(false, "Ant mesh %s is not toon" % node.name)
	check(checked > 5, "Ant must use toon materials")
	await clear()

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	if wants("static"):
		test_static()
	for section in [["mosquito", test_mosquito], ["ladybird", test_ladybird], ["dragonfly", test_dragonfly], ["moth", test_moth],
			["ant", test_ant], ["stag", test_stag], ["snail", test_snail], ["mushroom", test_mushroom], ["seed", test_seed]]:
		if wants(section[0]):
			await (section[1] as Callable).call()
	if wants("static"):
		await test_liberation()
		await test_toon()
		await test_dressing()
	for line in report:
		print("ASSET_FAUNA ", line)
	print("BEE_ASSET_FAUNA_V01_OK")
	quit(0)
