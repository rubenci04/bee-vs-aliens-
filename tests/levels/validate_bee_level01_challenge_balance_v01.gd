extends SceneTree

# BEE LEVEL 01 - CHALLENGE & BALANCE PASS 01:
#   * Giant Human SAFE CORRIDOR (real approach, not a teleport): only shoes and torso hurt.
#   * Density: 44-48 enemies in the same 24 events, <=3 per encounter, 3 only late; level-only tuning.
#   * No off-screen fire regression with the tuned cadence.
#   * Spread: 32 bursts, no stacking, pickup/HUD, checkpoint and restart restore.
#   * UFO boss: hurtbox matches the visible saucer, lateral pellets register, Spread is not clearly
#     worse than Base against it; Level Complete still only after the kill.
# With a renderer it saves captures in res://dev/level01_challenge_review/.

## LOTE 9 · ETAPA C: the NODO ALIEN has 1200 HP and 4 phases (was 500 HP, 3 phases).
const BOSS_HP := 1200
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const REVIEW := "res://dev/level01_challenge_review/"
const CORRIDOR_HEIGHTS := [2.6, 3.0, 3.4, 3.8, 4.0]
const LOW_HEIGHTS := [0.9, 1.5]
const START_DISTANCES := [4.0, 8.0]
const OLD_ENEMY_TOTAL := 38

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var human: GiantHumanCrossingHazard
var boss: UfoBoss01
var only := "" # Optional dev filter: -- only=spread (human|density|spread|boss).

func _initialize() -> void:
	BeeLevel01Controller.giant_human_enabled = true # NOCHE 01: the human is off in the game (GIANT_HUMAN_ENABLED); this test covers it.
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

func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW + file) == OK, "Capture failed: " + file)

func bind(value: Node) -> void:
	stage = value as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	human = stage.get_node("GiantHuman") as GiantHumanCrossingHazard

# --- Giant Human -------------------------------------------------------------------------------

func collider(part: String) -> CollisionShape3D:
	return human.get_node("ContactHitbox/" + part)

func reset_human() -> void:
	human.hitbox.set_enabled(false)
	human.visual_root.hide()
	human.set_physics_process(true)
	human.animation_player.stop()
	human.current_phase = GiantHumanCrossingHazard.Phase.EXITED
	await frames(3)

## Bee flies +X at her real speed towards the running human (real animation, real speed 2.6 m/s)
## and keeps going until she has crossed the whole body. Returns the HP lost.
func approach(height: float, start_distance: float) -> int:
	await reset_human()
	bee.health.current_health = bee.health.max_health
	var camera_x := stage.camera.global_position.x
	bee.global_position = Vector3(camera_x + stage.screen_left, height, 0)
	check(human.begin_crossing(stage.camera), "Approach crossing rejected")
	var launched := false
	for i in 1500:
		if not launched and human.global_position.x - camera_x <= start_distance:
			launched = true
		var next_x := camera_x + stage.screen_left
		if launched:
			next_x = minf(bee.global_position.x + bee.horizontal_speed / 60.0, camera_x + stage.screen_right)
		bee.global_position = Vector3(next_x, height, 0)
		await physics_frame
		if launched and bee.global_position.x - human.global_position.x > 6.8:
			break # The whole body (shoes reach +6.2 m) is behind Bee.
		if human.current_phase == GiantHumanCrossingHazard.Phase.EXITED:
			break
	var lost := bee.health.max_health - bee.health.current_health
	await frames(5)
	return lost

