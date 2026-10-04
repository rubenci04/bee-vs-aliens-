extends SceneTree

# BEE ARCADE PRESSURE + WORLD INTERACTION PASS 01:
#   Wasp   : stalk (presence) -> telegraph -> locked pass (no homing) -> recovery -> second pass -> exit.
#   Ranged : Probe/EyeDrone hold the right side, advance slowly and fire bursts; off-screen fairness; projectile safety.
#   Rocks  : small/medium flight rocks break with Base, Spread and Bomb; the tall rock at X=205 is structural;
#            checkpoint / restart; enemy fire neither damages rocks nor uses them as cover.
#   Level  : enemy total, quiet-event structure, UFO unchanged, Level Complete only after the kill.
# With a renderer it saves captures in res://dev/arcade_pressure_review/.
# Dev filter: -- only=wasp|ranged|rocks|level

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const REVIEW := "res://dev/arcade_pressure_review/"
const RANGED := ["Probe", "EyeDrone", "Turret", "Walker"]
const SMALL_ROCKS := [72, 155, 241, 283, 345]
const MEDIUM_ROCKS := [96, 307]
const STRUCTURAL_ROCK := 205

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

func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW + file) == OK, "Capture failed: " + file)

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

func camera_x() -> float:
	return stage.camera.global_position.x

## A quiet arena: scroll stopped, level controller off, Bee parked on the left half.
func arena(distance: float, bee_y := 3.5) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.current_health = bee.health.max_health
	bee.health.damage_blocked = false
	bee.global_position = Vector3(camera_x() - 3.0, bee_y, 0)
	bee.facing_x = 1.0

func spawn(family: String, slot := 0) -> Node3D:
	wave._spawn({"family": family, "slot": slot, "event": 0, "hard": false})
	var unit: Node3D = wave.active_units.back()
	return unit

func clear_units() -> void:
	for unit in wave.active_units.duplicate():
		wave.active_units.erase(unit)
		unit.queue_free()
	for shot in get_nodes_in_group("alien_projectiles"):
		shot.queue_free()
	await frames(2)

# --- Wasp ----------------------------------------------------------------------------------------

