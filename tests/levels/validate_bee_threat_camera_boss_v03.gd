extends SceneTree

# THREAT, CAMERA & BOSS REBUILD 03 (structure and fairness, never "fun").
#   camera        preset E bounds (+15-25 %), Bee anchor / flight window, camera-aware spawn edge and auto-aim
#   wasp          standard Wasp unchanged; implant sting telegraph + 2 aimed bolts; overload telegraph, locked straight
#                 dash, fair blast (only inside the radius), cancellation when shot during the telegraph
#   organic       ranged bio-orbs after a glow, then a lunge, never at the same time (reposition in between)
#   walker        HEAVY: stays on screen, fires burst AND sweep (high -> low), several cycles if ignored
#   roles         HP table by role; one heavy pattern at a time (BeeAttackTokens)
#   boss          more movement inside its band, minions (cap 2 in phase 2, 1 in phase 3, pause while summoning),
#                 restart, completion with minions cleared
#   presentation  the frog never intersects the distant bottle and enters from off screen; leaves are leaf meshes
# Dev filter: -- only=camera|wasp|organic|walker|roles|boss|presentation

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

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

func bind(value: Node) -> void:
	stage = value as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func fresh() -> void:
	var old := stage
	stage.checkpoint.restart_level(true)
	for i in 120:
		await process_frame
		if current_scene != null and current_scene != old and current_scene.is_node_ready():
			break
	await frames(3)
	bind(current_scene)

func arena(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x + BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.DESIGN_ASPECT), 3.6, 0)
	bee.facing_x = 1.0

func clear() -> void:
	for unit in wave.active_units + wave.swarm_units:
		unit.set_physics_process(false)
		unit.queue_free()
	wave.active_units.clear()
	wave.swarm_units.clear()
	for shot in get_nodes_in_group("alien_projectiles"):
		shot.queue_free()
	BeeAttackTokens.reset()
	await frames(2)

func spawn(family: String, slot := 0, y := 3.6, extra := {}) -> Node3D:
	var request := {"family": family, "slot": slot, "event": 0, "hard": false, "y": y}
	request.merge(extra, true)
	wave._spawn(request)
	return wave.active_units.back()

func place(unit: Node3D, rel_x: float, y: float) -> void:
	unit.global_position = Vector3(stage.camera.global_position.x + rel_x, y, 0)

# --- camera ------------------------------------------------------------------------------------------------

func test_camera() -> void:
	var aspect := BeeLevel01Framing.DESIGN_ASPECT
	check(BeeLevel01Framing.preset_name == &"E", "Camera E must be the default framing")
	var half := BeeLevel01Framing.half_width_min(aspect)
	var height := BeeLevel01Framing.top_y() - BeeLevel01Framing.bottom_y()
	BeeLevel01Framing.use_preset(&"D")
	var d_half := BeeLevel01Framing.half_width_min(aspect)
	var d_height := BeeLevel01Framing.top_y() - BeeLevel01Framing.bottom_y()
	BeeLevel01Framing.use_preset(&"E")
	check(half / d_half >= 1.15 and half / d_half <= 1.25 and height / d_height >= 1.15 and height / d_height <= 1.25, "Camera E gain outside 15-25 %")
	arena(60.0)
	var width := 2.0 * half
	var right_fraction := (bee.flight_max.x - stage.distance + half) / width
	check(absf(right_fraction - BeeLevel01Framing.FLIGHT_RIGHT_FRACTION) < 0.01 and (bee.flight_min.x - stage.distance + half) / width < 0.06, "Bee window must span ~4 %..66 % of the width")
	# Camera-aware spawn edge and auto-aim.
	var probe := spawn("Probe", 0, 4.0) as AlienProbeRanged
	check(probe.global_position.x - stage.camera.global_position.x >= BeeLevel01Framing.half_width_max(aspect) + 0.99, "Spawn not past the camera E edge")
	check(not bee._is_valid_target(probe), "Auto-aim locked onto an enemy that has not entered camera E")
	place(probe, 3.0, 4.0)
	check(bee._is_valid_target(probe), "An on-screen enemy must be targetable")
	await clear()
	print("V03_CAMERA preset=E width_gain=%.2f height_gain=%.2f bee_window=%.2f" % [half / d_half, height / d_height, right_fraction])

# --- wasp -------------------------------------------------------------------------------------------------