## Low corridor: enter at mid height, drop to the ground inside the central column, hold, climb out.
func low_corridor() -> int:
	await reset_human()
	bee.health.current_health = bee.health.max_health
	var camera_x := stage.camera.global_position.x
	var x := camera_x + stage.screen_left
	var y := 3.2
	bee.global_position = Vector3(x, y, 0)
	check(human.begin_crossing(stage.camera), "Low-corridor crossing rejected")
	var phase := 0
	var held := 0.0
	var reached_ground := false
	for i in 1800:
		var step := 1.0 / 60.0
		match phase:
			0:
				if human.global_position.x - camera_x <= 4.0:
					x = minf(x + bee.horizontal_speed * step, camera_x + stage.screen_right)
				if absf(x - human.global_position.x) < 0.5:
					phase = 1
			1:
				x = human.global_position.x
				y = move_toward(y, 0.9, bee.vertical_speed * step)
				if y <= 0.9:
					reached_ground = true
					held += step
					if held > 0.8:
						phase = 2
			2:
				x = human.global_position.x
				y = move_toward(y, 3.2, bee.vertical_speed * step)
				if y >= 3.2:
					phase = 3
			3:
				x += bee.horizontal_speed * step
				if x - human.global_position.x > 6.8:
					break
		bee.global_position = Vector3(x, y, 0)
		await physics_frame
		if human.current_phase == GiantHumanCrossingHazard.Phase.EXITED:
			break
	check(reached_ground, "Low-corridor trial never reached the ground inside the legs")
	var lost := bee.health.max_health - bee.health.current_health
	await frames(5)
	return lost

func freeze_pose(seek: float) -> void:
	check(human.begin_crossing(stage.camera), "Pose crossing rejected")
	for i in 100:
		if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING:
			break
		bee.global_position = Vector3(human.global_position.x, 3.4, 0)
		await frames(1)
	human.animation_player.seek(seek, true)
	human.animation_player.advance(0.0)
	human._physics_process(0.0)
	human.set_physics_process(false)
	human.animation_player.pause()
	await frames(2)

func test_human() -> void:
	stage.scroll_speed = 0.0
	stage.distance = 140.0
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	await frames(3)
	check(is_equal_approx(human.crossing_speed, 2.6) and is_equal_approx(human.second_crossing_speed, 2.4), "Human speed changed")
	check(human.hitbox.damage == 20, "Human damage is not 20")
	check(human.find_children("*", "HealthComponent", true, false).is_empty() and human.find_children("*", "DamageHurtbox3D", true, false).is_empty(), "Human became shootable")
	check(human.hitbox.get_node_or_null("LeftThigh") == null and human.hitbox.get_node_or_null("LeftLeg") == null, "Legs above the shoes must not be damage shapes")

	# 1. The mid-height corridor between the shoes and the pelvis: real approaches, never hurt.
	var safe := 0
	var total := 0
	for height in CORRIDOR_HEIGHTS:
		for start in START_DISTANCES:
			total += 1
			if await approach(height, start) == 0:
				safe += 1
			else:
				push_warning("Corridor crossing damaged Bee at y=%.1f start=%.0f" % [height, start])
	check(float(safe) / float(total) >= 0.95, "Visual corridor crossings without damage: %d/%d" % [safe, total])
	# 2. Low flight can meet a shoe, but only a shoe, and only once per crossing.
	var low_hits := 0
	for height in LOW_HEIGHTS:
		for start in START_DISTANCES:
			var lost := await approach(height, start)
			check(lost == 0 or lost == 20, "Low crossing lost %d HP (one 20 HP hit per crossing max)" % lost)
			low_hits += 1 if lost > 0 else 0
	check(await low_corridor() == 0, "The ground-level corridor between the legs damaged Bee")
	# 3. Wide stride: shoes outside the central column, torso above the visible gap, nothing in between.
	await reset_human()
	await freeze_pose(0.2)
	var column := float((human.get_script() as GDScript).get_script_constant_map()["SAFE_HALF_WIDTH"])
	var shoes := 0
	for part in ["LeftFoot", "RightFoot"]:
		if collider(part).disabled:
			continue
		shoes += 1
		for point in (collider(part).shape as ConvexPolygonShape3D).points:
			check(absf((collider(part).global_transform * point).x - human.global_position.x) >= column - 0.01, part + " reaches into the central corridor")
	check(shoes == 2, "Wide-stride pose lost a shoe envelope")
	var torso_bottom := 99.0
	for point in (collider("Torso").shape as ConvexPolygonShape3D).points:
		torso_bottom = minf(torso_bottom, (collider("Torso").global_transform * point).y)
	check(torso_bottom > 4.3, "Torso envelope hangs into the visible gap (bottom y=%.2f)" % torso_bottom)
	var hp := bee.health.current_health
	bee.global_position = Vector3(human.global_position.x, 3.4, 0)
	await frames(30)
	check(bee.health.current_health == hp, "Bee in the gap between the legs was damaged")
	if DisplayServer.get_name() != "headless":
		var debug := stage.get_node("HumanHitboxDebug") as GiantHumanHitboxDebug
		debug.set_viewing(true)
		stage.distance = human.global_position.x # The stage re-frames the camera on stage.distance every step.
		stage._update_camera_and_bounds()
		bee.global_position = Vector3(human.global_position.x, 3.4, 0)
		await frames(3)
		await capture("01_human_safe_corridor.png")
		debug.set_viewing(false)
		stage.distance = 140.0
		stage._update_camera_and_bounds()
	await reset_human()
	# 4. Shoes and torso still cost exactly 20 HP, once per crossing; flying into the pelvis is damage.
	for part in ["LeftFoot", "RightFoot", "Torso"]:
		await freeze_pose(0.2)
		var node := collider(part)
		check(not node.disabled, "Contact envelope absent for " + part)
		bee.health.current_health = bee.health.max_health
		bee.global_position = node.global_position
		hp = bee.health.current_health
		await frames(20)
		check(bee.health.current_health == hp - 20, part + " must cost exactly 20 HP")
		await frames(20)
		check(bee.health.current_health == hp - 20, part + " repeated damage during the same crossing")
		await reset_human()
	print("CHALLENGE_HUMAN corridor_safe=%d/%d low_crossings_hit=%d/%d low_corridor_via_centre=OK" % [safe, total, low_hits, LOW_HEIGHTS.size() * START_DISTANCES.size()])