func wasp_trace() -> Dictionary:
	await clear_units()
	arena(60.0)
	bee.health.damage_blocked = true
	var wasp := spawn("Wasp") as WaspEnemy
	check(wasp.arcade_mode, "Level 01 Wasp must use the arcade behaviour")
	var timeline := {}   # state -> seconds
	var order: Array = []
	var near_frames := 0
	var total := 0
	var stalk_first := 0.0
	var stalk_closest := INF
	var stalk_farthest := 0.0
	var windup_telegraph := true
	var windup_frames := 0
	var dash_dirs: Array[Vector3] = []
	var recovery_gain := 0.0
	var captured_hover := false
	var captured_dash := false
	for i in 60 * 24:
		await physics_frame
		if not is_instance_valid(wasp):
			break
		var state: int = wasp.current_state
		if order.is_empty() or order.back() != state:
			order.append(state)
		timeline[state] = float(timeline.get(state, 0.0)) + 1.0 / 60.0
		total += 1
		var distance := Vector2(wasp.global_position.x - bee.global_position.x, wasp.global_position.y - bee.global_position.y).length()
		if distance < 1.2:
			near_frames += 1
		if state == WaspEnemy.State.STALK:
			if order.count(WaspEnemy.State.STALK) == 1:
				stalk_first += 1.0 / 60.0
				if stalk_first > 1.2:
					stalk_closest = minf(stalk_closest, distance)
					stalk_farthest = maxf(stalk_farthest, distance)
			if stalk_first > 1.4 and not captured_hover:
				captured_hover = true
				await capture("01_wasp_hover.png")
		elif state == WaspEnemy.State.WINDUP:
			windup_frames += 1
			windup_telegraph = windup_telegraph and wasp.telegraph.visible
		elif state == WaspEnemy.State.DASH:
			dash_dirs.append(wasp.velocity.normalized())
			if not captured_dash and dash_dirs.size() == 12:
				captured_dash = true
				await capture("02_wasp_attack_pass.png")
		if wasp.current_state == WaspEnemy.State.EXIT and distance > 9.0:
			break
	check(order.has(WaspEnemy.State.STALK) and order.has(WaspEnemy.State.WINDUP) and order.has(WaspEnemy.State.DASH), "Wasp skipped stalk/telegraph/pass: " + str(order))
	check(order.count(WaspEnemy.State.DASH) == 3 and wasp.passes_done == 3, "Wasp must make exactly three passes (%d)" % wasp.passes_done)
	check(order.back() == WaspEnemy.State.EXIT or wasp.current_state == WaspEnemy.State.EXIT, "Wasp must exit after its passes")
	check(stalk_first >= 1.5 and stalk_first <= 3.8, "First stalk should last 1.5-3.8 s on screen, got %.2f" % stalk_first)
	check(stalk_closest >= 3.0 and stalk_farthest <= 6.6, "Stalk distance out of 3.0-6.6 m: %.2f..%.2f" % [stalk_closest, stalk_farthest])
	check(windup_telegraph and float(windup_frames) / 180.0 >= 0.5, "Pass telegraph too short/invisible (%.2f s per pass)" % (float(windup_frames) / 180.0))
	# No homing: the direction of each pass is constant for the whole dash.
	var first := dash_dirs[0]
	for direction in dash_dirs:
		check(direction.dot(first) > 0.98 or direction.dot(dash_dirs[dash_dirs.size() / 2]) > 0.98, "Pass direction changed mid-dash (homing)")
	check(float(near_frames) / float(total) <= 0.18, "The Wasp stays on top of Bee (%.0f %% of the time)" % (100.0 * near_frames / total))
	var stalk_total := float(timeline.get(WaspEnemy.State.STALK, 0.0))
	print("ARCADE_WASP order=%s first_stalk=%.2fs stalk_dist=%.1f..%.1f windup=%.2fs passes=%d near_bee=%.0f%%" % [str(order), stalk_first, stalk_closest, stalk_farthest, float(windup_frames) / 180.0, wasp.passes_done, 100.0 * near_frames / total])
	check(stalk_total >= 2.5, "Wasp presence too short")
	await clear_units()
	return {}

## Returns the HP lost: `dodge` moves Bee out of the locked line as soon as the telegraph starts.
func wasp_pass(dodge: bool) -> int:
	await clear_units()
	arena(60.0)
	var wasp := spawn("Wasp") as WaspEnemy
	var start_hp := bee.health.current_health
	var windup_seen := false
	var dodged := false
	for i in 60 * 10:
		await physics_frame
		if wasp.current_state == WaspEnemy.State.WINDUP:
			windup_seen = true
			if dodge and not dodged:
				dodged = true
				bee.global_position = Vector3(camera_x() - 3.0, 1.0, 0) # 2.5 m below the locked line
		if windup_seen and wasp.current_state == WaspEnemy.State.RECOVERY:
			break
	check(windup_seen, "Wasp never telegraphed a pass")
	var lost := start_hp - bee.health.current_health
	await clear_units()
	return lost

func test_wasp() -> void:
	await wasp_trace()
	var hit := await wasp_pass(false)
	check(hit == 10, "A pass that reaches Bee must cost exactly 10 HP once (got %d)" % hit)
	var dodged := await wasp_pass(true)
	check(dodged == 0, "A pass must be dodgeable by leaving the locked line (lost %d)" % dodged)
	print("ARCADE_WASP_PASS hit=%d dodged=%d" % [hit, dodged])

# --- Ranged ---------------------------------------------------------------------------------------