func test_wasp() -> void:
	arena(20.0) # COMBAT VARIETY 01: before STING_FROM_X (40) a Wasp has no sting.
	# Standard Wasp (before X=40 in the director): no sting, no overload.
	var plain := spawn("Wasp", 0, 4.6) as WaspEnemy
	check(plain.sting_shots == 0 and not plain.overload_enabled and plain.implant != null, "Standard Wasp must stay standard (implant visible only)")
	await clear()
	# COMBAT VARIETY 01 - implant sting: implant charges (telegraph) then ONE short fan of 3 bolts (every Wasp after X=40).
	arena(120.0)
	var stinger := spawn("Wasp", 0, 4.6) as WaspEnemy
	check(stinger.sting_shots == 1 and stinger.sting_fan_count == 3, "Every Wasp after X=40 must carry the fan sting")
	place(stinger, 2.5, 4.6)
	var charge_seen := -1
	var first_bolt := -1
	for i in 60 * 6:
		await physics_frame
		if charge_seen < 0 and stinger.current_state == WaspEnemy.State.STING:
			charge_seen = i
		if first_bolt < 0 and stinger.sting_count >= 1:
			first_bolt = i
		if stinger.sting_count >= 3:
			break
	check(stinger.sting_count == 3 and charge_seen >= 0 and first_bolt - charge_seen >= int(stinger.sting_windup * 60.0) - 2, "Sting must telegraph (%d frames) then fire a fan of 3" % (first_bolt - charge_seen))
	await clear()
	# Overload: telegraph >= 0.7 s, locked straight dash, blast only inside its radius.
	arena(260.0)
	var kami := spawn("Wasp", 0, 4.6) as WaspEnemy
	check(kami.overload_enabled, "From X=240 every Wasp may overload")
	place(kami, 3.5, 4.6)
	bee.health.damage_blocked = false
	bee.health.current_health = bee.health.max_health
	kami.health.take_damage(int(kami.health.max_health * 0.7))
	check(kami.current_state == WaspEnemy.State.OVERLOAD and kami.implant.mode == &"overload", "Overload did not start at low HP")
	var telegraph_frames := 0
	while kami.current_state == WaspEnemy.State.OVERLOAD and telegraph_frames < 200:
		telegraph_frames += 1
		await physics_frame
	check(telegraph_frames >= 42 and kami.current_state == WaspEnemy.State.KAMIKAZE, "Overload telegraph too short (%d frames)" % telegraph_frames)
	var dash_dir := kami.velocity.normalized()
	bee.global_position.y = 1.0 # Bee leaves the line.
	var straight := true
	while kami.current_state == WaspEnemy.State.KAMIKAZE:
		await physics_frame
		if kami.current_state == WaspEnemy.State.KAMIKAZE and kami.velocity.length() > 0.1:
			straight = straight and kami.velocity.normalized().angle_to(dash_dir) < 0.01
	await frames(2)
	check(straight, "Kamikaze dash must be straight (no homing)")
	check(kami.exploded and not kami.explosion_hit_bee and bee.health.current_health == bee.health.max_health, "A dodged overload must explode away from Bee without damage")
	await clear()
	# Cancellation: shot during the telegraph -> harmless controlled blast.
	var cancel := spawn("Wasp", 2, 4.6) as WaspEnemy
	place(cancel, 3.0, 4.6)
	cancel.health.take_damage(int(cancel.health.max_health * 0.7))
	await frames(10)
	cancel.health.take_damage(999)
	await frames(2)
	check(cancel.overload_canceled and not cancel.explosion_hit_bee and bee.health.current_health == bee.health.max_health, "Killing it during the telegraph must cancel the threat")
	bee.health.damage_blocked = true
	await clear()
	print("V03_WASP sting=2 telegraph=%.2fs straight_dash=OK fair_blast=OK cancel=OK" % (telegraph_frames / 60.0))

# --- organic ----------------------------------------------------------------------------------------------

func test_organic() -> void:
	arena(214.0)
	var organic := spawn("OrganicAlien", 0, 4.0) as OrganicAlienEnemy
	check(organic.ranged_enabled, "Level OrganicAlien must use its ranged language")
	var orbs_at := -1
	var lunge_at := -1
	var overlap := false
	for i in 60 * 10:
		bee.global_position.y = 3.6 + sin(float(i) / 60.0 * 2.0) * 0.8
		await physics_frame
		if orbs_at < 0 and organic.orbs_fired >= organic.orb_count:
			orbs_at = i
		if orbs_at >= 0 and lunge_at < 0 and organic.current_state == OrganicAlienEnemy.State.LUNGE:
			lunge_at = i
		overlap = overlap or (organic.current_state == OrganicAlienEnemy.State.LUNGE and organic.telegraph.material_override != null)
		if lunge_at >= 0:
			break
	check(orbs_at >= 0 and organic.orbs_fired == 3, "OrganicAlien must fire a fan of 3 bio-orbs")
	check(lunge_at > orbs_at and float(lunge_at - orbs_at) / 60.0 >= organic.reposition_time, "Lunge must come after a reposition, never with the orbs")
	check(not overlap, "Ranged and lunge languages overlapped")
	await clear()
	print("V03_ORGANIC orbs=3 lunge_after=%.2fs" % (float(lunge_at - orbs_at) / 60.0))

