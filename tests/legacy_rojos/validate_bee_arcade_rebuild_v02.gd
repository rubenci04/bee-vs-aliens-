extends SceneTree

# ARCADE CONTENT & SPECTACLE REBUILD 02 (structure, never "fun").
#   static      living garden (no collision), unit budget 82-97 (GARDEN IDENTITY 04: was 82-92), Walker x5 (clean presentation, showcase, escort, late gates), OrganicAlien x3
#               (presentation, crossfire, late gate), popcorn swarms with shooters, depth entries, set pieces, caps
#   popcorn     one Base shot kills a drone, shooters fire exactly one aimed shot, contact hurts, escapes are freed,
#               popcorn never counts towards the threat cap
#   depth       cinematic depth entry: no AI, no shot, no collision, no auto-aim while deep; a normal enemy on arrival
#   power       guaranteed pre-boss weapon power: Base -> Spread; Spread -> refill + extend; never a downgrade
#   setpieces   Walker hold keeps the showcase on screen; the frog scale event hops behind the flight plane (no collision)
#   checkpoint  resume after X=190 without replaying the Walker showcase or the frog; the power moment still ahead
#   run         whole level with a fast harness: caps, ceiling, every family, depth units never fire from depth,
#               moments in order, UFO 500 HP, Level Complete
# Dev filter: -- only=static|popcorn|depth|power|setpieces|checkpoint|run

## LOTE 9 · ETAPA C: the NODO ALIEN has 1200 HP and 4 phases (was 500 HP, 3 phases).
const BOSS_HP := 1200
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var only := ""

func _initialize() -> void:
	BeeLevel01Controller.roster_only = false # LOTE 12: this test covers the pre-roster flow (alien enemies, frog, UFO), which stays intact behind LEVEL01_ROSTER_ONLY.
	BeeLevel01Controller.instant_arrival = true # Tanda E
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

func fresh() -> void:
	var old := stage
	stage.checkpoint.restart_level(true)
	await reloaded(old)
	bind(current_scene)

func arena(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 3.5, 0)
	bee.facing_x = 1.0

func clear_units() -> void:
	for unit in wave.active_units + wave.swarm_units:
		unit.set_physics_process(false)
		unit.queue_free()
	wave.active_units.clear()
	wave.swarm_units.clear()
	for shot in get_nodes_in_group("alien_projectiles"):
		shot.queue_free()
	await frames(2)

# --- static ----------------------------------------------------------------------------------------------