func test_ranged() -> void:
	var burst := int(BeeLevel01Controller.LEVEL_TUNING["Probe"]["burst_shots"])
	check(burst == 4 and BeeLevel01Controller.LEVEL_TUNING["EyeDrone"]["burst_shots"] == 4, "Burst tuning missing (REBUILD 02: 4)")
	for family in ["Probe", "EyeDrone"]:
		var scene := (load("res://scenes/bee_prototype/alien_probe_ranged.tscn" if family == "Probe" else "res://scenes/bee_prototype/eye_drone_enemy.tscn") as PackedScene).instantiate()
		check(int(scene.burst_shots) == 1 and float(scene.advance_speed) == 0.0, "Base scene of %s was changed" % family)
		scene.free()
	# HOLD / SLOW ADVANCE / FIRE (burst) with the real AI, Bee parked on the left.
	await clear_units()
	arena(100.0)
	bee.health.damage_blocked = true
	var probe := spawn("Probe") as AlienProbeRanged
	var launches: Array[int] = []
	var distances: Array[float] = []
	var offsets: Array[float] = []
	probe.projectile_fired.connect(func(_shot):
		launches.append(Engine.get_physics_frames())
		distances.append(Vector2(probe.global_position.x - bee.global_position.x, probe.global_position.y - bee.global_position.y).length())
		offsets.append(probe.global_position.x - camera_x()))
	var captured := false
	for i in 60 * 11:
		await physics_frame
		if not captured and launches.size() >= 1:
			captured = true
			await capture("03_ranged_holding_right_side.png")
	check(launches.size() >= burst + 1, "Probe fired only %d shots in 11 s" % launches.size())
	check(launches[1] - launches[0] >= 9 and launches[1] - launches[0] <= 15, "Burst gap wrong: %d frames" % (launches[1] - launches[0]))
	check(offsets[0] >= 3.0, "Probe does not hold the right side (x=%+.1f from the centre)" % offsets[0])
	var cycle := float(launches[burst] - launches[0]) / 60.0 # First shot of burst 1 -> first shot of burst 2 (windup + burst + short recovery)
	check(cycle >= 1.2 and cycle <= 2.2, "Probe burst-to-burst time %.2f s outside 1.2-2.2 s" % cycle)
	check(distances[distances.size() - 1] < distances[0] - 0.3 and distances[distances.size() - 1] >= 4.5, "Probe must advance slowly but stay out of melee (%.1f -> %.1f m)" % [distances[0], distances[distances.size() - 1]])
	print("ARCADE_PROBE shots_in_11s=%d burst_gap=%d frames cycle=%.2fs hold_x=%+.1f advance=%.1f->%.1f m" % [launches.size(), launches[1] - launches[0], cycle, offsets[0], distances[0], distances[distances.size() - 1]])
	await clear_units()
	# Off-screen fairness with bursts: no shot while the enemy is outside the readable area.
	for family in ["Probe", "EyeDrone"]:
		var unit := spawn(family)
		unit.set_physics_process(false)
		unit.global_position = Vector3(camera_x() + 12.0, 4.0, 0)
		var before := get_nodes_in_group("alien_projectiles").size()
		if unit is EyeDroneEnemy:
			unit._shoot_at_bee()
		else:
			unit._shoot()
		unit.set_physics_process(true)
		unit.global_position = Vector3(camera_x() + 12.0, 4.0, 0)
		await frames(30)
		unit.global_position = Vector3(camera_x() + 12.0, 4.0, 0)
		check(get_nodes_in_group("alien_projectiles").size() == before, family + " fired a burst from outside the screen")
		check(int(unit.suppressed_shot_count) >= 1, family + " suppressed no shots")
		await clear_units()
	# Projectile safety: several ranged enemies at once never exceed the arcade ceiling (no bullet hell).
	await clear_units()
	arena(100.0)
	bee.health.damage_blocked = true
	for family in ["Probe", "EyeDrone", "Probe"]:
		spawn(family, wave.active_units.size())
	await frames(20)
	var peak := 0
	var captured_many := false
	for i in 60 * 10:
		await physics_frame
		peak = maxi(peak, get_nodes_in_group("alien_projectiles").size())
		if not captured_many and get_nodes_in_group("alien_projectiles").size() >= 3:
			captured_many = true
			await capture("04_multiple_ranged_pressure.png")
	check(peak >= 3 and peak <= 14, "Hostile projectile peak %d outside the arcade range 3-14" % peak)
	print("ARCADE_RANGED_PEAK three_ranged_peak_shots=%d" % peak)
	await clear_units()

