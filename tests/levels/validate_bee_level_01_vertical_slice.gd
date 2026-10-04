extends SceneTree

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const REVIEW := "res://dev/level_01_review/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer

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
		await process_frame

func wait_event(index: int, limit := 2400) -> bool:
	for i in limit:
		if wave.event_index == index and (not wave.active_units.is_empty() or wave._waiting_for_human):
			return true
		await frames(1)
	return false

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if name.begins_with("density02_") and not name.begins_with("density02_crate"):
		bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 3.8, 0)
	await frames(2)
	var review_path := OS.get_environment("BEE_LEVEL_REVIEW_DIR")
	if review_path.is_empty():
		review_path = REVIEW
	check(root.get_viewport().get_texture().get_image().save_png(review_path + name) == OK, "Capture failed: " + name)

func clear_active() -> void:
	check(wave.active_units.size() <= 3, "More than three active threats")
	for unit in wave.active_units.duplicate():
		var family: String = str(unit.name.get_slice("_", 0))
		var health := unit.get_node("HealthComponent") as HealthComponent
		check(unit.call("is_active"), "Encounter unit inactive")
		check(unit.visible, "Encounter unit hidden")
		check(health.max_health == int(BeeLevel01Controller.LEVEL_HP[family]) and health.current_health > 0, "Level HP wrong for " + family)
		health.take_damage(9999)
	await frames(3)
	check(wave.active_units.is_empty(), "Encounter did not clear")
	# Scroll is controlled by the authored soft/hard encounter policy.

func test_destructibles() -> void:
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	stage.distance = 18.0
	stage._update_camera_and_bounds()
	var crate := stage.get_node("Destructibles/GardenCrate") as DestructibleObstacle3D
	bee.global_position = Vector3(16.45, 1.2, 0)
	bee.velocity = Vector3.ZERO
	bee.facing_x = 1.0
	bee._place_melee_hitbox()
	Input.action_press("move_right")
	await frames(25)
	Input.action_release("move_right")
	check(bee.global_position.x < 17.3, "Intact crate did not block low flight")
	bee.global_position = Vector3(16.45, 1.2, 0)
	bee.velocity = Vector3.ZERO
	await capture("density02_crate_before.png")
	check(bee.start_melee(), "Bee melee rejected against crate")
	await frames(5)
	check(crate.health.current_health == 9 and crate.get_node("HitFlash3D").activation_count > 0, "Crate ignored Bee melee/HitFlash")
	await frames(36)
	check(bee.start_melee(), "Second Bee melee rejected")
	await frames(5)
	check(crate.is_destroyed and crate.health.current_health == 0 and crate.collider.disabled and crate.body.collision_layer == 0, "Crate did not release route")
	await capture("density02_crate_broken.png")
	bee.global_position = Vector3(16.3, 1.2, 0)
	Input.action_press("move_right")
	for i in 80:
		await frames(1)
		if bee.global_position.x >= 19.5:
			break
	Input.action_release("move_right")
	check(bee.global_position.x >= 19.5, "Bee cannot pass broken crate")
	var shot_crate := stage.get_node("Destructibles/LogApproachCrate") as DestructibleObstacle3D
	stage.distance = 43.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(41.0, 1.2, 0)
	bee.velocity = Vector3.ZERO
	bee.facing_x = 1.0
	var before := shot_crate.health.current_health
	check(bee.fire() != null, "Bee X rejected against crate")
	await frames(18)
	check(shot_crate.health.current_health < before, "Crate ignored Bee X")
	for i in 2:
		check(bee.fire() != null, "Follow-up X rejected against crate")
		await frames(18)
	check(shot_crate.is_destroyed and shot_crate.collider.disabled and not shot_crate.hurtbox.monitorable, "X destruction left an invisible collider/hurtbox")
	stage.distance = 0.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(-2, 4, 0)
	bee.velocity = Vector3.ZERO
	wave.set_physics_process(true)
	stage.set_physics_process(true)
	stage.scroll_speed = 24.0

