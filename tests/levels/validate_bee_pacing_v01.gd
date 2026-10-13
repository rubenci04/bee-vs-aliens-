extends SceneTree

# LOTE 7 — PACING: plays Level 01 from the start with a simple bot and measures how long it lasts.
# Bot: invulnerable Bee (damage blocked) at the player anchor, follows the height of the nearest threat, AIMS FREELY (LOTE 7
# mouse aim, any direction) at the nearest threat on screen and taps fire
# BOT_TAPS_PER_SECOND times per second with the normal weapon and auto-aim (a reasonable, not perfect, player).
# Reports game seconds to: each act, each checkpoint, the UFO entry and Level Complete. Asserts the ~6 min target.
# Dev: -- report  (only prints, never fails on duration)

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const BOT_TAPS_PER_SECOND := 3.0
const BOT_SPEED := 6.0 # Bee's own vertical speed (LOTE 14: the expert bot flies at full speed)
const TIME_SCALE := 4.0
const BOT_DODGE_LOOKAHEAD := 0.65
const BOT_DODGE_HOLD := 0.55 # LOTE 13: a shorter hold = it re-reads the field more often (a player does not freeze for a second after dodging).
const BOT_WARNING_HOLD := 0.55
## LOTE 13: a reasonable player rolls (Shift, Lote 11) when a shot is about to hit: it is invulnerable for 0.35 s and destroys common shots.
const BOT_ROLL_WINDOW := 0.4
const BOT_DRIFT := 2.4
const BOT_DRIFT_PERIOD := 4.5
## Target (game seconds from start to the UFO entry).
const MIN_TO_BOSS := 330.0 # LOTE 13: to the TARANTULA (5.5-7 min).
const MAX_TO_BOSS := 420.0
## LOTE 14 · ETAPA 2.3: REAL DAMAGE. The expert bot (auto-aim, dodges ~70 % of the warned attacks, rolls, collects pollen) reaches the robot gate with a
## LOW point of MIN_HP_LOW..MIN_HP_HIGH HP and an average of AVG_HP_LOW..AVG_HP_HIGH; without the pollen it would have taken > MIN_TOTAL_DAMAGE damage.
const BOT_SEED := 1414
const BOT_WARNING_REACT := 0.7 ## Share of the warned attacks (lines, rings) the bot reacts to.
const BOT_SHOT_REACT := 1.0 ## Share of the incoming shots the bot notices (the rest connect).
const BOT_POLLEN_RANGE := 5.0
const HP_SAMPLE_SECONDS := 30.0
const MIN_HP_LOW := 30
const MIN_HP_HIGH := 55
const AVG_HP_LOW := 55.0
const AVG_HP_HIGH := 85.0 # Lote 15: small enemies die in 1-2 Base taps; allow a slightly healthier expert.
const MIN_TOTAL_DAMAGE := 100 ## NOT 200: Bee has 100 HP, so min HP >= 30 needs damage <= 70 + healing; with the scarce pollen (about 55 HP) the route can deal about 125 (see docs/INFORME_LOTE_14.md).
## LOTE 14 · ETAPA 2.1: gradual introduction.
const DEBUT_ORDER := ["FlyCommon", "Ant", "Ladybird", "Wasp", "FlyGreen", "FlyCloud", "WormA", "Snail", "StagBeetle", "WormB", "Spider"]
const FLIES_ONLY_UNTIL := 20.0 ## Game seconds with common flies only.
const SOLO_SECONDS := 8.0
const MIN_DEBUT_GAP := 14.0 ## Shortest allowed gap between two debuts (s); the plan is one every ~22-40 s.
const SPECIES_LIMITS := [[120.0, 2], [240.0, 3], [100000.0, 4]] ## [until game second, max species at once]
const DENSITY_FROM_SECONDS := 120.0 ## The density goals apply from minute 2; before it: >= 1 threat and never > MAX_QUIET s without one.
## LOTE 11: longest stretch with no visible threat (s).
const MAX_QUIET := 4.0 # LOTE 13: never more than 4 s without a threat (no breathing valley any more).
## LOTE 13: density targets (route, bosses excluded): fraction of the time with >= DENSITY_MIN_VISIBLE visible enemies, with a flyer AND a ground enemy, with enemy bullets on screen.
const DENSITY_MIN_VISIBLE := 3
const DENSITY_VISIBLE_FRACTION := 0.80
const DENSITY_MIXED_FRACTION := 0.70
const DENSITY_BULLET_FRACTION := 0.70
## LOTE 13: the director must not lag behind the scroll (the layout - checkpoints, supplies, gates - is tied to X): max metres an event may launch late.
const MAX_EVENT_LAG := 18.0

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var report_only := false
var trace := false
var rng := RandomNumberGenerator.new()
var warn_active := {} # unit id -> true while the unit shows a warning (one decision per warning episode)
var warn_react := {} # unit id -> whether the bot notices the current warning
var shot_react := {} # projectile id -> whether the bot notices it

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
	var past_entry := [false] # LOTE 12: true once the last encounter (boss or walking robot) has been launched.
	var lost := [0]
	var revives := [0]
	bee.health.health_changed.connect(func(_hp, _max, change):
		if change < 0 and not past_entry[0]:
			lost[0] -= change)
	var act_times := {}
	var checkpoint_times: Array[String] = []
	var boss_at := -1.0
	var hp_at_boss := 0
	var complete_at := -1.0
	var tarantula_at := -1.0
	var density_frames := 0
	var max_lag := 0.0
	var lag_log: Array = []
	var sum_lag := 0.0
	var lag_count := 0
	var density_three := 0
	var density_mixed := 0
	var mixed_frames := 0
	var density_bullets := 0
	var fire_left := 0.0
	var dodge_until := 0.0
	var dodge_y := 3.4
	var kills := [0]
	var quiet := 0.0 # Seconds with no threat on screen (breathers).
	var longest_quiet := 0.0
	var run_quiet := 0.0
	var quiet_spans: Array[Vector3] = [] # x = seconds, y = distance at the end, z = game time at the end
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
	rng.seed = BOT_SEED
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("seed="): # Dev: -- report seed=N measures the bot with another random stream.
			rng.seed = int(arg.get_slice("=", 1))
	var hp_curve: Array[String] = []
	var density_buckets := {} # 20 s bucket -> (frames with >= 3 visible, frames)
	var hp_sum := 0.0
	var hp_time := 0.0
	var hp_min := 100
	var next_sample := 0.0
	var species_peak := {} # window index -> most species alive at once
	var species_peak_at := {}
	var solo_violations: Array[String] = []
	var early_foreign: Array[String] = []
	var pollen_scan := 0.0
	var pollen_targets: Array[Node3D] = []
	for frame in 60 * 900:
		await physics_frame
		var t := stage.get("elapsed_seconds") as float
		if report_only and not bee.is_defeated and bee.health.current_health <= 20 and boss_at < 0.0:
			bee.health.restore_health(100) # Report mode: a bot that would die is revived (counted) so the whole route is measured.
			revives[0] += 1
			print("REVIVE at %.0fs d=%.0f" % [t, stage.distance])
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
			event_log.append("%d@%.0fs,d%.0f" % [last_event, t, stage.distance])
			if last_event > 0 and last_event <= BeeLevel01Controller.events_table().size(): # LOTE 13: how far behind its X the director launched this event (spawn caps hold the events back when the field is saturated).
				var lag: float = stage.distance - float(BeeLevel01Controller.events_table()[last_event - 1]["at"])
				max_lag = maxf(max_lag, lag)
				lag_log.append([lag, last_event - 1, BeeLevel01Controller.events_table()[last_event - 1]["label"], BeeLevel01Controller.events_table()[last_event - 1]["at"]])
				sum_lag += lag
				lag_count += 1
		if boss_at < 0.0 and (wave.boss != null or (BeeLevel01Controller.LEVEL01_ROSTER_ONLY and wave.event_index >= BeeLevel01Controller.EVENTS.size())):
			boss_at = t
			past_entry[0] = true
			hp_at_boss = bee.health.current_health
			bee.health.damage_blocked = true # Measure route on Normal; boss has its own battle suite.
		if tarantula_at < 0.0 and wave.tarantula != null:
			tarantula_at = t # LOTE 12 · ETAPA 3: the final boss walks in after the robot mini-boss.
		if stage.sector_complete:
			complete_at = t
			break
		if boss_at < 0.0: # LOTE 14: HP curve before the robot gate (every HP_SAMPLE_SECONDS, plus the weighted average and the low point).
			var hp := bee.health.current_health
			hp_sum += float(hp) * tick
			hp_time += tick
			hp_min = mini(hp_min, hp)
			if t >= next_sample:
				hp_curve.append("%.0fs:%d" % [next_sample, hp])
				next_sample += HP_SAMPLE_SECONDS
			var families_alive := {}
			for u in wave.active_units + wave.swarm_units:
				if is_instance_valid(u) and not bool(u.get_meta("level_retreat", false)):
					families_alive[str(u.name).get_slice("_", 0)] = true
			var limit_index := 0
			while t >= float(SPECIES_LIMITS[limit_index][0]):
				limit_index += 1
			if families_alive.size() > int(species_peak.get(limit_index, 0)):
				species_peak[limit_index] = families_alive.size()
				species_peak_at[limit_index] = "%.0fs %s" % [t, str(families_alive.keys())]
			if not wave.debut_log.is_empty():
				var last_debut: Dictionary = wave.debut_log[wave.debut_log.size() - 1]
				if wave._clock - float(last_debut["time"]) < SOLO_SECONDS:
					for family in families_alive:
						if family != last_debut["family"] and solo_violations.size() < 8:
							solo_violations.append("%s alive %.1fs into the debut of %s" % [family, wave._clock - float(last_debut["time"]), last_debut["family"]])
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
			for unit in wave.active_units:
				if is_instance_valid(unit) and unit is ControlledSpider and absf(unit.global_position.x - bee.global_position.x) < 2.6:
					goal_y = 1.4 # LOTE 14: the low lane under a hanging spider is the safe one (min_strike_y); an expert player knows it.
			pollen_scan -= tick # LOTE 14: the expert bot collects the pollen it can reach (the only healing).
			if pollen_scan <= 0.0:
				pollen_scan = 0.5
				pollen_targets.clear()
				for item in stage.find_children("*", "Area3D", true, false):
					if item is BeePollenPickup and not item.was_collected:
						pollen_targets.append(item)
			var pollen_best: Node3D
			var pollen_d := BOT_POLLEN_RANGE
			for item in pollen_targets:
				if is_instance_valid(item) and not bool(item.get("was_collected")) and BeeShmupFairness.is_on_screen(item, -0.3):
					var item_d := item.global_position.distance_to(bee.global_position)
					if item_d < pollen_d:
						pollen_d = item_d
						pollen_best = item
			if pollen_best != null:
				goal_y = pollen_best.global_position.y
				anchor_x = pollen_best.global_position.x
			if t >= dodge_until: # LOTE 13: read the warnings first (the lines and rings are the whole point of the telegraph).
				var warn_dir := _warning_dodge()
				if warn_dir != 0.0:
					dodge_y = bee.global_position.y + warn_dir * 2.0
					if dodge_y < 1.0 or dodge_y > 6.2:
						dodge_y = bee.global_position.y - warn_dir * 2.0
					dodge_until = t + BOT_WARNING_HOLD
			if t >= dodge_until:
				for node in get_nodes_in_group("alien_projectiles"):
					var shot := node as AlienEnemyProjectile
					if shot == null or shot.is_queued_for_deletion():
						continue
					if not shot_react.has(shot.get_instance_id()): # LOTE 14: a real player misses some shots.
						shot_react[shot.get_instance_id()] = rng.randf() < BOT_SHOT_REACT
					if not bool(shot_react[shot.get_instance_id()]):
						continue
					# LOTE 13: arcs too (a lobbed shot is predicted with its gravity): a reasonable player dodges pebbles and bubbles.
					var hit_t := -1.0
					var miss_y := 0.0
					var step := 0.05
					var look := step
					while look <= BOT_DODGE_LOOKAHEAD:
						var future := shot.predicted_position(look) - bee.global_position
						if Vector2(future.x, future.y).length() < 0.7:
							hit_t = look
							miss_y = future.y
							break
						look += step
					if hit_t > 0.0 and hit_t <= BOT_ROLL_WINDOW:
						bee.start_roll() # The dodge below still applies after the roll.
					if hit_t > 0.0:
						var away := -1.0 if miss_y > 0.0 else 1.0
						dodge_y = bee.global_position.y + away * 1.8
						if dodge_y < 1.0 or dodge_y > 6.2:
							dodge_y = bee.global_position.y - away * 1.8
						dodge_until = t + BOT_DODGE_HOLD
						break
			if t < dodge_until:
				goal_y = dodge_y
		bee._update_roll(tick) # The bot drives Bee itself (its physics process is off): the roll timers need their tick.
		if _contact_imminent():
			bee.start_roll() # A body about to touch Bee (ram, lunge, dash): roll through it.
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
		if boss_at < 0.0 and t >= DENSITY_FROM_SECONDS: # LOTE 13: density metrics (route only, bosses excluded).
			var visible_units := actors.filter(_visible_threat)
			var air := visible_units.filter(func(u): return not _is_ground_unit(u)).size()
			var ground := visible_units.size() - air
			var bullets := get_nodes_in_group("alien_projectiles").filter(func(s): return is_instance_valid(s) and not s.is_queued_for_deletion() and BeeShmupFairness.is_on_screen(s as Node3D, 0.0)).size()
			density_frames += 1
			if trace and frame % 60 == 0 and visible_units.size() < DENSITY_MIN_VISIBLE:
				var desc: Array[String] = []
				for u in actors:
					if is_instance_valid(u):
						desc.append("%s[vis=%s act=%s ret=%s x=%.1f]" % [u.name, str(_visible_threat(u)), str(u.call("is_active")) if u.has_method("is_active") else "-", str(u.get_meta("level_retreat", false)), u.global_position.x - stage.camera.global_position.x])
				print("LOWDENS t=%.0f arena=%s next_event=%d pend=%d : %s" % [t, str(wave.in_arena()), wave.event_index, wave._pending.size(), " ".join(desc)])
			var bucket := int(t / 20.0)
			density_buckets[bucket] = Vector2(density_buckets.get(bucket, Vector2.ZERO).x + (1.0 if visible_units.size() >= DENSITY_MIN_VISIBLE else 0.0), density_buckets.get(bucket, Vector2.ZERO).y + 1.0)
			if visible_units.size() >= DENSITY_MIN_VISIBLE:
				density_three += 1
			var in_solo := not wave.debut_log.is_empty() and wave._clock - float(wave.debut_log[wave.debut_log.size() - 1]["time"]) < SOLO_SECONDS
			if not in_solo: # LOTE 14: while a species debuts ALONE (8 s) a flyer + ground mix is impossible by definition.
				mixed_frames += 1
				if air >= 1 and ground >= 1:
					density_mixed += 1
			if bullets >= 1:
				density_bullets += 1
		var threats := actors.filter(_visible_threat).size()
		if threats == 0 and boss_at < 0.0:
			if run_quiet == 0.0:
				quiet_start = t
			run_quiet += tick
			quiet += tick
			longest_quiet = maxf(longest_quiet, run_quiet)
		else:
			if run_quiet > 0.0:
				quiet_spans.append(Vector3(run_quiet, stage.distance, t))
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
	print("PACING event_lag max=%.1f m mean=%.1f m (events launched after their X)" % [max_lag, sum_lag / maxf(float(lag_count), 1.0)])
	lag_log.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	print("PACING worst lags: ", str(lag_log.slice(0, 6)))
	print("PACING frog_damage=", frog_damage[0])
	print("PACING density visible>=3: %.0f %% · flyer+ground: %.0f %% · bullets: %.0f %% (frames %d) longest_quiet=%.1fs" % [100.0 * density_three / maxf(density_frames, 1), 100.0 * density_mixed / maxf(mixed_frames, 1), 100.0 * density_bullets / maxf(density_frames, 1), density_frames, longest_quiet])
	print("PACING robot_miniboss_fight=%.1fs (invulnerable bot) tarantula_entry=%.1fs (%.1f min) escort_waves=%d" % [wave.miniboss_seconds, tarantula_at, tarantula_at / 60.0, wave.escort_waves])
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	print("PACING juice score=%d best_combo=%d pollen=%d (pickups %d, liberations %d) frenzy=%d pollen_heals=%d magnet_pulls=%d hit_stops=%d" % [juice.score, juice.best_combo, juice.pollen_total, juice.pollen_from_pickups, juice.pollen_from_liberations, juice.frenzy_activations, juice.pollen_heals, juice.magnet_pulls, BeeJuice.hit_stops])
	var hp_avg := hp_sum / maxf(hp_time, 0.001)
	var bucket_text: Array[String] = []
	for bucket in density_buckets:
		bucket_text.append("%d:%.0f" % [int(bucket) * 20, 100.0 * density_buckets[bucket].x / maxf(density_buckets[bucket].y, 1.0)])
	print("PACING density>=3 by 20 s bucket (%): ", " ".join(bucket_text))
	print("PACING revives (report mode only)=", revives[0])
	print("PACING HP curve (every %.0f s): %s" % [HP_SAMPLE_SECONDS, " ".join(hp_curve)])
	print("PACING HP before the robot gate: min=%d avg=%.1f damage_taken=%d healed=%d (pollen bars %d, pollen total %d, lost to cap %d)" % [hp_min, hp_avg, lost[0], juice.pollen_healed, juice.pollen_heals, juice.pollen_total, juice.pollen_lost_to_cap])
	var debut_lines: Array[String] = []
	var first_spawn := {}
	for entry in wave.spawn_history:
		if not first_spawn.has(entry["family"]):
			first_spawn[entry["family"]] = float(entry["time"])
	for family in first_spawn:
		debut_lines.append("%s@%.0fs" % [family, first_spawn[family]])
	print("PACING first appearance: ", " ".join(debut_lines))
	print("PACING debuts (director): ", str(wave.debut_log.map(func(d): return "%s@%.0fs d=%.0f%s" % [d["family"], d["time"], d["distance"], " FORCED" if d["forced"] else ""])))
	print("PACING species at once, by window: ", str(species_peak), " ", str(species_peak_at), " solo violations: ", str(solo_violations))
	print("PACING normal_hp_lost_before_boss=%d hp_at_boss=%d route_units=%d" % [lost[0], hp_at_boss, wave.spawn_history.filter(func(e): return not bool(e.get("boss_minion", false))).size()])
	if not report_only:
		# LOTE 14 · ETAPA 2.3: real damage (the expert bot ends the route with a low point of 30-55 HP, an average of 55-80, and has taken > 200 damage).
		check(hp_min >= MIN_HP_LOW and hp_min <= MIN_HP_HIGH, "Lowest HP before the robot is %d (expected %d-%d)" % [hp_min, MIN_HP_LOW, MIN_HP_HIGH])
		check(hp_avg >= AVG_HP_LOW and hp_avg <= AVG_HP_HIGH, "Average HP before the robot is %.1f (expected %.0f-%.0f)" % [hp_avg, AVG_HP_LOW, AVG_HP_HIGH])
		check(lost[0] > MIN_TOTAL_DAMAGE, "Total damage taken before the robot is %d (expected > %d)" % [lost[0], MIN_TOTAL_DAMAGE])
		# LOTE 14 · ETAPA 2.1: gradual introduction.
		var order: Array[String] = []
		var order_times: Array[float] = []
		for family in first_spawn:
			if family in DEBUT_ORDER:
				order.append(str(family))
				order_times.append(float(first_spawn[family]))
		check(order == DEBUT_ORDER, "Species debut order %s (expected %s)" % [str(order), str(DEBUT_ORDER)])
		for entry in wave.spawn_history:
			if float(entry["time"]) < FLIES_ONLY_UNTIL:
				check(entry["family"] == "FlyCommon", "Only common flies in the first %.0f s (got %s at %.1fs)" % [FLIES_ONLY_UNTIL, entry["family"], entry["time"]])
		for i in range(1, order_times.size()):
			check(order_times[i] - order_times[i - 1] >= MIN_DEBUT_GAP, "Debuts of %s and %s only %.0f s apart (min %.0f s)" % [order[i - 1], order[i], order_times[i] - order_times[i - 1], MIN_DEBUT_GAP])
		check(solo_violations.is_empty(), "A new species did not debut alone for %.0f s: %s" % [SOLO_SECONDS, str(solo_violations)])
		check(wave.debut_log.size() == DEBUT_ORDER.size() - 1, "Every species after the flies is a director debut (%d)" % wave.debut_log.size())
		for index in species_peak:
			check(int(species_peak[index]) <= int(SPECIES_LIMITS[index][1]), "More species at once than allowed: %d (limit %d) %s" % [species_peak[index], SPECIES_LIMITS[index][1], species_peak_at[index]])
		for name in wave.species_seen:
			check(wave.species_seen[name] >= 0.0, "species seen")
		check(is_equal_approx(BeeLevel01Controller.SPECIES_NAME_SECONDS, 1.5), "The species name shows for 1.5 s")
		check(tarantula_at >= MIN_TO_BOSS and tarantula_at <= MAX_TO_BOSS, "LOTE 13: time to the tarantula %.0fs outside %.0f-%.0f s (5.5-7 min)" % [tarantula_at, MIN_TO_BOSS, MAX_TO_BOSS])
		check(boss_at >= 280.0 and boss_at < tarantula_at, "The robot gate comes before the tarantula (%.0fs)" % boss_at)
		check(complete_at > boss_at, "Level must complete after the last encounter")
		check(tarantula_at > boss_at and wave.tarantula_freed, "The tarantula must close Level 1 (LOTE 12 · ETAPA 3)")
		check(seen_checkpoints.size() >= 2, "Two checkpoints must be crossed (%d)" % seen_checkpoints.size())
		check(is_equal_approx(BeeLevel01Controller.LEVEL_SCROLL, 1.25), "Cruise scroll must be 1.25 m/s (LOTE 9)")
		check(wave.arena_log.size() == 3, "Three combat zones must play (%d)" % wave.arena_log.size())
		var zone_seconds := 0.0
		for zone in wave.arena_log:
			zone_seconds += float(zone["seconds"])
			check(float(zone["seconds"]) >= 20.0, "A combat zone ended too early: %s" % zone)
		check(zone_seconds >= 60.0, "Combat-zone content %.0f s < 60 s (LOTE 9: 3 zones of 2 waves)" % zone_seconds)
		check(early_retire.is_empty(), "Units left before their camera time: %s" % str(early_retire))
		# LOTE 13: no breathing valley any more: never more than MAX_QUIET s without a threat, anywhere on the route.
		for span in quiet_spans:
			check(span.x <= MAX_QUIET + 0.3, "%.1f s without a threat at X=%.0f (max %.1f s)" % [span.x, span.y, MAX_QUIET])
		check(longest_quiet <= MAX_QUIET + 0.3, "Longest quiet stretch %.1f s (max %.1f s)" % [longest_quiet, MAX_QUIET])
		check(max_lag <= MAX_EVENT_LAG, "An event launched %.1f m after its X (max %.1f m): the roster saturates the caps" % [max_lag, MAX_EVENT_LAG])
		var frames_total := maxf(float(density_frames), 1.0)
		check(float(density_three) / frames_total >= DENSITY_VISIBLE_FRACTION, ">= %d visible enemies only %.0f %% of the time (min %.0f %%)" % [DENSITY_MIN_VISIBLE, 100.0 * density_three / frames_total, 100.0 * DENSITY_VISIBLE_FRACTION])
		check(float(density_mixed) / maxf(mixed_frames, 1.0) >= DENSITY_MIXED_FRACTION, "Flyer + ground enemy together only %.0f %% of the time (min %.0f %%)" % [100.0 * density_mixed / maxf(mixed_frames, 1.0), 100.0 * DENSITY_MIXED_FRACTION])
		check(float(density_bullets) / frames_total >= DENSITY_BULLET_FRACTION, "Enemy bullets on screen only %.0f %% of the time (min %.0f %%)" % [100.0 * density_bullets / frames_total, 100.0 * DENSITY_BULLET_FRACTION])
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
		var point := bee._target_point(target) # Same point the game auto-aim uses (LOTE 12 · ETAPA 3: the robot mini-boss offers its body).
		var d := point.distance_to(bee.global_position)
		if d < best_d:
			best_d = d
			best = point
	return best