# --- Density and tuning --------------------------------------------------------------------------

func test_density() -> void:
	var events := BeeLevel01Controller.EVENTS
	var total := 0
	var biggest := 0
	var triples := 0
	for event: Dictionary in events:
		var count: int = event["units"].size()
		var threats: int = (event["units"] as Array).filter(func(f): return f != "Swarm").size() # Popcorn is outside the threat cap.
		total += count
		biggest = maxi(biggest, threats)
		if count >= 3:
			triples += 1 # Challenge pass: last third only; Arcade Pressure pass relaxed this (see its own test).
		for zone_wave: Dictionary in event.get("arena", []): # LOTE 9: zone waves count in the budget.
			total += (zone_wave["units"] as Array).size()
	check(events.size() == 59, "Encounter count changed (LOTE 9: 38, was 56)")
	check(total >= 90 and total <= 110, "Unit total %d outside 90-110 (LOTE 9, zones included)" % total)
	check(biggest <= 4, "An encounter has more than 4 threats")
	check(float(events.back()["at"]) <= 340.0 and float(events[0]["at"]) >= 4.0, "Timeline thresholds changed")
	for family in BeeLevel01Controller.LEVEL_HP:
		if family == "OrganicAlien":
			continue # NOCHE 01: UFO minion only.
		var found := false
		for event: Dictionary in events:
			found = found or family in event["units"]
			for zone_wave: Dictionary in event.get("arena", []): # LOTE 9: some families only appear in a combat zone.
				found = found or family in zone_wave["units"]
		check(found, "Family missing from the timeline: " + family)
	# The level-only HP table is untouched; only the two cadences changed, on level spawns.
	check(_base_hp() == {"Wasp": 36, "Probe": 70, "EyeDrone": 50, "Turret": 70, "Speeder": 40, "OrganicAlien": 100, "Walker": 100, "Dragonfly": 110, "Swarm": 10, "Spider": 80}, "Level enemy HP changed (LOTE 9 table)")
	check(BeeLevel01Controller.LEVEL_TUNING.has("Probe") and BeeLevel01Controller.LEVEL_TUNING.has("EyeDrone"), "Level tuning table lost Probe/EyeDrone")
	var probe_scene := (load("res://scenes/bee_prototype/alien_probe_ranged.tscn") as PackedScene).instantiate()
	var eye_scene := (load("res://scenes/bee_prototype/eye_drone_enemy.tscn") as PackedScene).instantiate()
	check(is_equal_approx(probe_scene.cooldown_time, 1.25) and is_equal_approx(eye_scene.cooldown_time, 1.4), "Reusable enemy scenes were modified")
	probe_scene.free()
	eye_scene.free()
	for family in ["Probe", "EyeDrone"]:
		wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false})
		var unit: Node3D = wave.active_units.back()
		check(is_equal_approx(unit.cooldown_time, BeeLevel01Controller.LEVEL_TUNING[family]["cooldown_time"]), family + " tuning not applied to the level spawn")
		check(unit.get_node("HealthComponent").max_health == int(BeeLevel01Controller.LEVEL_HP[family]), family + " HP changed")
		wave.active_units.erase(unit)
		unit.queue_free()
	print("CHALLENGE_DENSITY enemies=%d events=%d biggest_encounter=%d triples=%d" % [total, events.size(), biggest, triples])