func test_static() -> void:
	var events := BeeLevel01Controller.EVENTS_LEGACY
	var total := 0
	var walkers: Array[float] = []
	var organics: Array[float] = []
	var swarm_groups := 0
	var swarm_shooters := 0
	var depth_events: Array[Dictionary] = []
	var depth_units := 0
	var paths := {}
	for event: Dictionary in events:
		var units: Array = event["units"]
		total += units.size()
		var at := float(event["at"])
		for family in units:
			if family == "Walker":
				walkers.append(at)
			elif family == "OrganicAlien":
				organics.append(at)
		for zone_wave: Dictionary in event.get("arena", []): # LOTE 9: combat-zone waves count in the budget and the popcorn variety.
			total += (zone_wave["units"] as Array).size()
			if "Swarm" in zone_wave["units"]:
				swarm_groups += 1
				swarm_shooters += (zone_wave.get("shooters", []) as Array).size()
				paths[str(zone_wave.get("path", "sine"))] = true
		if "Swarm" in units:
			swarm_groups += 1
			swarm_shooters += (event.get("shooters", []) as Array).size()
			paths[str(event.get("path", "sine"))] = true
			for index in event.get("shooters", []):
				check(str(units[int(index)]) == "Swarm", "Shooter index must point at a Swarm unit: " + str(event["label"]))
		if bool(event.get("depth", false)):
			depth_events.append(event)
			depth_units += units.size()
			check(not bool(event.get("hard", false)), "Depth entries never open a hard gate")
	check(total >= 144 and total <= 150, "Unit budget %d outside 144-150 (LOTE 11, zones included)" % total)
	check(walkers.size() >= 4 and walkers.size() <= 5, "Walker appearances %d (want 4-5)" % walkers.size())
	var first_walker: Dictionary = events.filter(func(e): return "Walker" in e["units"])[0]
	check((first_walker["units"] as Array).size() == 1 and walkers[0] < 140.0, "The first Walker must be a clean presentation, alone, before the human")
	check(walkers.back() == 340.0 and walkers.filter(func(x): return x >= 254.0).size() >= 2, "Walker needs late-game encounters")
	check(organics.is_empty(), "NOCHE 01: the purple organism is a UFO minion only (%d normal appearances)" % organics.size())
	check(swarm_groups >= 5 and swarm_shooters >= 8 and paths.size() >= 4, "Popcorn variety too low (%d groups, %d shooters, paths %s)" % [swarm_groups, swarm_shooters, str(paths.keys())])
	check(depth_events.size() >= 2 and depth_events.filter(func(e): return (e["units"] as Array).size() >= 2).size() >= 1, "Need >= 2 depth entries incl. a formation (LOTE 9: was 4 incl. 2 formations of 3)")
	check(BeeLevel01Controller.threat_cap(10.0) == 4 and BeeLevel01Controller.threat_cap(150.0) == 5 and BeeLevel01Controller.threat_cap(300.0) == 6, "Threat cap 2/3/4 (REBUILD 03 thresholds 96 / 240)")
	check(BeeLevel01Controller.LIVE_SHOT_CEILING - 1 + 5 <= 20, "Below-ceiling live shots + the largest volley (5) must stay <= 14")
	var moments: Array[String] = []
	for event: Dictionary in events:
		if event.has("moment"):
			moments.append(str(event["moment"]))
	for id in ["walker_showcase", "scale_event", "preboss_power"]:
		check(id in moments, "Missing set piece moment " + id)
	var garden := stage.get_node_or_null("LivingGarden") as BeeLevel01LivingGarden
	check(garden != null and garden.find_children("*", "CollisionObject3D", true, false).is_empty() and garden.butterflies.size() >= 3 \
			and garden.gnat_clouds.size() >= 3 and garden.leaves != null and garden.pollen != null, "Living garden missing or collidable")
	var power: Dictionary = events.filter(func(e): return e.get("moment", "") == "preboss_power")[0]
	check(float(power["at"]) >= 320.0 and float(power["at"]) < 340.0 and (power["units"] as Array).is_empty(), "Pre-boss power must be an enemy-free beat right before the last defence")
	print("REBUILD_STATIC units=%d walkers=%s organics=%s swarm_groups=%d shooters=%d depth=%d(%d units) moments=%s" % [total, str(walkers), str(organics), swarm_groups, swarm_shooters, depth_events.size(), depth_units, str(moments)])

# --- popcorn ---------------------------------------------------------------------------------------------

func test_popcorn() -> void:
	arena(100.0)
	await clear_units()
	wave._spawn({"family": "Swarm", "slot": 0, "event": 0, "hard": false, "y": 4.0, "path": "sine", "shooter": true})
	var drone := wave.swarm_units.back() as PopcornDrone
	check(drone != null and not wave.active_units.has(drone), "Popcorn must live outside the threat list")
	check(drone.health.max_health == 10, "Popcorn HP must be one Base shot")
	var fired := [0]
	drone.projectile_fired.connect(func(_p): fired[0] += 1)
	var start_x := drone.global_position.x - stage.camera.global_position.x
	for i in 150:
		await physics_frame
	check(drone.global_position.x - stage.camera.global_position.x < start_x - 3.0, "Popcorn must cross the screen")
	check(fired[0] == 1 and drone.projectile_fire_count == 1, "A shooter fires exactly one shot (%d)" % fired[0])
	var shot := bee._spawn_projectile((drone.global_position - bee.global_position).normalized())
	for i in 40:
		await physics_frame
		if drone.is_defeated():
			break
	for extra in 4: # Tanda E: the Base shot does 3 damage now; a popcorn drone dies within a few
		if drone.is_defeated(): break
		bee._spawn_projectile((drone.global_position - bee.global_position).normalized())
		for i in 30:
			await physics_frame
			if drone.is_defeated(): break
	check(drone.is_defeated(), "A few Base shots must destroy a popcorn drone")
	await frames(70)
	check(not is_instance_valid(drone) or not wave.swarm_units.has(drone), "A destroyed drone must leave the popcorn list")
	# An escaping drone is freed.
	wave._spawn({"family": "Swarm", "slot": 1, "event": 0, "hard": false, "y": 6.0, "path": "arc_top", "shooter": false})
	var runner := wave.swarm_units.back() as PopcornDrone
	wave.set_physics_process(true)
	for i in 60 * 8:
		await physics_frame
		if not is_instance_valid(runner) or not wave.swarm_units.has(runner as Node3D):
			break
	wave.set_physics_process(false)
	check(not is_instance_valid(runner) or not wave.swarm_units.has(runner), "An escaped drone must be released")
	await clear_units()
	print("REBUILD_POPCORN one_shot=OK shooter_once=OK escape_release=OK")