# --- Rocks ----------------------------------------------------------------------------------------

func rock(x: int) -> BreakableRock:
	return stage.get_node("Scenery/FlightRock%d" % x) as BreakableRock

func rock_arena(x: int, gap: float, from_right := false) -> BreakableRock:
	var target := rock(x)
	arena(float(x) - 4.0)
	bee.health.damage_blocked = true
	var side := 1.0 if from_right else -1.0
	bee.global_position = Vector3(float(x) + side * gap, target.collider.global_position.y, 0)
	bee.facing_x = -side
	return target

func shoot_until_broken(target: BreakableRock, limit: int) -> int:
	var shots := 0
	while not target.is_destroyed and shots < limit:
		bee._spawn_projectile(Vector3(bee.facing_x, 0.0, 0.0))
		shots += 1
		await frames(24)
	return shots

func blocks_bee(target: BreakableRock) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = bee.get_node("CollisionShape3D").shape
	query.transform = Transform3D(Basis.IDENTITY, target.collider.global_position)
	query.collision_mask = 1
	query.exclude = [bee.get_rid()]
	for hit in bee.get_world_3d().direct_space_state.intersect_shape(query):
		if hit["collider"] == target:
			return true
	return false

func has_effect(kind: StringName) -> bool:
	for effect in get_nodes_in_group("bee_combat_vfx"):
		if (effect as BeeCombatVFX).kind == kind:
			return true
	return false