# --- walker -----------------------------------------------------------------------------------------------

func test_walker() -> void:
	arena(238.0)
	var walker := spawn("Walker", 0) as GroundWalkerEnemy
	var on_screen := 0.0
	for i in 60 * 14:
		bee.global_position.y = 3.6 + sin(float(i) / 60.0 * 2.0) * 1.0
		await physics_frame
		if BeeShmupFairness.is_inside_screen(walker, 0.0):
			on_screen += 1.0 / 60.0
		if walker.sweep_count >= 1 and walker.attacks_started >= 3:
			break
	check(walker.health.max_health == int(BeeLevel01Controller.LEVEL_HP["Walker"]), "Walker HEAVY HP")
	check(walker.sweep_count >= 1 and walker.attacks_started >= 3, "Walker must alternate burst and sweep (%d attacks, %d sweeps)" % [walker.attacks_started, walker.sweep_count])
	check(on_screen >= 4.0 and walker.suppressed_shot_count <= 1, "Walker must stay on screen and fire from it (%.1f s, %d suppressed)" % [on_screen, walker.suppressed_shot_count])
	# Sweep order: high to low.
	var dirs := walker._sweep_dirs
	var ordered := true
	for k in range(1, dirs.size()):
		ordered = ordered and dirs[k].y <= dirs[k - 1].y
	check(dirs.size() == walker.sweep_shots and ordered, "Sweep must run from the highest shot to the lowest")
	var summary := "V03_WALKER attacks=%d sweeps=%d on_screen=%.1fs" % [walker.attacks_started, walker.sweep_count, on_screen]
	await clear()
	print(summary)

# --- roles ------------------------------------------------------------------------------------------------

func test_roles() -> void:
	var hp := BeeLevel01Controller.LEVEL_HP
	check(hp["Swarm"] <= 22, "POPCORN dies in < 0.8 s of reasonable fire")
	for light in ["Wasp", "EyeDrone", "Speeder"]:
		check(hp[light] >= 28 and hp[light] <= 56, "LIGHT HP out of the 1-2 s band: " + light)
	for medium in ["Probe", "Turret", "OrganicAlien"]:
		check(hp[medium] >= 60 and hp[medium] <= 126, "MEDIUM HP out of the ~2-4.5 s band: " + medium)
	check(hp["Walker"] >= 90 and hp["Walker"] <= 196 and BeeLevel01Controller.SHOWCASE_HP >= 120, "HEAVY / SHOWCASE HP (LOTE 9: Walker ~3 s, showcase ~4 s)")
	# One heavy pattern at a time.
	arena(300.0)
	var a := spawn("Wasp", 0, 4.0)
	var b := spawn("Walker", 1)
	check(BeeAttackTokens.enabled and BeeAttackTokens.try_claim(a, 1.0) and not BeeAttackTokens.try_claim(b, 1.0), "Two heavy patterns could start together")
	BeeAttackTokens.release(a)
	check(BeeAttackTokens.try_claim(b, 1.0), "Released token must be claimable")
	await clear()
	print("V03_ROLES hp=%s tokens=OK" % str(hp))

# --- boss -------------------------------------------------------------------------------------------------

func boss_fight() -> UfoBoss01:
	arena(340.0)
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	wave.set_physics_process(true)
	for i in 600:
		await physics_frame
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			break
	return wave.boss

