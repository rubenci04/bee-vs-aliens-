extends SceneTree

# COMBAT VARIETY 01 (lote 4). Every Level 01 family fires ITS pattern, each one announced 0.4-0.8 s (or more) before it
# can hurt, and the NODO ALIEN v2 boss (sides, mines, multi-point drones, beam) stays fair:
#   wasp    implant charge -> ONE short fan of 3 bolts
#   eye     laser: warning lines -> thin beam sweeping vertically through Bee's height (one hit)
#   speeder flashing telegraph + line at Bee -> straight (possibly diagonal) ram -> harmless retreat
#   turret  ground ring marked at the charge -> high-arc shell -> short cyan puddle
#   walker  neck-cannon charge -> 3 horizontal shots
#   probe   one slow orb -> swells -> splits in 2
#   boss    enters from either side and crosses at phase changes; phase 2 mines + drones from several points;
#           phase 3 beam + faster mines + side changes; every hazard has telegraph >= MIN_TELEGRAPH; the only
#           untelegraphed damage (hull contact) stays under UNTELEGRAPHED_CAP; F9 = Base + 2 bombs; retry from the other side.
# With a rendering window it saves captures in res://dev/visual_target/ (lote4_*.png).
# Dev filter: -- only=wasp|eye|speeder|turret|walker|probe|boss

## LOTE 9 · ETAPA C: the NODO ALIEN has 1200 HP and 4 phases (was 500 HP, 3 phases).
const BOSS_HP := 1200
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/visual_target/"
const UNTELEGRAPHED_CAP := 24 # Max hull-contact damage on Bee in the scripted fight (two touches; Bee flies like a player).

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
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "lote4_" + label + ".png"))

func bind(value: Node) -> void:
	stage = value as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func reload(action: Callable) -> void:
	var old := stage
	action.call()
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
	bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 3.6, 0)
	bee.facing_x = 1.0

func clear() -> void:
	for unit in wave.active_units + wave.swarm_units:
		unit.set_physics_process(false)
		unit.queue_free()
	wave.active_units.clear()
	wave.swarm_units.clear()
	for group in ["alien_projectiles", "alien_mortar", "ufo_boss_mines"]:
		for node in get_nodes_in_group(group):
			node.queue_free()
	BeeAttackTokens.reset()
	await frames(2)

func spawn(family: String, y := 3.6) -> Node3D:
	wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false, "y": y})
	return wave.active_units.back()

func place(unit: Node3D, rel_x: float, y: float) -> void:
	unit.global_position = Vector3(stage.camera.global_position.x + rel_x, y, 0)

## Frames until `condition` is true (or -1 after `limit`).
func wait_for(condition: Callable, limit := 600) -> int:
	for i in limit:
		if condition.call():
			return i
		await frames(1)
	return -1

# --- part A -----------------------------------------------------------------------------------------------

func test_wasp() -> void:
	arena(120.0)
	var wasp := spawn("Wasp", 4.6) as WaspEnemy
	place(wasp, 2.5, 4.6)
	check(wasp.sting_fan_count == 3 and wasp.sting_shots == 1, "Level 01 Wasp must use the fan sting")
	var charge := await wait_for(func(): return wasp.current_state == WaspEnemy.State.STING, 600)
	check(charge >= 0, "Wasp never charged its sting")
	await capture("wasp_charge")
	var fired := await wait_for(func(): return wasp.sting_count >= 3, 120)
	check(fired >= int(wasp.sting_windup * 60.0) - 2, "Wasp fan fired before its telegraph (%d frames)" % fired)
	check(wasp.sting_count == 3, "Wasp must fire exactly 3 bolts (%d)" % wasp.sting_count)
	var bolts := get_nodes_in_group("alien_projectiles")
	var spread := 0.0
	for a in bolts:
		for b in bolts:
			spread = maxf(spread, rad_to_deg((a as AlienEnemyProjectile).travel_direction.angle_to((b as AlienEnemyProjectile).travel_direction)))
	check(absf(spread - 2.0 * WaspEnemy.STING_FAN_STEP) < 1.5, "Wasp fan spread wrong (%.1f deg)" % spread)
	await capture("wasp_fan")
	report.append("wasp fan3 telegraph=%.2fs" % (fired / 60.0))
	await clear()