func _visible_threat(unit: Node3D) -> bool:
	if not is_instance_valid(unit) or not unit.is_visible_in_tree():
		return false
	if unit.get("buried") == true:
		return false # LOTE 13: a worm under the soil is not on screen.
	if unit.has_method("is_active") and not bool(unit.call("is_active")):
		return false
	var hurt := unit.get_node_or_null("Hurtbox3D") as Node3D
	var point := hurt.global_position if hurt != null else unit.global_position
	# Headless windows are square; project against the design aspect, as the director does.
	var local := stage.camera.global_transform.affine_inverse() * point
	var half_height := tan(deg_to_rad(stage.camera.fov) * 0.5) * -local.z
	return local.z < 0.0 and absf(local.y) <= half_height and absf(local.x) <= half_height * BeeLevel01Framing.view_aspect(root)


## Ground enemies: walkers, turrets and the ground fauna (a buried worm is not a visible threat).
func _is_ground_unit(unit: Node3D) -> bool:
	if unit is GroundWalkerEnemy or unit is GroundTurretEnemy:
		return true
	return unit.has_method("is_ground") and bool(unit.call("is_ground"))


## LOTE 13: reading the warnings like a player. Returns the vertical direction to dodge (+1 up / -1 down) when Bee stands on the
## line a warned attack will take (ram, lunge, dash, locked volley) or where a lobbed shot will land; 0.0 when she is safe.
func _warning_dodge() -> float:
	for unit in wave.active_units:
		if not is_instance_valid(unit):
			continue
		var id := unit.get_instance_id()
		var warned := false
		var result := 0.0
		if unit.has_method("warned_line"):
			var line: Array = unit.call("warned_line")
			if not line.is_empty():
				warned = true
				result = _line_miss(line[0], line[1], float(line[2]))
		for child in unit.get_children():
			if child is BeeImplantShooter and (child as BeeImplantShooter).warning != null:
				warned = true
				var shooter := child as BeeImplantShooter
				if shooter.family in BeeImplantShooter.LOB_FAMILIES:
					var offset := Vector2(bee.global_position.x - shooter.locked_point.x, bee.global_position.y - shooter.locked_point.y)
					if offset.length() < 1.7 and result == 0.0:
						result = 1.0 if offset.y >= 0.0 else -1.0
				else:
					var origin := unit.global_position + Vector3(0, 0.4, 0)
					var d := _line_miss(origin, origin + shooter.locked_aim.normalized() * 14.0, 1.2)
					if d != 0.0 and result == 0.0:
						result = d
		if not warned:
			warn_active.erase(id)
			continue
		if not warn_active.has(id): # LOTE 14: one decision per warning episode - the bot notices BOT_WARNING_REACT of them.
			warn_active[id] = true
			warn_react[id] = rng.randf() < BOT_WARNING_REACT
		if bool(warn_react.get(id, true)) and result != 0.0:
			return result
	return 0.0


## Vertical escape direction when Bee is within `half_width` of the segment from -> to (0.0 when clear).
func _line_miss(from: Vector3, to: Vector3, half_width: float) -> float:
	var a := Vector2(from.x, from.y)
	var b := Vector2(to.x, to.y)
	var p := Vector2(bee.global_position.x, bee.global_position.y)
	var ab := b - a
	if ab.length_squared() < 0.0001:
		return 0.0
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var closest := a + ab * t
	var off := p - closest
	if off.length() >= half_width:
		return 0.0
	return 1.0 if off.y >= 0.0 else -1.0


## An enemy attack body (ram, lunge, dash, eruption) is live and within touching distance of Bee.
func _contact_imminent() -> bool:
	for unit in wave.active_units:
		if not is_instance_valid(unit):
			continue
		var hitbox: Variant = unit.get("attack_hitbox")
		if hitbox is DamageHitbox3D and (hitbox as DamageHitbox3D).enabled and (hitbox as Node3D).global_position.distance_to(bee.global_position) < 1.5:
			return true
	return false