func test_rock_navigation() -> void:
	for i in 900:
		if stage.distance >= 96.0:
			break
		await frames(1)
	check(stage.distance >= 96.0 and stage.distance < 108.0, "Rock navigation window missed")
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	stage.distance = 96.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(94.0, 1.2, 0)
	bee.velocity = Vector3.ZERO
	Input.action_press("move_right")
	await frames(35)
	Input.action_release("move_right")
	check(bee.global_position.x < 96.0, "Rock failed to obstruct low flight")
	bee.global_position = Vector3(94.0, 3.4, 0)
	bee.velocity = Vector3.ZERO
	Input.action_press("move_right")
	for i in 70:
		await frames(1)
		if bee.global_position.x >= 98.0:
			break
	Input.action_release("move_right")
	check(bee.global_position.x >= 98.0, "Bee cannot fly over rock")
	await capture("density02_04_boxes_rocks.png")
	wave.set_physics_process(true)
	stage.set_physics_process(true)
	stage.scroll_speed = 24.0

func test_human_collision() -> void:
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	bee.set_physics_process(false) # Isolate collision from the moving flight-window clamp.
	var human := stage.get_node("GiantHuman") as GiantHumanCrossingHazard
	var camera_x := stage.camera.global_position.x
	check(human.begin_crossing(stage.camera), "Human diagnostic crossing rejected")
	var initial_hp := bee.health.current_health
	var sampled := 0
	for i in 700:
		bee.global_position = Vector3(human.global_position.x, 0.9, 0)
		await frames(1)
		if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING:
			sampled += 1
			check(bee.health.current_health == initial_hp, "Center safe corridor damaged Bee during crossing")
			if sampled == 220:
				# Bring the camera to the subject for a review image, not gameplay.
				stage.camera.set_stage_x(human.global_position.x)
				var debug_boxes: Array[MeshInstance3D] = []
				for part in ["LeftFoot", "RightFoot", "Torso"]:
					var collider: CollisionShape3D = human.get_node("ContactHitbox/" + part)
					if collider.disabled:
						continue
					var box := MeshInstance3D.new()
					var material := StandardMaterial3D.new()
					material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					material.albedo_color = Color(1.0, 0.15, 0.15)
					box.mesh = collider.shape.get_debug_mesh()
					box.material_override = material
					collider.add_child(box)
					debug_boxes.append(box)
				await capture("human_safe_gap_debug.png")
				for box in debug_boxes:
					box.queue_free()
		if human.current_phase == GiantHumanCrossingHazard.Phase.EXITED:
			break
	check(sampled > 400 and human.hit_count == 0, "Safe pass did not cover the entire crossing")
	stage.camera.set_stage_x(camera_x)
	# Freeze a real wide-stride pose, keeping Area3D collision fully active.
	# Each contact gets a new crossing, therefore one damage opportunity.
	for part in ["LeftFoot", "RightFoot", "Torso"]:
		check(human.begin_crossing(stage.camera), "Human contact crossing rejected")
		for i in 100:
			if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING:
				break
			bee.global_position = Vector3(human.global_position.x, 0.9, 0)
			await frames(1)
		human.animation_player.seek(0.2, true)
		human.animation_player.advance(0.0)
		human._physics_process(0.0)
		human.set_physics_process(false)
		human.animation_player.pause()
		await frames(2)
		var collider: CollisionShape3D = human.get_node("ContactHitbox/" + part)
		check(not collider.disabled, "Contact envelope absent for " + part)
		bee.global_position = collider.global_position
		var hp := bee.health.current_health
		var hits := human.hit_count
		await frames(20)
		check(bee.health.current_health == hp - 20 and human.hit_count == hits + 1, part + " must cause exactly one 20 HP hit")
		await frames(20)
		check(bee.health.current_health == hp - 20, part + " repeated damage every frame")
		human.hitbox.set_enabled(false)
		human.visual_root.hide()
		human.current_phase = GiantHumanCrossingHazard.Phase.EXITED
		human.set_physics_process(true)
		human.animation_player.stop()
	human.current_phase = GiantHumanCrossingHazard.Phase.WAITING
	human.crossings_started = 0
	human.crossings_exited = 0
	human.hit_count = 0
	bee.health.current_health = bee.health.max_health
	bee.global_position = Vector3(-2, 4, 0)
	bee.set_physics_process(true)
	stage.distance = 0
	stage._update_camera_and_bounds()
	stage.set_physics_process(true)
	wave.set_physics_process(true)
	print("HUMAN_COLLISION_OK full_crossing_samples=", sampled, " gap=2.4m shoes=20 torso=20 once_per_crossing=OK")