func test_eye() -> void:
	arena(120.0)
	var eye := spawn("EyeDrone", 4.4) as EyeDroneEnemy
	place(eye, 2.0, 4.4)
	check(eye.laser_every == 1 and eye.fan_every == 0, "Level 01 EyeDrone must use the laser after X=96")
	var warn := await wait_for(func(): return not eye._laser_warnings.is_empty(), 600)
	check(warn >= 0, "EyeDrone never charged its laser")
	await capture("eye_charge")
	var fire := await wait_for(func(): return eye.laser_active(), 120)
	check(fire >= int(EyeDroneEnemy.LASER_CHARGE * 60.0) - 2 and fire <= 50, "Laser charge must last 0.4-0.8 s (%d frames)" % fire)
	var start_angle: float = eye._laser_pivot.rotation.z
	await frames(10)
	await capture("eye_laser")
	var mid_angle: float = eye._laser_pivot.rotation.z
	check(absf(angle_difference(start_angle, mid_angle)) > deg_to_rad(5.0), "Laser must sweep")
	await wait_for(func(): return not eye.laser_active(), 120)
	check(eye.laser_count == 1, "One sweep per attack")
	report.append("eye laser charge=%.2fs sweep=%.2fs" % [fire / 60.0, EyeDroneEnemy.LASER_SWEEP])
	await clear()

func test_speeder() -> void:
	arena(160.0)
	var speeder := spawn("Speeder", 5.2) as SpeederEnemy
	bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 2.0, 0) # Lower than the Speeder: diagonal ram.
	check(speeder.ram_mode, "Level 01 Speeder must ram")
	var tele := await wait_for(func(): return speeder.current_state == SpeederEnemy.Phase.TELEGRAPH, 600)
	check(tele >= 0, "Speeder never telegraphed")
	await frames(20)
	await capture("speeder_flash")
	var ram := await wait_for(func(): return speeder.current_state == SpeederEnemy.Phase.DASH, 120)
	check(ram + 20 >= int(SpeederEnemy.RAM_TELEGRAPH * 60.0) - 2, "Ram before its telegraph")
	check(speeder._ram_dir.y < -0.05 and speeder.dash_hitbox.enabled, "Ram must aim at Bee (diagonal) and hurt")
	await frames(8)
	await capture("speeder_ram")
	var back := await wait_for(func(): return speeder.current_state == SpeederEnemy.Phase.RETREAT, 180)
	check(back >= 0 and not speeder.dash_hitbox.enabled, "Speeder must retreat harmlessly after the ram")
	report.append("speeder ram telegraph=%.2fs" % SpeederEnemy.RAM_TELEGRAPH)
	await clear()

func test_turret() -> void:
	arena(160.0)
	var turret := spawn("Turret") as GroundTurretEnemy
	place(turret, 1.5, -0.2)
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 1.6, 0)
	check(turret.mortar_mode, "Level 01 Turret must fire the mortar")
	var mark := await wait_for(func(): return turret._mortar_marker != null, 600)
	check(mark >= 0, "No mortar ground marker")
	await capture("turret_mark")
	var shell_node := await wait_for(func(): return not get_nodes_in_group("alien_mortar").is_empty(), 120)
	check(shell_node >= int(turret.windup_time * 60.0) - 2, "Mortar fired before its marker telegraph")
	var shell := get_nodes_in_group("alien_mortar")[0] as AlienMortarShell
	await frames(25)
	await capture("turret_shell")
	var shell_id := shell.get_instance_id()
	var landed := await wait_for(func(): return not is_instance_id_valid(shell_id) or (instance_from_id(shell_id) as AlienMortarShell).landed, 120)
	check(landed >= 0 and is_instance_valid(shell) and shell.landed and shell.find_child("EnergyPuddle", true, false) != null, "Shell must land and leave a puddle")
	await frames(5)
	await capture("turret_puddle")
	report.append("turret mortar marker=%.2fs before impact" % ((shell_node + 25 + landed) / 60.0))
	await clear()

func test_walker() -> void:
	arena(160.0)
	var walker := spawn("Walker") as GroundWalkerEnemy
	place(walker, 3.0, -0.2)
	bee.global_position = Vector3(stage.camera.global_position.x - 2.5, 2.4, 0)
	check(walker.low_burst, "Level 01 Walker must use the low burst")
	var shots: Array = []
	walker.projectile_fired.connect(func(p: AlienEnemyProjectile): shots.append(p.travel_direction))
	var charge := await wait_for(func(): return walker.current_state == GroundWalkerEnemy.State.WINDUP and not walker._sweeping, 900)
	check(charge >= 0, "Walker never charged")
	await capture("walker_charge")
	await wait_for(func(): return walker.low_burst_count >= 1 and shots.size() >= GroundWalkerEnemy.LOW_BURST_SHOTS, 240)
	check(shots.size() >= GroundWalkerEnemy.LOW_BURST_SHOTS, "Walker low burst must fire 3 shots")
	for d in shots.slice(0, 3):
		check(absf((d as Vector3).y) < 0.01, "Low burst shots must be horizontal")
	await capture("walker_burst")
	report.append("walker low burst windup=%.2fs" % GroundWalkerEnemy.LOW_BURST_WINDUP)
	await clear()