func test_offscreen_fire() -> void:
	var camera_x := stage.camera.global_position.x
	for family in ["Probe", "EyeDrone", "Turret"]:
		wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false})
		var unit: Node3D = wave.active_units.back()
		unit.set_physics_process(false)
		var shots_before := get_nodes_in_group("alien_projectiles").size()
		unit.global_position = Vector3(camera_x + 12.0, 4.0, 0)
		if unit is EyeDroneEnemy:
			unit._shoot_at_bee()
		else:
			unit._shoot()
		await frames(1)
		check(get_nodes_in_group("alien_projectiles").size() == shots_before, family + " fired from outside the screen")
		check(int(unit.suppressed_shot_count) == 1, family + " off-screen shot was not suppressed")
		unit.global_position = Vector3(camera_x + 1.0, 4.0, 0)
		if unit is EyeDroneEnemy:
			unit._shoot_at_bee()
		else:
			unit._shoot()
		await frames(1)
		check(get_nodes_in_group("alien_projectiles").size() >= shots_before + 1, family + " must still fire when readable (Turret fires a fan)")
		wave.active_units.erase(unit)
		unit.queue_free()
	for shot in get_nodes_in_group("alien_projectiles"):
		shot.queue_free()
	await frames(2)
	print("CHALLENGE_OFFSCREEN_FIRE OK tuned_probe_eye_turret")

# --- Spread ---------------------------------------------------------------------------------------

func test_spread() -> void:
	bee.set_physics_process(false)
	stage.scroll_speed = 0.0
	bee.health.current_health = bee.health.max_health
	check(bee.spread_max_shots == 32 and bee.spread_ammo == 0, "Spread capacity/initial state wrong")
	var pickup := stage.get_node("Powerups/SpreadFirst") as Area3D
	stage.distance = pickup.global_position.x - 2.0 # The flight window follows stage.distance and would drag Bee back.
	stage._update_camera_and_bounds()
	bee.global_position = pickup.global_position
	await frames(5)
	check(bee.spread_ammo == 32 and "SPREAD x32" in stage.get_node("CanvasLayer/WeaponsHUD/State").text, "Spread pickup/HUD wrong: ammo=%d hud=%s" % [bee.spread_ammo, stage.get_node("CanvasLayer/WeaponsHUD/State").text])
	var central := bee.fire()
	check(bee.spread_ammo == 31 and central != null, "A burst must consume exactly one charge")
	var burst := 0
	for node in stage.find_children("*", "Node3D", false, false):
		if node is BeeEnergyProjectile:
			burst += 1
			check((node as BeeEnergyProjectile).damage == 8, "Spread pellet damage is not 8")
	check(burst == 3, "Spread must still fire 3 projectiles")
	check(bee.collect_spread() and bee.spread_ammo == 32, "Refill must cap at 32 (no stacking)")
	check(bee.collect_spread() and bee.spread_ammo == 32, "Second refill stacked ammo")
	for node in stage.find_children("*", "Node3D", false, false):
		if node is BeeEnergyProjectile:
			node.queue_free()
	for i in 32:
		bee.fire()
		await frames(1)
	check(bee.spread_ammo == 0 and "BASE" in stage.get_node("CanvasLayer/WeaponsHUD/State").text, "Ammo exhaustion failed")
	check(bee.fire().damage == 10, "No automatic return to Base")
	print("CHALLENGE_SPREAD ammo=32 pellets=3x8 refill_cap=OK")