func test_log() -> void:
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	stage.distance = 57.0 # REBUILD 03: Bee's window ends ~2 m right of the camera; frame the whole passage (52 -> 58).
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(52.0, 0.9, 0)
	bee.velocity = Vector3.ZERO
	Input.action_press("move_right")
	for i in 100:
		await frames(1)
		if bee.global_position.x >= 58:
			break
	Input.action_release("move_right")
	check(bee.global_position.x >= 58 and bee.global_position.y < 1.3, "Hollow log passage blocked")
	stage.distance = 0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(-2, 4, 0)
	wave.set_physics_process(true)
	stage.set_physics_process(true)

func sample_render_performance() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var saved_scale := Engine.time_scale
	Engine.time_scale = 1.0
	await frames(30)
	var total_ms := 0.0
	var worst_ms := 0.0
	var peak_nodes := 0
	var last := Time.get_ticks_usec()
	for i in 180:
		await frames(1)
		var now := Time.get_ticks_usec()
		var ms := float(now - last) / 1000.0
		last = now
		total_ms += ms
		worst_ms = maxf(worst_ms, ms)
		peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("RENDER_NORMAL_SAMPLE threats=3 frames=180 mean_fps=", 180000.0 / total_ms, " peak_frame_ms=", worst_ms, " peak_nodes=", peak_nodes)
	Engine.time_scale = saved_scale