func test_probe() -> void:
	arena(160.0)
	var probe := spawn("Probe", 4.4) as AlienProbeRanged
	place(probe, 3.0, 4.4)
	check(probe.split_orb, "Level 01 Probe must fire the split orb")
	var orb_frame := await wait_for(func(): return probe.orb_count >= 1, 900)
	check(orb_frame >= 0, "Probe never fired its orb")
	var orb := get_nodes_in_group("alien_split_orbs")[0] as AlienEnemyProjectile
	var orb_id := orb.get_instance_id()
	await frames(int((AlienProbeRanged.ORB_SPLIT_DISTANCE / AlienProbeRanged.ORB_SPEED - AlienProbeRanged.ORB_SPLIT_WARN * 0.5) * 60.0))
	await capture("probe_orb_swell")
	check(is_instance_id_valid(orb_id) and orb.scale.x > AlienProbeRanged.ORB_SCALE * 1.05, "Orb must swell before splitting")
	await wait_for(func(): return not is_instance_id_valid(orb_id), 120)
	await frames(2)
	var splits := get_nodes_in_group("alien_projectiles").filter(func(p: Node): return not p.is_in_group("alien_split_orbs"))
	check(splits.size() == 2, "Orb must split into 2 (%d)" % splits.size())
	var angle := rad_to_deg((splits[0] as AlienEnemyProjectile).travel_direction.angle_to((splits[1] as AlienEnemyProjectile).travel_direction))
	check(absf(angle - 2.0 * AlienProbeRanged.ORB_SPLIT_ANGLE) < 1.0, "Split angle wrong (%.1f)" % angle)
	await frames(15)
	await capture("probe_split")
	report.append("probe orb split=%.1fm warn=%.2fs" % [AlienProbeRanged.ORB_SPLIT_DISTANCE, AlienProbeRanged.ORB_SPLIT_WARN])
	await clear()

# --- part B: boss v2 ---------------------------------------------------------------------------------------

func boss_phase(boss: UfoBoss01, wanted: int, limit := 300) -> bool:
	for i in limit:
		await frames(1)
		if boss.state == wanted:
			return true
	return false