func test_boss() -> void:
	var boss := await boss_fight()
	check(boss != null and boss.max_hp == 500, "Boss missing or HP changed")
	var cam_x := stage.camera.global_position.x
	var xs: Array[float] = []
	for i in 60 * 6:
		await physics_frame
		xs.append(boss.global_position.x - cam_x)
	check(xs.max() - xs.min() >= 0.8 and xs.min() >= UfoBoss01.X_MIN - 0.01, "Phase 1 must drift visibly inside its band (%.2f..%.2f)" % [xs.min(), xs.max()])
	check(wave.boss_minions().is_empty(), "No minions in phase 1")
	# Phase 2: summon (no attack while summoning), at most 2 minions.
	boss.health.take_damage(boss.health.current_health - int(boss.max_hp * 0.6))
	var summon_seen := false
	var attacked_while_summoning := false
	var max_minions := 0
	var xs2: Array[float] = []
	for i in 60 * 12:
		bee.global_position.y = 3.6 + sin(float(i) / 60.0 * 2.0) * 1.0
		await physics_frame
		if boss.state == UfoBoss01.State.PHASE_2:
			xs2.append(boss.global_position.x - cam_x)
		if str(boss._attack_step) == "summon":
			summon_seen = true
			attacked_while_summoning = attacked_while_summoning or boss._attack_step in [&"telegraph", &"burst"]
		max_minions = maxi(max_minions, wave.boss_minions().size())
	check(summon_seen and boss.summons >= 1, "Phase 2 must summon minions")
	check(max_minions >= 1 and max_minions <= BeeLevel01Controller.MAX_BOSS_MINIONS, "Minion cap broken (%d)" % max_minions)
	check(not attacked_while_summoning, "The saucer must not attack while summoning")
	check(xs2.max() - xs2.min() > xs.max() - xs.min(), "Phase 2 must move more than phase 1")
	for minion in wave.boss_minions():
		check(minion.has_meta("boss_minion") and bool(minion.get_meta("level_hard")), "Minions never retreat on their own")
	# Phase 3: at most one minion.
	boss.health.take_damage(boss.health.current_health - int(boss.max_hp * 0.3))
	for i in 60 * 10:
		await physics_frame
		check(wave.boss_minions().size() <= BeeLevel01Controller.MAX_BOSS_MINIONS, "Minion cap broken in phase 3")
	# Completion: minions fall with the ship, then Level Complete.
	var summons := boss.summons
	boss.health.take_damage(99999)
	await frames(3)
	check(wave.boss_minions().is_empty(), "Minions must be cleared with the boss")
	for i in 60 * 20: # Death sequence + the roll to the sector end.
		await physics_frame
		if stage.sector_complete:
			break
	check(stage.sector_complete, "Level Complete missing after the boss")
	# Restart: a fresh boss with full HP and no minions.
	await fresh()
	var again := await boss_fight()
	check(again != null and again.health.current_health == again.max_hp and wave.boss_minions().is_empty() and again.summons == 0, "Restart must give a fresh boss")
	print("V03_BOSS drift_p1=%.2f drift_p2=%.2f summons=%d max_minions=%d complete=OK restart=OK" % [xs.max() - xs.min(), xs2.max() - xs2.min(), summons, max_minions])

# --- presentation -----------------------------------------------------------------------------------------

func test_presentation() -> void:
	var garden := stage.get_node("LivingGarden") as BeeLevel01LivingGarden
	check(garden.find_children("*", "CollisionObject3D", true, false).is_empty(), "Living garden must not collide")
	check(not (garden.leaves.mesh is QuadMesh) and garden.leaves.mesh is ArrayMesh, "Falling leaves must be real leaf meshes")
	var frog_event := stage.get_node("ScaleEvent") as BeeLevel01ScaleEvent
	arena(188.0)
	stage.scroll_speed = 2.0
	stage.set_physics_process(true)
	wave.director_moment.emit(&"scale_event")
	await frames(1)
	var start_rel := frog_event.frog.global_position.x - stage.camera.global_position.x
	check(start_rel > frog_event._half_at_depth(), "The frog must enter from beyond the visible edge at its depth")
	# The frog must never share space with the distant bottle (its real mesh bounds).
	var bottle_box := AABB()
	var bottle_node := stage.get_node("Scenery").find_child("DistantBottle", true, false) as Node3D
	check(bottle_node != null, "Distant bottle missing")
	var first_b := true
	for mesh: MeshInstance3D in bottle_node.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = mesh.global_transform * mesh.get_aabb()
		bottle_box = bb if first_b else bottle_box.merge(bb)
		first_b = false
	var frog_box := AABB()
	var touched := false
	for i in 60 * 16:
		await physics_frame
		if not is_instance_valid(frog_event.frog):
			break
		var box := AABB()
		var first := true
		for mesh: MeshInstance3D in frog_event.frog.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = mesh.global_transform * mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		frog_box = box
		touched = touched or box.intersects(bottle_box)
	check(not touched and frog_event.landings >= 4 and frog_box.end.z < -3.0, "The frog intersects the bottle or never hops (landings %d)" % frog_event.landings)
	stage.scroll_speed = 0.0
	print("V03_PRESENTATION leaves=mesh frog_start=%.1f landings=%d bottle_clear=OK" % [start_rel, frog_event.landings])

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	bind(current_scene)
	if wants("camera"):
		await test_camera()
	if wants("wasp"):
		await test_wasp()
	if wants("organic"):
		await test_organic()
	if wants("walker"):
		await test_walker()
	if wants("roles"):
		await test_roles()
	if wants("presentation"):
		await fresh()
		await test_presentation()
	if wants("boss"):
		await fresh()
		await test_boss()
	print("BEE_THREAT_CAMERA_BOSS_V03_OK")
	quit(0)