# --- depth entry -----------------------------------------------------------------------------------------

func test_depth() -> void:
	arena(80.0)
	await clear_units()
	wave._spawn({"family": "Probe", "slot": 0, "event": 0, "hard": false, "y": 4.4, "depth": true, "anchor": Vector2(BeeLevel01Controller.DEPTH_TARGET_X, 4.4)})
	var probe := wave.active_units.back() as AlienProbeRanged
	check(CinematicDepthEntry.is_in_depth(probe), "Depth entry not started")
	var deepest := 0.0
	var shots_during := 0
	var hp := probe.health.current_health
	var frames_in_depth := 0
	while CinematicDepthEntry.is_in_depth(probe) and frames_in_depth < 300:
		frames_in_depth += 1
		deepest = minf(deepest, probe.global_position.z)
		check(probe.visible, "A depth entry must be visible (it is the spectacle)")
		check(not probe.is_in_group("bee_auto_aim_targets") and not bee._is_valid_target(probe), "Auto-aim locked onto a unit in depth")
		check(not probe.hurtbox.monitorable, "Hurtbox active while in depth")
		check(not probe.is_physics_processing(), "AI running while in depth")
		if frames_in_depth % 10 == 0: # Bee keeps firing through its screen position: nothing may touch it.
			var p := bee._spawn_projectile((Vector3(probe.global_position.x, probe.global_position.y, 0) - bee.global_position).normalized())
			p.hitbox.damage = 10
		shots_during += get_nodes_in_group("alien_projectiles").size()
		await physics_frame
	check(frames_in_depth < 300 and deepest <= -10.0, "Depth entry must start deep (%.1f) and finish" % deepest)
	check(shots_during == 0, "A unit fired while in depth")
	check(probe.health.current_health == hp, "A unit took damage while in depth")
	await frames(3)
	check(absf(probe.global_position.z) < 0.01 and probe.is_in_group("bee_auto_aim_targets") and probe.hurtbox.monitorable and probe.is_physics_processing(), "Arrival must hand over to a normal enemy")
	var hit := bee._spawn_projectile((probe.global_position - bee.global_position).normalized())
	await frames(30)
	check(probe.health.current_health < hp, "After arriving the unit must be damageable")
	await clear_units()
	print("REBUILD_DEPTH deepest_z=%.1f frames_in_depth=%d no_fire=OK no_hit=OK handover=OK" % [deepest, frames_in_depth])

# --- pre-boss power --------------------------------------------------------------------------------------

func test_power() -> void:
	var capsule := stage.get_node("Powerups/PrebossPower") as BeePowerupPickup
	check(capsule != null and capsule.overcharge and capsule.kind == BeePowerupPickup.Kind.SPREAD, "Pre-boss Spread capsule missing")
	check(capsule.global_position.x >= 330.0 and capsule.global_position.x < 340.0 and capsule.scale.x >= 1.2, "Pre-boss capsule must sit right before the last defence and look bigger")
	# Base -> Spread.
	check(bee.spread_ammo == 0, "Bee should start with Base")
	check(bee.collect_spread_overcharge(), "Overcharge refused")
	var from_base := bee.spread_ammo
	check(is_equal_approx(from_base, BeeGameSettings.SPREAD_DURATION_SEC), "Base -> overcharged Spread (%d)" % from_base)
	# Spread with little ammo -> refill + extend (never less than before).
	bee.spread_ammo = 5
	bee.collect_spread_overcharge()
	check(is_equal_approx(bee.spread_ammo, 15.0), "Spread must refill and extend (%d)" % bee.spread_ammo)
	# Already overcharged -> never a downgrade.
	var before := bee.spread_ammo
	bee.collect_spread_overcharge()
	check(bee.spread_ammo >= before and bee.spread_ammo <= BeeGameSettings.SPREAD_MAX_DURATION_SEC, "Never a downgrade, bounded (%d)" % bee.spread_ammo)
	bee.spread_ammo = 0
	# Real pickup through the director moment.
	arena(331.0)
	wave.director_moment.emit(&"preboss_power")
	await frames(20)
	check(capsule.scale.x > 1.3 or wave.player_label != "", "The power moment must announce itself")
	bee.set_physics_process(true)
	bee.global_position = capsule.global_position
	await frames(4)
	check(not is_instance_valid(capsule) or capsule.was_collected, "Capsule not collected")
	check(bee.spread_ammo > 19.0 and bee.spread_ammo <= 20.0, "Pre-boss pickup must give an overcharged Spread")
	print("REBUILD_POWER base_to=%d refill_extend=OK no_downgrade=OK" % from_base)