func test_boss() -> void:
	await reload(func(): stage.checkpoint.debug_jump_to_boss())
	check(bee.spread_ammo == 0 and bee.bomb_charges == 2 and stage.checkpoint.debug_label.visible, "F9 must land with Base + 2 bombs")
	bee.set_physics_process(false)
	var boss: UfoBoss01 = null
	for i in 900:
		await frames(1)
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			boss = wave.boss
			break
	check(boss != null and boss.max_hp == BOSS_HP, "Boss did not start (HP %d)" % BOSS_HP)
	check(boss.side == 1.0 and boss.global_position.x > stage.camera.global_position.x, "First attempt enters from the right")
	check(stage.get("boss_arena_wide") == true, "Bee must get the whole width in the boss arena")
	await capture("boss_phase1_right")
	# Scripted fight: Bee hovers on the free side, damage counted but never lethal.
	bee.health.damage_blocked = false
	var taken := [0]
	bee.health.health_changed.connect(func(_c: int, _m: int, change: int): taken[0] += maxi(0, -change))
	var phase_switch_x := []
	for p in [UfoBoss01.State.PHASE_2, UfoBoss01.State.PHASE_3]:
		for i in 60 * 8:
			await frames(1)
			bee.health.current_health = bee.health.max_health
			bee.global_position = bee.global_position.move_toward(Vector3(stage.camera.global_position.x - boss.side * 4.0, 2.4 + sin(float(i) / 50.0) * 1.6, 0), 7.0 / 60.0) # Flies like a player (7 m/s), no teleports.
		if p == UfoBoss01.State.PHASE_3:
			for node in boss.shield_nodes.duplicate(): # LOTE 9: break the shield nodes first (phase 2 shield).
				node.health.take_damage(9999)
			await frames(2)
		var before := boss.side
		boss.health.take_damage(ceili(float(boss.health.current_health - int(boss.max_hp * (0.6 if p == UfoBoss01.State.PHASE_2 else 0.3))) / boss.health.damage_scale)) # LOTE 9: the open shield window doubles damage.
		check(boss.crossing and boss.side == -before, "Phase change must cross to the other side")
		check(await boss_phase(boss, p, 200), "Phase %d not reached" % (p - UfoBoss01.State.PHASE_1 + 1))
		phase_switch_x.append(signf(boss.global_position.x - stage.camera.global_position.x))
		if p == UfoBoss01.State.PHASE_2:
			await capture("boss_phase2_crossed")
	# Phase 3 for a while: beam, faster mines, side changes.
	var switches := boss.side_switches
	var mine_seen := false
	for i in 60 * 16:
		await frames(1)
		bee.health.current_health = bee.health.max_health
		bee.global_position = bee.global_position.move_toward(Vector3(stage.camera.global_position.x - boss.side * 4.0, 2.4 + sin(float(i) / 50.0) * 1.6, 0), 7.0 / 60.0)
		if not mine_seen and boss.live_mines().size() >= 2:
			mine_seen = true
			await frames(30)
			await capture("boss_mines")
	check(boss.side_switches - switches >= 2 and boss.beams >= 1, "Phase 3 must change side and use the beam")
	check(phase_switch_x[0] != phase_switch_x[1], "Phases 2 and 3 must be on different sides")
	# Fairness: every hazard announced >= MIN_TELEGRAPH; mines at their faster fuse in phase 3.
	var kinds := {}
	for h in boss.hazards:
		kinds[str(h["kind"])] = true
		check(float(h["telegraph"]) >= UfoBoss01.MIN_TELEGRAPH, "%s hazard with only %.2f s of telegraph" % [h["kind"], h["telegraph"]])
	check(kinds.has("aimed") and kinds.has("mine") and kinds.has("beam"), "Missing hazard kinds: %s" % str(kinds.keys()))
	check(float(UfoBoss01.MINE_FUSE[UfoBoss01.State.PHASE_3]) < float(UfoBoss01.MINE_FUSE[UfoBoss01.State.PHASE_2]), "Phase 3 mines must be faster")
	check(boss.untelegraphed_damage <= UNTELEGRAPHED_CAP, "Untelegraphed damage %d > %d" % [boss.untelegraphed_damage, UNTELEGRAPHED_CAP])
	# Drones from several entry points.
	var gates := {}
	for g in wave.minion_gates_used:
		gates[g % 3] = true
	check(not wave.minion_gates_used.is_empty() and gates.size() >= mini(2, wave.minion_gates_used.size()), "Minions must come from several points (%s; LOTE 9: phase 3 only, one at a time)" % str(gates.keys()))
	report.append("boss hazards=%d kinds=%s untelegraphed=%d dmg_taken=%d switches=%d gates=%s" % [boss.hazards.size(), str(kinds.keys()), boss.untelegraphed_damage, taken[0], boss.side_switches, str(gates.keys())])
	# Retry: Bee dies in the fight -> respawn at the start, the boss now enters from the LEFT.
	bee.health.damage_blocked = false
	bee.health.take_damage(99999)
	await frames(2)
	await reload(func(): stage.checkpoint.restart_level(false))
	bee.set_physics_process(false)
	var second: UfoBoss01 = null
	for i in 900:
		await frames(1)
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			second = wave.boss
			break
	check(second != null and second.side == -1.0 and second.global_position.x < stage.camera.global_position.x and second.health.current_health == BOSS_HP, "Retry must enter from the left with full HP")
	await capture("boss_retry_left")
	# Victory: mines defused, nothing hurts afterwards.
	second.health.take_damage(second.health.current_health - int(second.max_hp * 0.6))
	await boss_phase(second, UfoBoss01.State.PHASE_2, 200)
	await wait_for(func(): return second.mines_thrown >= 1, 900)
	for node in second.shield_nodes.duplicate(): # LOTE 9: the phase 2 shield blocks damage until its nodes break.
		node.health.take_damage(9999)
	await frames(2)
	second.health.take_damage(99999)
	await frames(2)
	check(second.live_mines().is_empty(), "Mines must be defused when the boss dies")

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	bind(current_scene)
	if wants("wasp"):
		await test_wasp()
	if wants("eye"):
		await test_eye()
	if wants("speeder"):
		await test_speeder()
	if wants("turret"):
		await test_turret()
	if wants("walker"):
		await test_walker()
	if wants("probe"):
		await test_probe()
	if wants("boss"):
		await test_boss()
	for line in report:
		print("COMBAT_VARIETY ", line)
	print("BEE_COMBAT_VARIETY_V01_OK")
	quit(0)
