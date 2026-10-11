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
## Target (game seconds from start to the UFO entry).
const MIN_TO_BOSS := 320.0
const MAX_TO_BOSS := 420.0

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var report_only := false

func _initialize() -> void:
	report_only = "report" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	for i in 5:
		await physics_frame
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.health.damage_blocked = true
	bee.set_physics_process(false)
	Engine.time_scale = TIME_SCALE
	var act_times := {}
	var checkpoint_times: Array[String] = []
	var boss_at := -1.0
	var complete_at := -1.0
	var fire_left := 0.0
	var kills := [0]
	var quiet := 0.0 # Seconds with no threat on screen (breathers).
	var longest_quiet := 0.0
	var run_quiet := 0.0
	wave.director_moment.connect(func(_id): pass)
	var checkpoints := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	var seen_checkpoints := {}
	var retired_seen := {}
	var early_retire: Array[String] = []
	var stopped := 0.0 # Seconds with the scroll stopped (hard gates, the human, holds at 0).
	var slowed := 0.0
	var last_event := -1
	var event_log: Array[String] = []
	var tick := TIME_SCALE / float(Engine.physics_ticks_per_second) # Game seconds per physics frame (time scale applied).
	for frame in 60 * 900:
		await physics_frame
		var t := stage.get("elapsed_seconds") as float
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
		var threats := wave.active_units.filter(func(u): return is_instance_valid(u) and u.visible).size()
		if threats == 0 and wave.boss == null:
			run_quiet += tick
			quiet += tick
			longest_quiet = maxf(longest_quiet, run_quiet)
		else:
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
	if not report_only:
		check(boss_at >= MIN_TO_BOSS and boss_at <= MAX_TO_BOSS, "Time to the UFO %.0fs outside %.0f-%.0f s" % [boss_at, MIN_TO_BOSS, MAX_TO_BOSS])
		check(complete_at > boss_at, "Level must complete after the UFO")
		check(seen_checkpoints.size() >= 2, "Two checkpoints must be crossed (%d)" % seen_checkpoints.size())
		check(is_equal_approx(BeeLevel01Controller.LEVEL_SCROLL, 1.5), "Cruise scroll must be 1.5 m/s")
		check(wave.arena_log.size() == 3, "Three combat zones must play (%d)" % wave.arena_log.size())
		var zone_seconds := 0.0
		for zone in wave.arena_log:
			zone_seconds += float(zone["seconds"])
			check(float(zone["seconds"]) >= 20.0, "A combat zone ended too early: %s" % zone)
		check(zone_seconds >= 90.0, "New combat-zone content %.0f s < 90 s" % zone_seconds)
		check(early_retire.is_empty(), "Units left before their camera time: %s" % str(early_retire))
		check(longest_quiet <= 25.0, "A breather longer than 25 s feels empty (%.0f s)" % longest_quiet)
	print("PACING camera-time violations=%d retired_checked=%d" % [early_retire.size(), retired_seen.size()])
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
		if target.has_method("is_active") and not bool(target.call("is_active")):
			continue
		var hurtbox := target.get_node_or_null("Hurtbox3D") as Node3D
		var point := hurtbox.global_position if hurtbox != null else target.global_position
		var d := point.distance_to(bee.global_position)
		if d < best_d:
			best_d = d
			best = point
	return best