func reloaded(old: Node) -> void:
	for i in 120:
		await process_frame
		if current_scene != null and current_scene != old and current_scene.is_node_ready():
			break
	await frames(3)

func test_checkpoint_and_restart() -> void:
	bee.spread_ammo = 17
	bee.bomb_charges = 2
	stage.distance = 190.05
	stage.checkpoint.activate_checkpoint()
	check(stage.checkpoint.snapshot["spread"] == 17, "Checkpoint did not snapshot the Spread charges")
	bee.spread_ammo = 3 # Spent after the checkpoint; a respawn must restore the snapshot.
	var old_stage := stage
	stage.checkpoint.restart_level(false)
	await reloaded(old_stage)
	bind(current_scene)
	check(stage != old_stage and bee.spread_ammo == 17 and bee.spread_max_shots == 32, "Checkpoint respawn did not restore 17 Spread charges")
	check("SPREAD x17" in stage.get_node("CanvasLayer/WeaponsHUD/State").text, "HUD not restored after the checkpoint")
	var snapshot_stage := stage
	stage.checkpoint.restart_level(true)
	await reloaded(snapshot_stage)
	bind(current_scene)
	check(stage != snapshot_stage and bee.spread_ammo == 0 and bee.bomb_charges == 1, "Full restart did not restore the initial kit")
	check(stage.get_node("Powerups").get_child_count() == 5, "Full restart did not restore the pickups (REBUILD 02: incl. the S+ capsule)")
	print("CHALLENGE_RESTORE checkpoint_spread=17 restart_spread=0")

# --- UFO boss, large target -----------------------------------------------------------------------

func follow(gap: float, delta: float) -> void:
	var wanted_y := clampf(boss.global_position.y, bee.flight_min.y, bee.flight_max.y)
	bee.global_position.x = boss.global_position.x - gap
	bee.global_position.y = move_toward(bee.global_position.y, wanted_y, bee.vertical_speed * delta * 0.8)
	bee.facing_x = 1.0

func dps(gap: float, spread: bool, shot := "") -> float:
	boss.health.current_health = boss.health.max_health
	if spread:
		bee.collect_spread()
	else:
		bee.spread_ammo = 0
	var time := 0.0
	var next := 0.0
	var shot_taken := shot.is_empty()
	while time < 8.0:
		follow(gap, 1.0 / 60.0)
		if time >= next:
			bee.fire()
			next += 1.0 / 3.3
		await physics_frame
		time += 1.0 / 60.0
		if not shot_taken and time > 2.0:
			shot_taken = true
			await capture(shot)
	await frames(70)
	return float(boss.health.max_health - boss.health.current_health) / 8.0

