extends SceneTree

# LOTE 7 — PACING: plays Level 01 from the start with a simple bot and measures how long it lasts.
# Bot: invulnerable Bee (damage blocked) at the player anchor, follows the height of the nearest threat, AIMS FREELY (LOTE 7
# mouse aim, any direction) at the nearest threat on screen and taps fire
# BOT_TAPS_PER_SECOND times per second with the normal weapon and auto-aim (a reasonable, not perfect, player).
# Reports game seconds to: each act, each checkpoint, the UFO entry and Level Complete. Asserts the ~6 min target.
# Dev: -- report  (only prints, never fails on duration)

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const BOT_TAPS_PER_SECOND := 3.0
const BOT_SPEED := 5.0
const TIME_SCALE := 4.0
const BOT_DODGE_LOOKAHEAD := 0.65
const BOT_DODGE_HOLD := 1.0
const BOT_DRIFT := 2.4
const BOT_DRIFT_PERIOD := 4.5
## Target (game seconds from start to the UFO entry).
const MIN_TO_BOSS := 330.0 # LOTE 9: 5.5-6.5 min (was 320-420 s).
const MAX_TO_BOSS := 420.0 # LOTE 11: 5.5-7 min.
## LOTE 11: HP lost on Normal before the UFO (frog included).
const MIN_ROUTE_DAMAGE := 45
const MAX_ROUTE_DAMAGE := 70
## LOTE 11: longest stretch with no visible threat (s).
const MAX_QUIET := 5.0

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var report_only := false
var trace := false