# --- set pieces ------------------------------------------------------------------------------------------

func test_setpieces() -> void:
	# Walker hold: while a showcase Walker lives, the scroll slows so it stays on screen.
	stage.distance = 104.0
	stage._update_camera_and_bounds()
	wave.set_physics_process(true)
	wave._spawn({"family": "Walker", "slot": 0, "event": 0, "hard": false, "hold": true})
	var walker := wave.active_units.back() as GroundWalkerEnemy
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	stage.scroll_speed = BeeLevel01Controller.LEVEL_SCROLL # LOTE 7: cruise scroll 1.5 m/s.
	for i in 60 * 3:
		await physics_frame
		bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 5.5, 0)
	check(is_equal_approx(stage.scroll_speed, BeeLevel01Controller.HOLD_SCROLL), "Showcase hold must slow the scroll (%.1f)" % stage.scroll_speed)
	check(absf(walker.global_position.x - stage.camera.global_position.x) < 5.6, "The showcase Walker must stay on screen")
	walker.health.take_damage(9999)
	await frames(3)
	check(is_equal_approx(stage.scroll_speed, BeeLevel01Controller.LEVEL_SCROLL), "Scroll must resume after the showcase")
	wave.set_physics_process(false)
	await clear_units()
	# The frog: hops behind the flight plane, lands with feedback, no collision, then leaves.
	var frog_event := stage.get_node("ScaleEvent") as BeeLevel01ScaleEvent
	arena(188.0)
	stage.scroll_speed = BeeLevel01Controller.LEVEL_SCROLL # LOTE 7: cruise scroll 1.5 m/s.
	stage.set_physics_process(true)
	wave.director_moment.emit(&"scale_event")
	await frames(2)
	check(frog_event.frog != null and frog_event.frog is BeeGardenToadEncounter, "Frog missing or collidable")
	var max_z := -INF
	var seen_on_screen := false
	for i in 60 * 55: # REBUILD 03: the frog enters from beyond the real edge at its depth, so the crossing is longer.
		await physics_frame
		if not is_instance_valid(frog_event.frog):
			break
		max_z = maxf(max_z, frog_event.frog.global_position.z)
		seen_on_screen = seen_on_screen or absf(frog_event.frog.global_position.x - stage.camera.global_position.x) < 4.0
	check(is_zero_approx(max_z) and seen_on_screen and frog_event.landings >= 4, "Frog must hop across the background (z %.1f, landings %d)" % [max_z, frog_event.landings])
	check(not frog_event.frog.is_visible_in_tree() and not frog_event.frog.is_physics_processing(), "Frog must time out and leave without a gate")
	stage.scroll_speed = 0.0
	print("REBUILD_SETPIECES walker_hold=OK frog_landings=%d" % frog_event.landings)

# --- checkpoint ------------------------------------------------------------------------------------------

func test_checkpoint() -> void:
	stage.distance = 190.05
	stage.checkpoint.activate_checkpoint()
	var old := stage
	stage.checkpoint.restart_level(false)
	await reloaded(old)
	bind(current_scene)
	for index in range(wave.event_index, BeeLevel01Controller.EVENTS_LEGACY.size()):
		var event: Dictionary = BeeLevel01Controller.EVENTS_LEGACY[index]
		check(str(event.get("moment", "")) not in ["walker_showcase", "scale_event"], "A pre-checkpoint set piece would replay")
	check(stage.get_node_or_null("Powerups/PrebossPower") != null, "The pre-boss power must still be ahead after the checkpoint")
	print("REBUILD_CHECKPOINT resume=%d no_replay=OK power_ahead=OK" % wave.event_index)

# --- whole level -----------------------------------------------------------------------------------------