func test_rocks() -> void:
	var rocks := get_nodes_in_group("breakable_rocks")
	check(rocks.size() == 8, "Expected 8 flight rocks, got %d" % rocks.size())
	var structural := 0
	for node in rocks:
		var r := node as BreakableRock
		if r.structural:
			structural += 1
		else:
			check(r.health.max_health in [32, 64], "Unexpected rock HP %d" % r.health.max_health)
	check(structural == 1 and rock(STRUCTURAL_ROCK).structural, "Exactly the X=205 rock must be structural")
	for x in SMALL_ROCKS:
		check(rock(x).health.max_health == 32, "Small rock HP at %d" % x)
	for x in MEDIUM_ROCKS:
		check(rock(x).health.max_health == 64, "Medium rock HP at %d" % x)
	# Base: 4 shots (~0.9 s of sustained fire) for a small rock, 7 (~1.8 s) for a medium one.
	var small := rock_arena(72, 3.0)
	check(blocks_bee(small), "The rock must obstruct before it breaks")
	bee._spawn_projectile(Vector3.RIGHT)
	await frames(24)
	check(small.health.current_health == 22 and has_effect(&"rock_hit"), "A Base hit must take 10 HP and show rock dust")
	await capture("05_rock_taking_damage.png")
	var shots := 1 + await shoot_until_broken(small, 8)
	check(small.is_destroyed and shots == 4, "A small rock must break with 4 Base shots (took %d)" % shots)
	var sustained := float(shots - 1) / 3.3
	check(not blocks_bee(small) and small.collider.disabled and small.collision_layer == 0, "A broken rock must not block Bee")
	check(not small.hurtbox.monitorable, "A broken rock must stop being a target")
	var meshes_hidden := true
	for mesh: MeshInstance3D in small.find_children("*", "MeshInstance3D", true, false):
		meshes_hidden = meshes_hidden and not mesh.visible
	check(meshes_hidden, "A broken rock must hide its mesh")
	check(has_effect(&"rock_break"), "No break VFX")
	var crate_voice := false
	for voice in get_nodes_in_group("bee_audio_voice"):
		crate_voice = crate_voice or voice.get_meta("cue", &"") == &"crate"
	check(crate_voice, "No approved break audio")
	await capture("06_rock_destruction.png")
	var medium := rock_arena(96, 3.0)
	shots = await shoot_until_broken(medium, 12)
	check(medium.is_destroyed and shots == 7, "A medium rock must break with 7 Base shots (took %d)" % shots)
	# Spread: three pellets break a small rock in at most 2 bursts at close range.
	var spread_rock := rock_arena(155, 2.5, true) # A crate stands at X=153, left of this rock.
	bee.collect_spread()
	var bursts := 0
	var first_burst := 0
	while not spread_rock.is_destroyed and bursts < 4:
		var before := spread_rock.health.current_health
		bee.fire()
		bursts += 1
		await frames(26)
		if bursts == 1:
			first_burst = before - spread_rock.health.current_health
	check(spread_rock.is_destroyed and bursts <= 2 and first_burst >= 16, "Spread must break a small rock in <=2 bursts (took %d, first burst %d)" % [bursts, first_burst])
	# Bomb: one Bomb breaks a small rock without a bomb-only exception.
	var bomb_rock := rock_arena(241, 1.5)
	bee.bomb_charges = 1
	check(bee.use_bomb() != null, "Bomb unavailable")
	await frames(40)
	check(bomb_rock.is_destroyed, "A Bomb must break a small rock")
	# Structural: takes hits (flash, dust) but never breaks and keeps obstructing.
	var wall := rock_arena(STRUCTURAL_ROCK, 3.5)
	for i in 8:
		bee._spawn_projectile(Vector3.RIGHT)
		await frames(22)
	check(not wall.is_destroyed and wall.health.current_health < wall.health.max_health and blocks_bee(wall), "The structural rock must take hits but stay")
	check(has_effect(&"rock_hit"), "Shots against the structural rock vanish without feedback")
	# Enemy fire neither damages rocks nor uses them as cover.
	var intact := rock_arena(307, 4.0)
	var enemy_shot := (load("res://scenes/bee_prototype/alien_enemy_projectile.tscn") as PackedScene).instantiate() as AlienEnemyProjectile
	stage.add_child(enemy_shot)
	enemy_shot.global_position = Vector3(307.0 - 3.0, intact.collider.global_position.y, 0)
	enemy_shot.launch(Vector3.RIGHT, null)
	await frames(40)
	check(intact.health.current_health == intact.health.max_health, "Enemy fire damaged a rock")
	print("ARCADE_ROCKS small_base_shots=4 (%.1fs sustained) medium_base_shots=7 spread_bursts=%d bomb=1 structural=1 enemy_fire_ignored=OK" % [sustained, bursts])

func test_rock_checkpoint() -> void:
	# Broken before the checkpoint (72, 96, 155) stay broken; broken after it (241) are rebuilt on retry.
	check(rock(72).is_destroyed and rock(96).is_destroyed and rock(155).is_destroyed and rock(241).is_destroyed, "Fixture rocks not broken")
	stage.distance = 190.05
	stage.checkpoint.activate_checkpoint()
	var broken: Array = stage.checkpoint.snapshot["broken"]
	check("FlightRock72" in broken and "FlightRock96" in broken and "FlightRock155" in broken and not ("FlightRock241" in broken), "Checkpoint snapshot of rocks wrong: " + str(broken))
	var old_stage := stage
	stage.checkpoint.restart_level(false)
	await reloaded(old_stage)
	bind(current_scene)
	for x in [72, 96, 155]:
		check(rock(x).is_destroyed and rock(x).collider.disabled and not rock(x).hurtbox.monitorable, "Rock %d must stay broken after the checkpoint" % x)
	for x in [241, 283, 307, 345, STRUCTURAL_ROCK]:
		check(not rock(x).is_destroyed and not rock(x).collider.disabled and rock(x).health.current_health == rock(x).health.max_health, "Rock %d must be rebuilt after the checkpoint" % x)
	check(get_nodes_in_group("bee_combat_vfx").is_empty(), "Restoring broken rocks must not replay VFX")
	var snapshot_stage := stage
	stage.checkpoint.restart_level(true)
	await reloaded(snapshot_stage)
	bind(current_scene)
	for node in get_nodes_in_group("breakable_rocks"):
		check(not (node as BreakableRock).is_destroyed and not (node as BreakableRock).collider.disabled, "Full restart must rebuild every rock")
	check(get_nodes_in_group("breakable_rocks").size() == 8, "Duplicate rocks after restart")
	print("ARCADE_ROCKS_RESTORE checkpoint_keeps_pre=3 rebuilds_post OK restart_rebuilds_all OK")

