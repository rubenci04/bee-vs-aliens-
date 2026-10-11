extends SceneTree

# BEE UFO BOSS 01 — FIRST CONTACT. Flow, approach, arena lock, phases, patterns, fairness, Bomb,
# death cleanup, level completion only after the kill, checkpoint retry and full restart.
# With a rendering window it also saves review captures in res://dev/ufo_boss_01_review/.

## LOTE 9 · ETAPA C: the NODO ALIEN has 1200 HP and 4 phases (was 500 HP, 3 phases).
const BOSS_HP := 1200
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const REVIEW := "res://dev/ufo_boss_01_review/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var boss: UfoBoss01
var shots: Array[Dictionary] = []
var peak_projectiles := 0

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
		peak_projectiles = maxi(peak_projectiles, get_nodes_in_group(UfoBoss01.PROJECTILE_GROUP).size())

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(REVIEW + name + ".png"))

func bind_level() -> void:
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func load_level() -> void:
	var level := LEVEL.instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	bind_level()

## Jump to the end of Level 01: every encounter consumed, camera near the sector end.
func to_boss_entry(distance := 352.0) -> void:
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.distance - 3.2, 3.4, 0)

func wait_state(wanted: int, limit := 900) -> bool:
	for i in limit:
		await frames(1)
		if wave.boss != null and is_instance_valid(wave.boss) and wave.boss.state == wanted:
			return true
	return false

func on_fired(projectile: AlienEnemyProjectile, pattern: StringName) -> void:
	shots.append({"projectile": projectile, "pattern": pattern, "direction": projectile.travel_direction,
		"origin": projectile.global_position, "bee": bee.global_position, "frame": Engine.get_physics_frames()})