func test_run() -> void:
	var moments: Array[String] = []
	wave.director_moment.connect(func(id: StringName): moments.append(str(id)))
	bee.set_physics_process(false)
	bee.hurtbox.monitorable = false
	Engine.time_scale = 3.0
	var seen := {}
	var peak := 0
	var depth_seen := 0
	var depth_fired := 0
	var max_swarm := 0
	for frame in 36000:
		await physics_frame
		bee.global_position = Vector3(stage.distance - 4.8, 7.0, 0)
		var cap := BeeLevel01Controller.MAX_ON_SCREEN_ARENA if wave.in_arena() else BeeLevel01Controller.threat_cap(stage.distance)
		check(wave.active_units.size() <= cap, "Threat cap exceeded")
		max_swarm = maxi(max_swarm, wave.swarm_units.size())
		peak = maxi(peak, get_nodes_in_group("alien_projectiles").size())
		for shot in get_nodes_in_group("alien_projectiles"):
			var shot_box := shot.get_node_or_null("Hitbox3D") as DamageHitbox3D # LOTE 6: mortar shells (alien_projectiles too) have no Hitbox3D child.
			if shot_box == null:
				continue
			var attacker = shot_box.attacker
			if attacker != null and is_instance_valid(attacker) and attacker != wave.boss and CinematicDepthEntry.is_in_depth(attacker):
				depth_fired += 1
		for unit in wave.active_units.duplicate():
			var id: int = unit.get_instance_id()
			if CinematicDepthEntry.is_in_depth(unit):
				if not seen.has(id):
					depth_seen += 1
					seen[id] = -1.0
				continue
			if not seen.has(id) or float(seen[id]) < 0.0:
				seen[id] = wave._clock
			var full: bool = wave.active_units.size() >= cap
			if (wave._pending.is_empty() or full) and wave._clock - float(seen[id]) > 2.0:
				unit.get_node("HealthComponent").take_damage(9999)
		if wave._waiting_for_human:
			bee.global_position = Vector3(stage.distance - 5.1, 7.0, 0)
		if wave.boss != null and wave.boss.is_active():
			check(wave.boss.max_hp == BOSS_HP, "UFO HP changed")
			wave.boss.health.take_damage(99999)
		if stage.sector_complete:
			break
	Engine.time_scale = 1.0
	check(stage.sector_complete and (stage.status.text.begins_with("SECTOR DESPEJADO") or stage.has_node("ResultsScreen")), "Level Complete missing")
	check(moments == ["opening_can", "watering_can", "human_aftermath", "walker_showcase", "scale_event", "contaminated_garden", "bomb_reward", "preboss_power", "last_silence"], "Moments out of order: " + str(moments))
	var planned := 0
	for event: Dictionary in BeeLevel01Controller.EVENTS_LEGACY:
		planned += (event["units"] as Array).size()
		for zone_wave: Dictionary in event.get("arena", []): # LOTE 7: combat-zone waves.
			planned += (zone_wave["units"] as Array).size()
	var spawned := 0
	for family in wave.spawned_by_family:
		spawned += int(wave.spawned_by_family[family])
	check(spawned == planned, "Spawned %d of %d planned units" % [spawned, planned])
	check(int(wave.spawned_by_family.get("Walker", 0)) == 5 and int(wave.spawned_by_family.get("OrganicAlien", 0)) <= 2, "Walker/Organic presence wrong (LOTE 9: 5 Walkers incl. 1 in a zone; NOCHE 01: organism only as UFO minion)")
	check(depth_seen >= 3 and depth_fired == 0, "Depth entries: %d seen, %d shots from depth" % [depth_seen, depth_fired])
	check(peak <= 14, "Projectile ceiling exceeded (%d)" % peak)
	check(max_swarm <= BeeLevel01Controller.MAX_SWARM_ALIVE, "Popcorn budget exceeded")
	print("REBUILD_RUN units=%d depth_units=%d peak_shots=%d max_swarm=%d moments=%d complete=OK" % [spawned, depth_seen, peak, max_swarm, moments.size()])

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_children().filter(func(n): return n.name != "SceneFade").back() # Tanda E: the scene-fade cover is added after the level
	await frames(5)
	bind(current_scene)
	if wants("static"):
		test_static()
	if wants("popcorn"):
		await test_popcorn()
	if wants("depth"):
		await test_depth()
	if wants("power"):
		await fresh()
		await test_power()
	if wants("setpieces"):
		await fresh()
		await test_setpieces()
	if wants("checkpoint"):
		await fresh()
		await test_checkpoint()
	if wants("run"):
		await fresh()
		await test_run()
	print("BEE_ARCADE_REBUILD_V02_OK")
	quit(0)