# --- Level ----------------------------------------------------------------------------------------

func test_level() -> void:
	var events := BeeLevel01Controller.EVENTS
	var total := 0
	var biggest := 0
	var with_ranged := 0
	var combat_events := 0
	for event: Dictionary in events:
		var units: Array = event["units"]
		total += units.size()
		biggest = maxi(biggest, units.filter(func(f): return f != "Swarm").size()) # Popcorn is outside the threat cap.
		if not units.is_empty():
			combat_events += 1
			for family in units:
				if family in RANGED or (family == "Swarm" and not (event.get("shooters", []) as Array).is_empty()):
					with_ranged += 1
					break
	check(events.size() == 47 and float(events.back()["at"]) == 340.0, "Level length / thresholds changed (GARDEN IDENTITY 04: 44 + 3 spider events)")
	check(total >= 82 and total <= 97, "Unit total %d outside 82-97 (REBUILD 02 + GARDEN IDENTITY 04: 3 spiders and 2 escorts)" % total)
	check(biggest <= 4, "More than 4 threats in one encounter")
	check(float(with_ranged) / float(combat_events) >= 0.75, "Too few encounters with a ranged threat (%d/%d)" % [with_ranged, combat_events])
	check(BeeLevel01Controller.threat_cap(300.0) == 4 and wave.soft_pressure_seconds == 14.0, "Concurrency / lifetime constants")
	check(BeeLevel01Controller.LEVEL_HP.merged({}) == {"Wasp": 44, "Probe": 80, "EyeDrone": 40, "Turret": 70, "Speeder": 30, "OrganicAlien": 100, "Walker": 120, "Dragonfly": 60, "Swarm": 10, "Spider": 90}, "HP changed")
	print("ARCADE_LEVEL enemies=%d events=%d biggest=%d encounters_with_ranged=%d/%d" % [total, events.size(), biggest, with_ranged, combat_events])
	# Dense encounter and a respite for the review captures.
	arena(100.0)
	bee.health.damage_blocked = true
	for family in ["Wasp", "Probe", "EyeDrone"]:
		spawn(family, wave.active_units.size())
	await frames(150)
	await capture("07_dense_encounter.png")
	await clear_units()
	arena(124.0)
	await frames(10)
	await capture("08_respite.png")

func test_boss_and_complete() -> void:
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	stage.scroll_speed = 2.0
	wave.set_physics_process(true)
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	stage.distance = 352.0
	stage._update_camera_and_bounds()
	for i in 900:
		await physics_frame
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			break
	var boss := wave.boss
	check(boss != null and boss.max_hp == 1300 and is_equal_approx(UfoBoss01.APPROACH_SECONDS, 3.2), "UFO Boss changed")
	check(not stage.sector_complete, "Level complete before the boss died")
	boss.health.take_damage(boss.health.max_health)
	for i in 900:
		await physics_frame
		bee.global_position.y = 7.0
		if stage.sector_complete:
			break
	check(stage.sector_complete and stage.status.text == "SECTOR DESPEJADO" and wave.boss_defeated, "Level Complete missing after the boss died")
	print("ARCADE_LEVEL_COMPLETE OK (UFO 1300 HP unchanged)")

func run() -> void:
	create_timer(560.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	bind(current_scene)
	if wants("wasp"):
		await test_wasp()
	if wants("ranged"):
		await test_ranged()
	if wants("rocks"):
		await test_rocks()
		await test_rock_checkpoint()
	if wants("level"):
		await test_level()
		await test_boss_and_complete()
	print("BEE_ARCADE_PRESSURE_WORLD_INTERACTION_V01_OK")
	quit(0)