func test_boss() -> void:
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	stage.distance = 352.0
	stage._update_camera_and_bounds()
	for i in 900:
		await physics_frame
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			break
	boss = wave.boss
	check(boss != null and boss.state == UfoBoss01.State.PHASE_1, "Boss did not reach phase 1")
	check(boss.max_hp == BOSS_HP and is_equal_approx(UfoBoss01.APPROACH_SECONDS, 3.2), "Boss HP/approach changed (out of scope)")
	# The hurtbox lives inside the visible saucer.
	var shape_node := boss.hurtbox.get_node("CollisionShape3D") as CollisionShape3D
	# The saucer spins about Y: use radial extents (rotation-proof) and the exact vertical extents.
	var visible_box := AABB()
	var first := true
	var hull_width := 0.0
	var scale_factor := boss.visual_root.scale.x
	for mesh: MeshInstance3D in boss.visual_root.find_children("*", "MeshInstance3D", false, false):
		var local := mesh.get_aabb()
		var centre := mesh.global_position
		var radius := maxf(maxf(absf(local.position.x), absf(local.end.x)), maxf(absf(local.position.z), absf(local.end.z))) * scale_factor
		var bounds := AABB(Vector3(centre.x - radius, centre.y + local.position.y * scale_factor, -1.0), Vector3(radius * 2.0, local.size.y * scale_factor, 2.0))
		visible_box = bounds if first else visible_box.merge(bounds)
		first = false
		if mesh.name == "Hull":
			hull_width = radius * 2.0
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for point in (shape_node.shape as ConvexPolygonShape3D).points:
		var world: Vector3 = shape_node.global_transform * point
		check(world.x >= visible_box.position.x and world.x <= visible_box.end.x and world.y >= visible_box.position.y and world.y <= visible_box.end.y, "Hurtbox leaves the visible silhouette")
		low = low.min(Vector2(world.x, world.y))
		high = high.max(Vector2(world.x, world.y))
	check(high.x - low.x >= hull_width * 0.9 and high.y - low.y >= 1.0, "Hurtbox is smaller than the visible hull (w=%.2f h=%.2f)" % [high.x - low.x, high.y - low.y])
	# Horizontal pellets that cross the visible hull register; those that pass clear of it do not.
	boss.set_physics_process(false)
	boss.health.max_health = 100000
	await frames(2)
	for entry in [[0.3, true], [-0.3, true], [1.0, true], [1.6, false], [-1.5, false]]: # Boss doubled in size (batch 4): offsets scaled.
		boss.health.current_health = boss.health.max_health
		bee.global_position = Vector3(boss.global_position.x - 3.0, boss.global_position.y + float(entry[0]), 0)
		bee.facing_x = 1.0
		var pellet := bee._spawn_projectile(Vector3.RIGHT)
		await frames(30)
		var hit := boss.health.current_health < boss.health.max_health
		check(hit == bool(entry[1]), "Lateral pellet at dy=%.2f %s" % [float(entry[0]), "must register" if bool(entry[1]) else "must pass clear"])
		if is_instance_valid(pellet):
			pellet.queue_free()
	# Spread against a large target is not clearly worse than Base.
	boss.set_physics_process(true)
	var report := []
	for gap in [3.0, 6.0]:
		var base := await dps(gap, false)
		var spread := await dps(gap, true, "02_spread_vs_ufo.png" if gap == 3.0 else "")
		report.append("%.0fm base=%.1f spread=%.1f" % [gap, base, spread])
		if gap == 3.0:
			check(spread >= base * 1.2, "Spread at 3 m should beat Base (%.1f vs %.1f)" % [spread, base])
		else:
			check(spread >= base * 0.75, "Spread at 6 m is clearly worse than Base (%.1f vs %.1f)" % [spread, base])
	print("CHALLENGE_BOSS_SPREAD ", " | ".join(report))
	# Level Complete only after the kill.
	boss.health.current_health = boss.health.max_health
	bee.global_position = Vector3(stage.distance - 3.0, 7.0, 0)
	check(not stage.sector_complete, "Level complete before the boss died")
	boss.health.take_damage(boss.health.max_health)
	for i in 900:
		await physics_frame
		bee.global_position.y = 7.0
		if stage.sector_complete:
			break
	check(stage.sector_complete and stage.status.text.begins_with("SECTOR DESPEJADO") and wave.boss_defeated, "Level Complete missing after the boss died")
	await capture("03_level_complete.png")
	print("CHALLENGE_LEVEL_COMPLETE OK")

func run() -> void:
	create_timer(540.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	bind(current_scene)
	if wants("human"):
		await test_human()
	if wants("density"):
		test_density()
		await test_offscreen_fire()
	if wants("spread"):
		await test_spread()
		await test_checkpoint_and_restart()
	if wants("boss"):
		await test_boss()
	print("BEE_LEVEL01_CHALLENGE_BALANCE_V01_OK")
	quit(0)

## LOTE 6: the original ten families keep their HP; the Codex fauna has its own table (validate_bee_asset_fauna_v01).
func _base_hp() -> Dictionary:
	var result := {}
	for family in ["Wasp", "Probe", "EyeDrone", "Turret", "Speeder", "OrganicAlien", "Walker", "Dragonfly", "Swarm", "Spider"]:
		result[family] = BeeLevel01Controller.LEVEL_HP[family]
	return result