func _initialize() -> void:
	report_only = "report" in OS.get_cmdline_user_args()
	trace = "trace" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	for i in 5:
		await physics_frame
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.health.damage_blocked = false
	# LOTE 11: the route is measured without hit stop (the bot counts fixed time steps) and without honey mode (an optional power-up:
	# with it the bot reaches the UFO ~20-30 s earlier and loses ~25 HP less). `-- honey` plays with it and only reports.
	BeeJuice.hit_stop_enabled = false
	if not "honey" in OS.get_cmdline_user_args():
		bee.honey_seconds = 0.0
	bee.set_physics_process(false)
	Engine.time_scale = TIME_SCALE
	var lost := [0]
	bee.health.health_changed.connect(func(_hp, _max, change):
		if change < 0 and wave.boss == null:
			lost[0] -= change)
	var act_times := {}
	var checkpoint_times: Array[String] = []
	var boss_at := -1.0
	var hp_at_boss := 0
	var complete_at := -1.0
	var fire_left := 0.0
	var dodge_until := 0.0
	var dodge_y := 3.4
	var kills := [0]
	var quiet := 0.0 # Seconds with no threat on screen (breathers).
	var longest_quiet := 0.0
	var run_quiet := 0.0
	wave.director_moment.connect(func(_id): pass)
	var checkpoints := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	var seen_checkpoints := {}
	var retired_seen := {}
	var tracked_hitboxes := {}
	var frog_damage := [0]
	var frog_tracked := false
	var quiet_start := 0.0
	var early_retire: Array[String] = []
	var stopped := 0.0 # Seconds with the scroll stopped (hard gates, the human, holds at 0).
	var slowed := 0.0
	var last_event := -1
	var event_log: Array[String] = []
	var tick := TIME_SCALE / float(Engine.physics_ticks_per_second) # Game seconds per physics frame (time scale applied).
	for frame in 60 * 900:
		await physics_frame
		var t := stage.get("elapsed_seconds") as float
		check(not bee.is_defeated, "Normal bot defeated at %.1fs; damage=%d" % [t, lost[0]])
		if trace and frame % 900 == 0:
			var names := []
			for u in wave.active_units:
				names.append(str(u.name) if is_instance_valid(u) else "freed")
			print("TRACE t=%.0f d=%.1f ev=%d arena=%s boss=%s units=%s pending=%d" % [t, stage.distance, wave.event_index, wave.in_arena(), str(wave.boss.state) if wave.boss != null and is_instance_valid(wave.boss) else "-", str(names), wave._pending.size()])
		if trace:
			for area in stage.find_children("*", "Area3D", true, false):
				if area is DamageHitbox3D and area.team_id == &"alien" and not tracked_hitboxes.has(area.get_instance_id()):
					tracked_hitboxes[area.get_instance_id()] = true
					var label := str(area.attacker.name) if is_instance_valid(area.attacker) else str(area.name)
					area.hit_confirmed.connect(func(hurt, amount):
						if hurt.owner_entity == bee: print("BOT_HIT %s -%d @%.1f" % [label, amount, stage.elapsed_seconds]))
		act_times[wave.current_act] = act_times.get(wave.current_act, t)
		for x in checkpoints.checkpoint_list():
			if stage.distance >= float(x) and not seen_checkpoints.has(x):
				seen_checkpoints[x] = true
				checkpoint_times.append("X=%d @%.0fs" % [int(x), t])
		if wave.boss == null:
			if stage.scroll_speed <= 0.01:
				stopped += tick
			elif stage.scroll_speed < wave.level_scroll() - 0.01:
				slowed += tick
		if wave.event_index != last_event:
			last_event = wave.event_index
			event_log.append("%d@%.0f" % [last_event, t])
		if wave.boss != null and boss_at < 0.0:
			boss_at = t
			hp_at_boss = bee.health.current_health
			bee.health.damage_blocked = true # Measure route on Normal; boss has its own battle suite.
		if stage.sector_complete:
			complete_at = t
			break
		# Bot movement: stay near the anchor, follow the nearest threat's height.
		var anchor_x := stage.camera.global_position.x + BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.view_aspect(root)) - 0.5
		var goal_y := 3.4
		var nearest := INF
		for unit in wave.active_units + wave.swarm_units:
			if not is_instance_valid(unit) or not unit.visible:
				continue
			var d := absf(unit.global_position.x - bee.global_position.x)
			if d < nearest:
				nearest = d
				goal_y = clampf(unit.global_position.y + 0.3, 1.2, 6.2)
		if wave.boss != null and is_instance_valid(wave.boss) and wave.boss.is_active():
			goal_y = clampf(wave.boss.global_position.y, 1.5, 6.0)
			anchor_x = stage.camera.global_position.x - wave.boss.side * 3.6 # LOTE 9: the free side, off the hull and the shield.
		if wave.boss == null:
			# Ordinary player: keep moving, react to near body threats and incoming bolts.
			goal_y = clampf(3.6 + BOT_DRIFT * sin(t * TAU / BOT_DRIFT_PERIOD), 1.3, 6.0)
			for unit in wave.active_units:
				if is_instance_valid(unit) and unit.global_position.distance_to(bee.global_position) < 2.0:
					goal_y = 5.8 if unit.global_position.y < 3.5 else 1.4
			if t >= dodge_until:
				for node in get_nodes_in_group("alien_projectiles"):
					var shot := node as AlienEnemyProjectile
					if shot == null or shot.is_queued_for_deletion():
						continue
					var v := Vector2(shot.travel_direction.x, shot.travel_direction.y) * shot.speed
					var r := Vector2(shot.global_position.x - bee.global_position.x, shot.global_position.y - bee.global_position.y)
					var closest := -r.dot(v) / maxf(v.length_squared(), 0.001)
					if closest > 0.0 and closest < BOT_DODGE_LOOKAHEAD and (r + v * closest).length() < 0.7:
						var miss_y := (r + v * closest).y
						var away := -1.0 if miss_y > 0.0 else 1.0
						dodge_y = bee.global_position.y + away * 1.8
						if dodge_y < 1.0 or dodge_y > 6.2:
							dodge_y = bee.global_position.y - away * 1.8
						dodge_until = t + BOT_DODGE_HOLD
						break
			if t < dodge_until:
				goal_y = dodge_y
		var p := bee.global_position
		p.x = move_toward(p.x, clampf(anchor_x, bee.flight_min.x, bee.flight_max.x), BOT_SPEED * tick)
		p.y = move_toward(p.y, clampf(goal_y, bee.flight_min.y, bee.flight_max.y), BOT_SPEED * tick)
		bee.global_position = p
		var aim_target: Variant = _nearest_target()
		if aim_target != null:
			bee.set_aim_point(aim_target)
		else:
			bee.clear_aim()
			bee.facing_x = 1.0
		bee.refresh_auto_aim()
		fire_left -= tick
		if fire_left <= 0.0:
			fire_left = 1.0 / BOT_TAPS_PER_SECOND
			bee.fire()
		for unit in wave.active_units:
			if is_instance_valid(unit) and bool(unit.get_meta("level_retreat", false)) and not retired_seen.has(unit.get_instance_id()):
				retired_seen[unit.get_instance_id()] = true
				var family := str(unit.name).get_slice("_", 0)
				var age := wave._clock - float(unit.get_meta("level_born"))
				var walker := unit is GroundWalkerEnemy or unit is GroundTurretEnemy or (unit is AssetFauna and (unit as AssetFauna).is_ground())
				if not walker and age < wave.camera_time(family) - 0.2:
					early_retire.append("%s %.1fs" % [unit.name, age])
		var actors := wave.active_units + wave.swarm_units
		var frog := stage.get_node("ScaleEvent").frog as Node3D
		if is_instance_valid(frog):
			actors.append(frog)
			if not frog_tracked:
				frog_tracked = true
				(frog as BeeGardenToadEncounter)._tongue_box.hit_confirmed.connect(func(hurt, amount):
					if hurt.owner_entity == bee: frog_damage[0] += amount)
		var threats := actors.filter(_visible_threat).size()
		if threats == 0 and boss_at < 0.0:
			if run_quiet == 0.0:
				quiet_start = t
			run_quiet += tick
			quiet += tick
			longest_quiet = maxf(longest_quiet, run_quiet)
		else:
			if trace and run_quiet > 4.0:
				print("QUIET %.1f..%.1f (%.1fs) d=%.1f ev=%d" % [quiet_start, t, run_quiet, stage.distance, wave.event_index])
			run_quiet = 0.0
	Engine.time_scale = 1.0
	var acts := []
	for act in act_times:
		acts.append("act%d@%.0fs" % [act, act_times[act]])
	print("PACING acts: ", " ".join(acts))
	print("PACING checkpoints: ", ", ".join(checkpoint_times))
	print("PACING events(index@s): ", " ".join(event_log))
	var spawned := 0
	for family in wave.spawned_by_family:
		spawned += int(wave.spawned_by_family[family])
	print("PACING scroll stopped=%.0fs slowed=%.0fs spawned=%d escaped(retired)=%d shots=%d zones=%s" % [stopped, slowed, spawned, wave.escaped_count, bee.shots_fired, str(wave.arena_log)])
	print("PACING boss_entry=%.1fs (%.1f min) complete=%.1fs (%.1f min) distance_scroll=%.1f m/s quiet_total=%.0fs longest_quiet=%.1fs" % [
			boss_at, boss_at / 60.0, complete_at, complete_at / 60.0, stage.scroll_speed, quiet, longest_quiet])
	print("PACING frog_damage=", frog_damage[0])
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	print("PACING juice score=%d best_combo=%d pollen=%d (pickups %d, liberations %d) honey_activations=%d magnet_pulls=%d hit_stops=%d" % [juice.score, juice.best_combo, juice.pollen_total, juice.pollen_from_pickups, juice.pollen_from_liberations, juice.honey_activations, juice.magnet_pulls, BeeJuice.hit_stops])
	print("PACING normal_hp_lost_before_boss=%d hp_at_boss=%d route_units=%d" % [lost[0], hp_at_boss, wave.spawn_history.filter(func(e): return not bool(e.get("boss_minion", false))).size()])
	if not report_only:
		check(lost[0] >= MIN_ROUTE_DAMAGE and lost[0] <= MAX_ROUTE_DAMAGE, "Route damage %d outside %d-%d HP (LOTE 11, frog included)" % [lost[0], MIN_ROUTE_DAMAGE, MAX_ROUTE_DAMAGE])
		check(boss_at >= MIN_TO_BOSS and boss_at <= MAX_TO_BOSS, "Time to the UFO %.0fs outside %.0f-%.0f s" % [boss_at, MIN_TO_BOSS, MAX_TO_BOSS])
		check(complete_at > boss_at, "Level must complete after the UFO")
		check(seen_checkpoints.size() >= 2, "Two checkpoints must be crossed (%d)" % seen_checkpoints.size())
		check(is_equal_approx(BeeLevel01Controller.LEVEL_SCROLL, 1.25), "Cruise scroll must be 1.25 m/s (LOTE 9)")
		check(wave.arena_log.size() == 3, "Three combat zones must play (%d)" % wave.arena_log.size())
		var zone_seconds := 0.0
		for zone in wave.arena_log:
			zone_seconds += float(zone["seconds"])
			check(float(zone["seconds"]) >= 20.0, "A combat zone ended too early: %s" % zone)
		check(zone_seconds >= 60.0, "Combat-zone content %.0f s < 60 s (LOTE 9: 3 zones of 2 waves)" % zone_seconds)
		check(early_retire.is_empty(), "Units left before their camera time: %s" % str(early_retire))
		check(longest_quiet <= MAX_QUIET, "LOTE 11: %.1f s without a visible threat (max %.1f s)" % [longest_quiet, MAX_QUIET])
		check(wave.max_alive_route <= BeeLevel01Controller.MAX_ON_SCREEN, "LOTE 9: %d enemies at once on the route (max %d)" % [wave.max_alive_route, BeeLevel01Controller.MAX_ON_SCREEN])
		check(wave.max_alive_arena <= BeeLevel01Controller.MAX_ON_SCREEN_ARENA, "LOTE 9: %d enemies at once in a zone (max %d)" % [wave.max_alive_arena, BeeLevel01Controller.MAX_ON_SCREEN_ARENA])
	print("PACING camera-time violations=%d retired_checked=%d" % [early_retire.size(), retired_seen.size()])
	print("PACING max_alive route=%d arena=%d (popcorn included)" % [wave.max_alive_route, wave.max_alive_arena])
	print("BEE_PACING_V01_OK")
	quit(0)