func run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(func(): quit(1))
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	check(wave != null and is_equal_approx(stage.sector_length, 360.0), "Level contract invalid")
	check(is_equal_approx(stage.scroll_speed, 2.0), "Authored speed changed")
	check(stage.get_node("Pollen").get_child_count() == 17, "Pollen count changed")
	check(stage.get_node("Powerups").get_child_count() == 5 and bee.spread_ammo == 0 and bee.bomb_charges == 1, "Level powerups/initial kit wrong") # REBUILD 02: + the pre-boss S+ capsule.
	check(stage.get_node("Destructibles").get_child_count() == 8, "Eight crates missing")
	check(stage.get_node("Scenery").get_child_count() == 350, "Expected 350 scenery placements")
	for prop: Node3D in stage.get_node("Scenery").get_children():
		var prop_name := str(prop.name)
		if "Tree" in prop_name or "Flower" in prop_name or ("Fern" in prop_name and not prop_name.begins_with("Front") and not prop_name.begins_with("Near")):
			for mesh: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
				var bounds: AABB = mesh.global_transform * mesh.get_aabb()
				check(bounds.end.z <= -2.999, "Background foliage reaches the flight plane: " + prop_name)
	check(stage.get_node("WorldEnvironment").environment.sky != null, "Daylight missing")
	check(stage.get_node("LogObstacle/CollisionShape3D").disabled, "Log solid collision enabled")
	for side in ["LogTop", "LogBottom", "LogNearSide", "LogFarSide"]:
		check(not stage.get_node("LogObstacle/" + side).disabled, "Log shell missing")
	check(BeeLevel01Controller.EVENTS.size() == 44, "Event count wrong (REBUILD 03: 44 incl. 7 director moments and the human)")
	var total := 0
	var max_gap := 0.0
	for i in BeeLevel01Controller.EVENTS.size():
		var event: Dictionary = BeeLevel01Controller.EVENTS[i]
		total += event["units"].size()
		if i > 0:
			max_gap = maxf(max_gap, float(event["at"]) - float(BeeLevel01Controller.EVENTS[i - 1]["at"]))
	check(total == 92 and max_gap <= 16, "Unit count/pacing wrong (REBUILD 02: 92 incl. 29 popcorn)")
	await capture("density02_01_garden.png")
	await test_destructibles()
	# Restore authored travel; geometry tests may accelerate their own travel.
	stage.scroll_speed = 2.0
	await test_log()
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	stage.distance = 96
	stage._update_camera_and_bounds()
	await test_rock_navigation()
	stage.distance = 0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(-2, 4, 0)
	stage.scroll_speed = 2.0
	await test_human_collision()
	bee.hurtbox.monitorable = false # Progression coverage is not an unattended survival playtest.
	# Normal thresholds and frames drive every activation. Kills accelerate
	# coverage after each group is observed; first soft group escapes alive.
	var seen: Dictionary = {}
	var captured: Dictionary = {}
	var peak_nodes := 0
	var fps_min := INF
	var frame_peak_ms := 0.0
	var last_usec := Time.get_ticks_usec()
	var frame_sum := 0.0
	var frame_count := 0
	Engine.time_scale = 3.0
	for frame in 20000:
		await frames(1)
		var now := Time.get_ticks_usec()
		var wall_ms := float(now - last_usec) / 1000.0
		last_usec = now
		if frame > 30:
			frame_peak_ms = maxf(frame_peak_ms, wall_ms)
			frame_sum += wall_ms
			frame_count += 1
		peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		fps_min = minf(fps_min, Performance.get_monitor(Performance.TIME_FPS))
		check(wave.active_units.size() <= BeeLevel01Controller.threat_cap(stage.distance), "Concurrency cap exceeded")
		check(wave.swarm_units.size() <= BeeLevel01Controller.MAX_SWARM_ALIVE, "Popcorn budget exceeded")
		check(not bee.is_defeated, "Progression harness Bee defeated")
		# Keep test Bee away from attacks; combat itself remains covered by family tests.
		bee.global_position.y = 0.9 if wave._waiting_for_human else 7.0
		bee.global_position.x = stage.distance - 4.8
		for unit in wave.active_units.duplicate():
			var id: int = unit.get_instance_id()
			var family := str(unit.name).get_slice("_", 0)
			var health := unit.get_node("HealthComponent") as HealthComponent
			check((unit.call("is_active") or CinematicDepthEntry.is_in_depth(unit)) and unit.visible, "Spawn not active/visible") # REBUILD 02: depth entries activate on arrival.
			check(health.max_health == (BeeLevel01Controller.SHOWCASE_HP if unit.has_meta("level_hold") else int(BeeLevel01Controller.LEVEL_HP[family])), "HP changed for " + family)
			if not seen.has(id):
				seen[id] = wave._clock
			var event_id := int(str(unit.name).get_slice("_", 1))
			if wave.active_units.size() == 2 and not captured.has("pair"):
				await capture("density02_02_light_group.png")
				captured["pair"] = true
			if wave.active_units.size() == 3 and not captured.has("triple"):
				await capture("density02_03_three_threats.png")
				captured["triple"] = true
			if family == "OrganicAlien" and not captured.has("organic"):
				await capture("density02_07_organic.png")
				captured["organic"] = true
			if family == "Walker" and not captured.has("walker"):
				await capture("density02_08_walker.png")
				captured["walker"] = true
			if event_id == BeeLevel01Controller.EVENTS.size() - 1 and wave.active_units.size() == 3 and not captured.has("final"):
				await capture("density02_09_final_section.png")
				captured["final"] = true
				await sample_render_performance()
			# Observe all staged entries before resolving each hard gate.
			var slots_full: bool = wave.active_units.size() >= BeeLevel01Controller.threat_cap(stage.distance)
			if event_id > 0 and (wave._pending.is_empty() or slots_full) and wave._clock - float(seen[id]) > 2.0: # A queued unit needs a free slot first.
				health.take_damage(9999)
		if wave._waiting_for_human:
			check(stage.scroll_speed == 0, "Human failed to pause scroll")
			# Collision full-crossing coverage was isolated above. Avoid contacts
			# here while validating normal progression and flight bounds.
			bee.global_position.y = 7.0
			bee.global_position.x = stage.distance - 5.1
		elif not wave._hard_gate:
			check(is_equal_approx(stage.scroll_speed, 2.0) or is_equal_approx(stage.scroll_speed, BeeLevel01Controller.HOLD_SCROLL) or stage.scroll_speed == 0.0, "Soft scroll changed speed") # HOLD_SCROLL: showcase Walker (REBUILD 02).
		if stage.distance >= 180 and not captured.has("vegetation"):
			await capture("density02_06_vegetation.png")
			captured["vegetation"] = true
		# UFO BOSS 01 closes the level; its fight is covered by validate_bee_ufo_boss_01.
		if wave.boss != null and wave.boss.is_active():
			wave.boss.health.take_damage(99999)
		if stage.sector_complete:
			break
	Engine.time_scale = 1.0
	check(stage.sector_complete and stage.status.text == "SECTOR DESPEJADO", "Level did not complete")
	check(wave.event_index == BeeLevel01Controller.EVENTS.size() and wave.max_active_seen >= 3 and wave.max_active_seen <= 4, "Progression/max active wrong")
	check(wave.escaped_count >= 1, "Soft encounters required killing every enemy")
	var spawned := 0
	for family in BeeLevel01Controller.LEVEL_HP:
		check(int(wave.spawned_by_family.get(family, 0)) > 0, "Missing enemy family")
		spawned += int(wave.spawned_by_family[family])
	check(spawned == 92, "Not all 92 units spawned (incl. 2 controlled dragonflies and 29 popcorn)")
	for event_id in BeeLevel01Controller.EVENTS.size():
		var times: Array[float] = []
		for entry in wave.spawn_history:
			if int(entry["event"]) == event_id:
				times.append(float(entry["time"]))
		for i in range(1, times.size()):
			check(times[i] - times[i-1] >= 0.19, "Group spawned in the same frame") # REBUILD 02: formations keep their authored spacing (>= 0.2 s).
	check(captured.has("triple") and captured.has("organic") and captured.has("walker") and captured.has("final"), "Review encounter coverage incomplete")
	var mean_ms := frame_sum / maxf(float(frame_count), 1.0)
	var escaped := wave.escaped_count
	var max_active := wave.max_active_seen
	print("PERFORMANCE_SAMPLE mode=", DisplayServer.get_name(), " time_scale=3 peak_nodes=", peak_nodes, " fps_min=", fps_min, " mean_frame_ms=", mean_ms, " peak_frame_ms=", frame_peak_ms)
	# Real Area3D collection after progression coverage, avoiding any change
	# to the existing combat/geometry diagnostics above.
	bee.set_physics_process(false)
	for pickup: BeePowerupPickup in stage.get_node("Powerups").get_children():
		bee.global_position = pickup.global_position
		await frames(4)
	check(stage.get_node("Powerups").get_child_count() == 0 and bee.spread_ammo == bee.spread_max_shots + bee.spread_overcharge_bonus and bee.bomb_charges == 3, "Level pickups cannot be collected") # REBUILD 02: the S+ capsule overcharges Spread.
	bee.set_physics_process(true)
	bee.health.damage_blocked = false # Victory protection is covered by validate_bee_terminal_states_v01.gd.
	bee.health.take_damage(9999)
	await frames(2)
	check(bee.is_defeated and stage.status.text == "PLAYER DOWN — PRESS R TO RESPAWN", "Defeat missing")
	check(stage.checkpoint.checkpoint_active, "Checkpoint blocked progression or failed to activate")
	Input.action_press("bee_full_restart")
	await frames(3)
	Input.action_release("bee_full_restart")
	var restarted := current_scene as BeeShmupStage
	check(restarted != null and restarted != stage and restarted.distance < 1.0, "R failed to reload")
	check(not restarted.bee.is_defeated and restarted.bee.health.current_health == 100, "R did not restore Bee")
	check((restarted.wave as BeeLevel01Controller).event_index == 0 and restarted.get_node("Pollen").get_child_count() == 17, "Restart encounters/pollen wrong")
	check(not (restarted.get_node("Destructibles/GardenCrate") as DestructibleObstacle3D).is_destroyed, "Restart crate missing")
	check(restarted.get_node("Powerups").get_child_count() == 5 and restarted.bee.spread_ammo == 0 and restarted.bee.bomb_charges == 1, "Restart weapons/powerups wrong")
	print("BEE_LEVEL_01_DENSITY_02_OK events=44 units=92 max_active=", max_active, " escaped=", escaped, " scenery=350 gap=2.4 restart=OK")
	quit(0)