func run() -> void:
	create_timer(240.0, true, false, true).timeout.connect(func(): quit(1))
	await load_level()
	bee.set_physics_process(false) # The test flies Bee by hand.
	bee.health.damage_blocked = true # Survival is not under test until the cleanup checks.
	to_boss_entry()

	# 1. Breather: arena locked, no boss yet, no completion, no new encounters.
	await frames(20)
	check(wave.boss == null and stage.scroll_speed == 0.0 and not stage.sector_complete and not wave.is_complete(), "Breather/arena lock missing")
	check(wave.active_units.is_empty(), "Encounters spawned after the final event")
	var start_distance := stage.distance

	# 2. Approach: far in Z, invulnerable, silent, 2-4 s.
	var approach_frames := 0
	for i in 300:
		await frames(1)
		if wave.boss != null:
			break
	boss = wave.boss
	check(boss != null and boss.state == UfoBoss01.State.APPROACH, "UFO did not start its approach")
	boss.projectile_fired.connect(on_fired)
	check(boss.global_position.z < -30.0, "Approach must start deep in Z (z=%.1f)" % boss.global_position.z)
	await capture("01_ufo_far")
	check(boss.health.take_damage(500) == 0 and not boss.is_active() and not boss.is_in_group("bee_auto_aim_targets") and not boss.hurtbox.monitorable, "UFO vulnerable during approach")
	var halfway_capture := false
	while boss.state == UfoBoss01.State.APPROACH and approach_frames < 400:
		await frames(1)
		approach_frames += 1
		if not halfway_capture and boss.global_position.z > -14.0:
			halfway_capture = true
			await capture("02_ufo_approach")
	var approach_seconds := approach_frames / 60.0
	check(approach_seconds >= 2.0 and approach_seconds <= 4.0, "Approach lasted %.2f s" % approach_seconds)
	check(shots.is_empty() and get_nodes_in_group(UfoBoss01.PROJECTILE_GROUP).is_empty(), "UFO fired during the approach")
	check(boss.state == UfoBoss01.State.PHASE_1 and is_zero_approx(boss.global_position.z), "UFO did not enter the play plane")
	await capture("03_ufo_enters_plane")
	check(boss.is_vulnerable() and boss.health_bar_visible() and boss.health.current_health == boss.max_hp and boss.max_hp == BOSS_HP, "Fight did not start correctly")
	var visible_half := BeeShmupFairness.visible_half_width(stage.camera, boss.global_position, BeeLevel01Framing.view_aspect(root))
	check(absf(boss.global_position.x - stage.camera.global_position.x) < visible_half - 1.5, "UFO arena position off screen")

	# 3. Phase 1 (LOTE 9): fast aimed bursts of 4 at Bee's position at the moment of each shot + an aimed fan every third attack.
	bee.global_position = Vector3(stage.distance - 4.0, 2.2, 0)
	for i in 420:
		await frames(1)
		bee.global_position.y = 2.2 + sin(float(i) / 40.0) * 1.2 # Moving Bee: aim must follow the fire moment.
	check(stage.distance == start_distance and wave.active_units.is_empty(), "Arena lock broken during the fight")
	var aimed := shots.filter(func(s: Dictionary): return s["pattern"] == &"aimed")
	check(aimed.size() >= 6 and shots.all(func(s: Dictionary): return s["pattern"] == &"aimed" or s["pattern"] == &"fan") and boss.mines_thrown == 0 and boss.beams == 0, "Phase 1 must only fire aimed bursts and aimed fans (%d shots)" % shots.size())
	for s in aimed:
		var wanted := Vector3(s["bee"].x - s["origin"].x, s["bee"].y - s["origin"].y, 0).normalized()
		check((s["direction"] as Vector3).angle_to(wanted) < deg_to_rad(4.0), "Aimed shot not aimed at Bee's position at fire time")
	var tracked: AlienEnemyProjectile = aimed.back()["projectile"]
	if is_instance_valid(tracked):
		var before: Vector3 = tracked.travel_direction
		await frames(20)
		check(not is_instance_valid(tracked) or tracked.travel_direction.is_equal_approx(before), "Boss projectile is homing")
	await capture("04_phase1")

	# 4. Projectile fairness: lethal sphere below the visible core; boss on screen when firing.
	var sample := (load("res://scenes/levels/ufo_boss_projectile.tscn") as PackedScene).instantiate() as AlienEnemyProjectile
	var lethal := ((sample.get_node("Hitbox3D/CollisionShape3D") as CollisionShape3D).shape as SphereShape3D).radius
	var core := ((sample.get_node("Visual") as MeshInstance3D).mesh as SphereMesh).radius
	check(lethal < core and lethal >= core * 0.55, "Boss projectile collider must be slightly smaller than its core")
	check((((sample.get_node("Visual") as MeshInstance3D).mesh as SphereMesh).material as StandardMaterial3D).render_priority >= 50, "Boss projectile must draw over VFX")
	sample.free()
	check(BeeShmupFairness.can_fire(boss), "UFO outside the readable area")

	# 5. Bomb damages the boss with its normal radius/damage and does not cancel projectiles.
	bee.global_position = Vector3(boss.global_position.x - 2.4, boss.global_position.y, 0)
	await frames(1)
	bee.collect_bomb()
	var hp := boss.health.current_health
	var live_before := boss.live_projectiles().size()
	check(bee.use_bomb() != null, "Bomb refused")
	await frames(4)
	check(hp - boss.health.current_health == roundi(boss.max_hp * UfoBoss01.BOMB_FRACTION), "LOTE 9: the bomb must take BOMB_FRACTION of the UFO (%d)" % (hp - boss.health.current_health))
	check(boss.live_projectiles().size() >= mini(live_before, 1) or live_before == 0, "Bomb must not cancel boss projectiles")
	bee.global_position = Vector3(stage.distance - 4.0, 2.2, 0)

	# 6. Phase 2 at 70 %: crossing to the other side, then the SHIELD (nodes) while MINES alternate with aimed bursts (LOTE 9).
	shots.clear()
	var side_before := boss.side
	boss.health.take_damage(boss.health.current_health - int(boss.max_hp * 0.6))
	await frames(1)
	check(boss.state == UfoBoss01.State.TRANSITION and boss.transitions == 1 and boss.crossing and boss.side == -side_before, "Phase 2 must start with a side change")
	check(await wait_state(UfoBoss01.State.PHASE_2, 150), "Phase 2 not reached")
	check(signf(boss.global_position.x - stage.camera.global_position.x) == boss.side, "Saucer did not reach the other side")
	var mines_seen := false
	for i in 600:
		await frames(1)
		if not mines_seen and boss.live_mines().size() >= 2:
			mines_seen = true
			await frames(40)
			await capture("05_phase2_mines")
	check(boss.mines_thrown >= 2 and shots.any(func(s: Dictionary): return s["pattern"] == &"aimed"), "Phase 2 must alternate mines and aimed bursts (%d mines)" % boss.mines_thrown)
	check(boss.shield_up and not boss.is_vulnerable() and boss.health.take_damage(50) == 0 and boss.shield_nodes.size() == UfoBoss01.SHIELD_NODES, "Phase 2: shielded, nodes up, no damage")
	for node in boss.shield_nodes.duplicate():
		node.health.take_damage(9999)
	await frames(2)
	check(not boss.shield_up and boss.shield_window_open() and boss.is_vulnerable() and boss.shield_windows == 1, "Breaking every node must open the vulnerability window")

	# 7. Phase 3 at 40 %: faster movement, beam + faster mines + aimed, frequent side changes, moderate projectiles.
	shots.clear()
	peak_projectiles = 0
	var switches_before := boss.side_switches
	boss.health.take_damage(ceili(float(boss.health.current_health - int(boss.max_hp * 0.3)) / boss.health.damage_scale)) # LOTE 9: the open shield window doubles damage.
	check(await wait_state(UfoBoss01.State.PHASE_3, 150), "Phase 3 not reached")
	check(float(UfoBoss01.PHASE_TUNING[UfoBoss01.State.PHASE_3][1]) < float(UfoBoss01.PHASE_TUNING[UfoBoss01.State.PHASE_1][1]), "Phase 3 must move faster")
	var phase3_captured := false
	for i in 900:
		await frames(1)
		if not phase3_captured and i > 120 and boss.live_projectiles().size() + boss.live_mines().size() >= 4:
			phase3_captured = true
			await capture("06_phase3")
	check(boss.beams >= 1 and boss.mines_thrown >= 4 and shots.any(func(s: Dictionary): return s["pattern"] == &"aimed"), "Phase 3 must combine beam, mines and aimed bursts")
	check(boss.side_switches - switches_before >= 2, "Phase 3 must change side often (%d)" % (boss.side_switches - switches_before))
	check(peak_projectiles >= 3 and peak_projectiles <= 15, "Peak boss projectiles out of range (%d)" % peak_projectiles)
	var phase3_peak := peak_projectiles

	# 7b. LOTE 9 — Phase 4 (fury) under 15 %: beam and mines together, red core, faster side changes.
	boss.health.take_damage(boss.health.current_health - int(boss.max_hp * 0.1))
	check(await wait_state(UfoBoss01.State.PHASE_4, 150), "Phase 4 not reached")
	var combo_seen := false
	for i in 900:
		await frames(1)
		if boss._pattern == &"combo" and boss._attack_step == &"beam_tele" and boss.live_mines().size() >= 1:
			combo_seen = true
			break
	check(combo_seen and boss.is_fury(), "Phase 4 must combine the beam and mines")
	check(boss.phases_seen == [UfoBoss01.State.PHASE_1, UfoBoss01.State.PHASE_2, UfoBoss01.State.PHASE_3, UfoBoss01.State.PHASE_4], "The 4 phases must happen in order (%s)" % str(boss.phases_seen))

	# 8. Damage feedback reuses HitFlash.
	var flashes := boss.hit_flash.activation_count
	boss.health.take_damage(5)
	check(boss.hit_flash.activation_count == flashes + 1, "No hit flash on the UFO")
	await capture("07_damage_feedback")

	# 9. Death: attacks off at once, its projectiles cleared, completion only after the sequence.
	await frames(30)
	check(boss.live_projectiles().size() > 0, "Need live projectiles to verify the death clear")
	var fired_before := shots.size()
	boss.health.take_damage(99999)
	check(boss.state == UfoBoss01.State.DEATH and not boss.is_active() and not boss.health_bar_visible(), "Death state wrong")
	await frames(1)
	check(boss.live_projectiles().is_empty(), "Boss projectiles not cleared on death")
	check(not wave.is_complete() and not stage.sector_complete, "Level completed before the death sequence ended")
	await frames(30)
	await capture("08_death")
	check(shots.size() == fired_before, "UFO fired after dying")
	var death_frames := 31 # Already elapsed since the killing blow (1 + 30 frames above).
	while is_instance_valid(boss) and death_frames < 400:
		await frames(1)
		death_frames += 1
	check(not is_instance_valid(boss) and death_frames / 60.0 >= UfoBoss01.death_seconds() - 0.3 and death_frames / 60.0 <= UfoBoss01.death_seconds() + 0.8, "Death sequence lasted %.2f s (LOTE 9: longer cinematic, %.2f s)" % [death_frames / 60.0, UfoBoss01.death_seconds()])
	check(wave.boss_defeated and wave.is_complete(), "Boss death did not complete the wave")
	for i in 600:
		await frames(1)
		if stage.sector_complete:
			break
	check(stage.sector_complete and stage.status.text.begins_with("SECTOR DESPEJADO"), "Level did not complete after the boss")
	await capture("09_level_complete")
	print("UFO_BOSS_FLOW_OK approach=%.2fs peak_phase3=%d death=%.2fs" % [approach_seconds, phase3_peak, death_frames / 60.0])

	# 10. Checkpoint retry: die against the boss after the checkpoint, R rebuilds everything.
	await load_after(func(): stage.checkpoint.restart_level(true))
	check(stage.distance < 1.0 and wave.boss == null, "Full restart did not reset the level")
	wave.resume_after_checkpoint(190.5) # Earlier encounters consumed, human gone, as in a real run.
	stage.distance = 190.5
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(190.5, 4.0, 0)
	await frames(3)
	check(stage.checkpoint.checkpoint_active, "Checkpoint did not activate")
	to_boss_entry()
	check(await wait_state(UfoBoss01.State.PHASE_1, 600), "Boss did not start after the checkpoint")
	boss = wave.boss
	boss.health.take_damage(300)
	await frames(200)
	check(boss.live_projectiles().size() > 0 or boss.fired_aimed > 0 or boss.beams > 0, "Boss idle before the retry")
	bee.health.damage_blocked = false
	bee.health.take_damage(99999)
	await frames(2)
	check(bee.is_defeated and not boss.is_physics_processing(), "Boss must freeze when Bee dies")
	await load_after(func(): stage.checkpoint.restart_level(false))
	check(stage.distance >= 352.0 and stage.distance < 353.0 and stage.checkpoint.checkpoint_active and wave.event_index == BeeLevel01Controller.EVENTS.size(), "Retry did not resume at the start of the boss fight (%.2f)" % stage.distance)
	await assert_clean("checkpoint retry")
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	to_boss_entry()
	check(await wait_state(UfoBoss01.State.PHASE_1, 600), "Boss not rebuilt after the checkpoint retry")
	check(wave.boss.health.current_health == wave.boss.max_hp and wave.boss.transitions == 0, "Boss kept HP/phase from the previous attempt")
	check(get_nodes_in_group("bee_auto_aim_targets").filter(func(n: Node): return n is UfoBoss01).size() == 1, "Duplicated boss after retry")

	# 11. Full restart while the boss is alive: nothing survives.
	await load_after(func(): stage.checkpoint.restart_level(true))
	check(stage.distance < 1.0 and not stage.checkpoint.checkpoint_active, "Full restart kept the checkpoint")
	await assert_clean("full restart")
	print("UFO_BOSS_01_OK approach=%.2fs peak_projectiles=%d" % [approach_seconds, phase3_peak])
	quit(0)

func load_after(action: Callable) -> void:
	action.call()
	for i in 10:
		await process_frame
	await frames(3)
	bind_level()

func assert_clean(label: String) -> void:
	check(wave.boss == null and not wave.boss_defeated, label + ": boss state survived")
	check(get_nodes_in_group(UfoBoss01.PROJECTILE_GROUP).is_empty(), label + ": boss projectiles survived")
	check(root.find_children("UfoBoss01", "", true, false).is_empty() and root.find_children("HoverLoop", "", true, false).is_empty(), label + ": boss node or hover loop survived")
	check(root.find_children("BossHealthBar", "", true, false).is_empty(), label + ": health bar survived")
	check(root.find_children("UfoSting", "", true, false).is_empty() and root.find_children("UfoDeath", "", true, false).is_empty(), label + ": UFO sting/explosion audio survived")
	var voices := get_nodes_in_group("bee_audio_voice").filter(func(v: Node): return str(v.get_meta("cue", "")).begins_with("ufo_"))
	check(voices.is_empty(), label + ": UFO audio survived")