## The closest live target on screen (any direction), as a player with a mouse would pick it; null = none (auto-aim).
func _nearest_target() -> Variant:
	var best: Variant = null
	var best_d := INF
	for node in get_nodes_in_group("bee_auto_aim_targets"):
		var target := node as Node3D
		if target == null or not target.is_visible_in_tree() or not BeeShmupFairness.is_on_screen(target, -0.4):
			continue
		if target is UfoBoss01 and (target as UfoBoss01).shield_up:
			continue # LOTE 9: the shield is up - shoot its nodes.
		if target.has_method("is_active") and not bool(target.call("is_active")):
			continue
		var hurtbox := target.get_node_or_null("Hurtbox3D") as Node3D
		var point := hurtbox.global_position if hurtbox != null else target.global_position
		var d := point.distance_to(bee.global_position)
		if d < best_d:
			best_d = d
			best = point
	return best

func _visible_threat(unit: Node3D) -> bool:
	if not is_instance_valid(unit) or not unit.is_visible_in_tree():
		return false
	if unit.has_method("is_active") and not bool(unit.call("is_active")):
		return false
	var hurt := unit.get_node_or_null("Hurtbox3D") as Node3D
	var point := hurt.global_position if hurt != null else unit.global_position
	# Headless windows are square; project against the design aspect, as the director does.
	var local := stage.camera.global_transform.affine_inverse() * point
	var half_height := tan(deg_to_rad(stage.camera.fov) * 0.5) * -local.z
	return local.z < 0.0 and absf(local.y) <= half_height and absf(local.x) <= half_height * BeeLevel01Framing.view_aspect(root)
