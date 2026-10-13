extends SceneTree

# LOTE 10 C: four reproducible Normal/Easy x Base/Spread fights. Three taps/s, 60% aim, partial dodge.
# HP capacity is raised only to finish measurements; received damage and honey healing are counted separately.
# Each shot is indexed by creation order for alternating dodge decisions; instance-id parity is not reproducible.
# Run -- report for diagnostics; assertions are enabled in the final suite.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const BOT_TAPS_PER_SECOND := 3.0
const AIM_PATTERN := [true, true, false, true, false] # 60 % of the taps aimed at the target.
const DRIFT := 1.2 # m, slow vertical drift while holding the line.
const DRIFT_PERIOD := 3.2
## "Half-dodging": it reacts to every warning, but every other time only after LATE_FRACTION of the warning has gone by.
const LATE_FRACTION := 0.5
## Seconds ahead it looks for a shot on a collision course (half of them, see the loop).
const BULLET_LOOKAHEAD := 0.9
const TIME_SCALE := 1.0 # One physics step per frame: hitbox toggles and warnings match actual play.
const NORMAL_SECONDS := Vector2(70.0, 100.0) # Small variation from the Lote 17 camera composition adjustment.
const NORMAL_DAMAGE := Vector2(50.0, 70.0)
const EASY_DAMAGE_RATIO := 0.8 # EASY damage <= this x NORMAL damage.

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var report_only := false
var lines: Array[String] = []
var trace := false
var use_spread := false

func _initialize() -> void:
	BeeLevel01Controller.roster_only = false # LOTE 12: this test covers the pre-roster flow (alien enemies, frog, UFO), which stays intact behind LEVEL01_ROSTER_ONLY.
	report_only = "report" in OS.get_cmdline_user_args()
	trace = "trace" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if report_only:
		if not ok:
			print("WOULD FAIL: ", message)
		return
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func load_level() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await frames(3)
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(6)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func run() -> void:
	# Legacy UFO balance fixture predates Bee v02 (the UFO is outside the Level 01 roster).
	# Keep its original shooter geometry; v02 is covered by hero integration and the two garden-boss bots.
	BeeGameSettings.BEE_MODEL_VERSION = "v01"
	create_timer(1200.0, true, false, true).timeout.connect(func(): quit(1))
	Engine.max_physics_steps_per_frame = 16
	var normal: Array[Dictionary] = []
	for difficulty in [BeeGameSettings.NORMAL, BeeGameSettings.EASY]:
		BeeGameSettings.difficulty = difficulty
		for spread in [false, true]:
			if "first" in OS.get_cmdline_user_args() and (difficulty != BeeGameSettings.NORMAL or spread):
				continue
			use_spread = spread
			var label := str(difficulty).to_upper() + (" SPREAD" if spread else " BASE")
			var result := await fight(label)
			print("MEASURE ", label, " ", result)
			check(float(result.seconds) >= NORMAL_SECONDS.x and float(result.seconds) <= NORMAL_SECONDS.y, label + ": duration outside 75-100s: " + str(result.seconds))
			if difficulty == BeeGameSettings.NORMAL:
				normal.append(result)
				check(int(result.damage) >= NORMAL_DAMAGE.x and int(result.damage) <= NORMAL_DAMAGE.y, label + ": damage outside 50-70: " + str(result.damage))
			else:
				check(int(result.damage) < int(normal[int(spread)].damage), label + ": Easy must hurt less")
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	Engine.time_scale = 1.0
	for line in lines:
		print(line)
	print("BEE_BOSS_FIGHT_V04_OK four_combinations=OK")
	quit(0)


## Jumps straight to the fight, plays it with the bot and returns {seconds, damage, ...}.
func fight(label: String, with_bomb := false) -> Dictionary:
	await load_level()
	stage.scroll_speed = 0.0
	stage.distance = 340.0
	stage._update_camera_and_bounds()
	wave.event_index = BeeLevel01Controller.EVENTS_LEGACY.size()
	for unit in wave.active_units:
		unit.queue_free()
	wave.active_units.clear()
	bee.set_physics_process(false)
	bee.bomb_charges = 0 # Base weapon only (the bomb is measured separately).
	bee.spread_ammo = 0
	for group_name in ["Powerups", "Pollen", "PreBossSupply"]: # No pickups in the measured fight.
		var group := stage.get_node_or_null(group_name)
		if group != null:
			for item in group.get_children():
				item.queue_free()
	bee.health.max_health = 1000 # The fight always ends; the damage is measured.
	bee.health.current_health = 1000
	var damage := [0]
	var hits := {}
	bee.health.health_changed.connect(func(_c: int, _m: int, change: int):
		if change < 0:
			damage[0] += -change
			hits[-change] = int(hits.get(-change, 0)) + 1
			if trace:
				trace_hit(-change))
	bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 3.4, 0.0)
	wave._boss_breather_left = 0.01
	Engine.time_scale = TIME_SCALE
	var boss: UfoBoss01
	for i in 600:
		await physics_frame
		boss = wave.boss
		if boss != null and boss.state == UfoBoss01.State.PHASE_1:
			break
	check(boss != null and boss.state == UfoBoss01.State.PHASE_1, label + ": the fight did not start")
	var tick := TIME_SCALE / float(Engine.physics_ticks_per_second)
	var fire_left := 0.0
	var taps := 0
	var last_attack := -1
	var dodge_until := 0.0
	var dodge_goal := Vector3.ZERO
	var avoid_mines_until := 0.0
	var clock := 0.0
	var reacted := 0
	var held := 0
	var bomb_checked := false
	var bomb_fraction := 0.0
	var snapshot := {}
	var last_state := -1
	var phase_log: Array[String] = []
	var pending_at := -1.0
	var pending_kind := &"shots"
	var pending_combo := false
	var bullet_seen := {}
	var bullet_until := 0.0
	var bullet_goal := Vector3.ZERO
	while is_instance_valid(boss) and boss.state != UfoBoss01.State.DONE and clock < 400.0:
		await physics_frame
		clock += tick
		if is_instance_valid(boss) and boss.state != last_state:
			phase_log.append("%s@%.1fs dmg=%d hp=%d" % [UfoBoss01.State.keys()[boss.state], boss.fight_seconds, damage[0], boss.health.current_health])
			last_state = boss.state
		if is_instance_valid(boss) and boss.state == UfoBoss01.State.DEATH and snapshot.is_empty():
			snapshot = _snapshot(boss, damage[0])
		if not is_instance_valid(boss) or boss.state == UfoBoss01.State.DEATH:
			if is_instance_valid(boss) and boss.state == UfoBoss01.State.DEATH:
				continue
			break
		var cam_x := stage.camera.global_position.x
		# --- half-dodge: it reacts to every warning, but every other time LATE (only when the attack goes off) ---
		if boss.attacks_started != last_attack:
			last_attack = boss.attacks_started
			var late := last_attack % 2 == 1
			pending_kind = &"beam" if boss._attack_step == &"beam_tele" else (&"mines" if boss._attack_step == &"mine_tele" else &"shots")
			pending_combo = boss._pattern == &"combo"
			var lands := boss._attack_left + (UfoBossMine.TRAVEL if pending_kind == &"mines" else 0.0) # When it can first hurt.
			pending_at = clock + (lands * LATE_FRACTION if late else 0.0)
			if late:
				held += 1
			else:
				reacted += 1
		if pending_at >= 0.0 and clock >= pending_at:
			pending_at = -1.0
			if pending_kind == &"beam":
				var away := signf(bee.global_position.x - boss._beam_x)
				if away == 0.0:
					away = -boss.side
				if absf(boss._beam_x + away * 2.6 - cam_x) > 5.6:
					away = -away # The screen edge blocks that side: go the other way.
				dodge_goal = Vector3(boss._beam_x + away * 2.6, bee.global_position.y, 0.0)
				dodge_until = clock + maxf(boss._attack_left, 0.0) + (UfoBoss01.BEAM_ACTIVE if boss._attack_step == &"beam_tele" else 0.0) + 0.3
			elif pending_kind == &"shots":
				dodge_goal = Vector3(bee.global_position.x, bee.global_position.y + (2.4 if bee.global_position.y < 3.6 else -2.4), 0.0)
				dodge_until = clock + 0.9
			if pending_kind == &"mines" or pending_combo:
				avoid_mines_until = clock + 3.5
		# A player never stands still: a slow vertical drift around the saucer height.
		var goal := Vector3(cam_x - boss.side * 3.6, clampf(boss.global_position.y + DRIFT * sin(clock * TAU / DRIFT_PERIOD), 1.4, 6.0), 0.0)
		if clock < dodge_until:
			goal = dodge_goal
		if clock < avoid_mines_until or not boss.live_mines().is_empty() and clock < avoid_mines_until + 2.0:
			var push := Vector2.ZERO
			for mine in boss.live_mines():
				var m := (mine as UfoBossMine).spot()
				var d := Vector2(bee.global_position.x - m.x, bee.global_position.y - m.y)
				if d.length() < UfoBoss01.MINE_RADIUS + 0.9:
					push += d.normalized() * (UfoBoss01.MINE_RADIUS + 0.9 - d.length())
			if push.length() > 0.01:
				goal = bee.global_position + Vector3(push.normalized().x, push.normalized().y, 0.0) * 2.5
		# Bullets: it sees half of the shots coming at it (by instance id) and side-steps those.
		if clock >= bullet_until:
			for node in get_nodes_in_group("alien_projectiles"):
				var shot := node as AlienEnemyProjectile
				if shot == null or not is_instance_valid(shot) or shot.is_queued_for_deletion() :
					continue
				if not bullet_seen.has(shot.get_instance_id()):
					bullet_seen[shot.get_instance_id()] = bullet_seen.size()
				if int(bullet_seen[shot.get_instance_id()]) % 2 == 1:
					continue
				var v := Vector2(shot.travel_direction.x, shot.travel_direction.y) * shot.speed
				var r := Vector2(shot.global_position.x - bee.global_position.x, shot.global_position.y - bee.global_position.y)
				var closest_t := -r.dot(v) / maxf(v.length_squared(), 0.001)
				if closest_t <= 0.0 or closest_t > BULLET_LOOKAHEAD:
					continue
				var miss := r + v * closest_t
				if miss.length() > 0.8:
					continue
				var perp := Vector2(-v.y, v.x).normalized()
				if perp.dot(-miss) > 0.0:
					perp = -perp # Step to the side the shot is already missing towards.
				bullet_goal = bee.global_position + Vector3(perp.x, perp.y, 0.0) * 1.8
				bullet_until = clock + 0.45
				break
		if clock < bullet_until:
			goal = bullet_goal
		if boss.assault.busy:
			if boss.assault.kind == &"sweep":
				var gaps := boss.assault.gap_centres
				goal.y = gaps.x if absf(bee.global_position.y - gaps.x) < absf(bee.global_position.y - gaps.y) else gaps.y
			else:
				goal.y = clampf(boss.global_position.y + (2.0 if boss.global_position.y < 3.5 else -2.0), 1.4, 6.0)
		goal.x = clampf(goal.x, cam_x - 5.6, cam_x + 5.6)
		goal.y = clampf(goal.y, bee.flight_min.y, bee.flight_max.y)
		var p := bee.global_position
		p.x = move_toward(p.x, goal.x, bee.horizontal_speed * tick)
		p.y = move_toward(p.y, goal.y, bee.vertical_speed * tick)
		# Keep off the hull.
		if absf(p.x - boss.global_position.x) < 3.0 and absf(p.y - boss.global_position.y) < 1.4:
			p.x = boss.global_position.x - boss.side * 3.0 if absf(boss.global_position.x - cam_x) > 0.5 else p.x - 3.0
		bee.global_position = p
		# --- fire ---
		bee.spread_ammo = 9999 if use_spread else 0 # Measure sustained Spread, no automatic downgrade.
		fire_left -= tick
		if fire_left <= 0.0 and boss.is_active():
			fire_left = 1.0 / BOT_TAPS_PER_SECOND
			var aimed: bool = AIM_PATTERN[taps % AIM_PATTERN.size()]
			taps += 1
			var target_point := boss.global_position
			if boss.shield_up and not boss.shield_nodes.is_empty():
				var best := INF
				for node in boss.shield_nodes:
					if is_instance_valid(node) and node.global_position.distance_to(bee.global_position) < best:
						best = node.global_position.distance_to(bee.global_position)
						target_point = node.global_position
			elif not wave.boss_minions().is_empty(): # A player clears the minions first.
				var closest := INF
				for minion in wave.boss_minions():
					var d := minion.global_position.distance_to(bee.global_position)
					if d < closest:
						closest = d
						target_point = bee._target_point(minion)
			if not aimed:
				target_point += Vector3(0.0, 5.0, 0.0) # Goes wide.
			bee.set_aim_point(target_point)
			bee.fire()
		# One bomb on the vulnerable saucer (measured, then the fight goes on with Base only).
		if with_bomb and not bomb_checked and boss.state == UfoBoss01.State.PHASE_1 and boss.fight_seconds > 3.0:
			bomb_checked = true
			bee.bomb_charges = 1
			bee.global_position = boss.global_position - Vector3(boss.side * 2.0, 0.0, 0.0)
			var applied := [0]
			var bomb := bee.use_bomb()
			bomb.hit_confirmed.connect(func(hurt, amount):
				if hurt.health_component == boss.health: applied[0] += amount)
			bomb.detonate()
			await frames(18)
			bomb_fraction = float(applied[0]) / float(boss.max_hp)
			bee.global_position = Vector3(cam_x - boss.side * 3.6, 3.4, 0.0)
	var result := {"seconds": INF, "damage": damage[0]}
	if not snapshot.is_empty():
		var s := snapshot
		check(float(s["min_tele"]) >= UfoBoss01.MIN_TELEGRAPH - 0.001, label + ": an attack warned only %.2f s" % s["min_tele"])
		check(int(s["untelegraphed"]) <= UfoBoss01.CONTACT_DAMAGE, label + ": %d untelegraphed damage" % s["untelegraphed"])
		check(s["phases"] == [UfoBoss01.State.PHASE_1, UfoBoss01.State.PHASE_2, UfoBoss01.State.PHASE_3, UfoBoss01.State.PHASE_4, UfoBoss01.State.PHASE_5], label + ": phases %s" % str(s["phases"]))
		check(int(s["sweeps"]) >= 1 and int(s["rams"]) >= 1, label + ": new hull attacks must both occur")
		check(int(s["windows"]) >= 1 and int(s["raises"]) >= 1, label + ": the shield never dropped")
		check(not with_bomb or absf(bomb_fraction - UfoBoss01.BOMB_FRACTION) < 0.01, label + ": the bomb took %.1f %% of the UFO (want ~8 %%)" % (bomb_fraction * 100.0))
		result = {"seconds": float(s["seconds"]), "damage": int(s["damage"])}
		lines.append("BOSS %s fight=%.1fs damage=%d untelegraphed=%d hp=%d phases=%s shield raises=%d windows=%d absorbed=%d beams=%d mines=%d aimed=%d fans=%d minions=%d min_telegraph=%.2fs bomb=%.1f%% taps=%d reacted=%d held=%d" % [
				label, s["seconds"], s["damage"], s["untelegraphed"], s["hp"], str(s["phases"]), s["raises"], s["windows"],
				s["absorbed"], s["beams"], s["mines"], s["aimed"], s["fans"], s["minions"], s["min_tele"], bomb_fraction * 100.0, taps, reacted, held])
	else:
		lines.append("BOSS %s did not finish (clock %.0f s, damage %d)" % [label, clock, damage[0]])
		print("STUCK state=",boss.state," hp=",boss.health.current_health," nodes=",boss.shield_nodes.size()," tokens=",boss._hull_tokens," phases=",phase_log," vulnerable=",boss.is_vulnerable()," monitor=",boss.hurtbox.monitorable," bee=",bee.global_position," boss=",boss.global_position," minions=",wave.boss_minions().map(func(u): return [u.name,u.health.current_health,u.global_position]))
	lines.append("BOSS %s timeline: %s" % [label, " | ".join(phase_log)])
	lines.append("BOSS %s hits taken (damage: count): %s" % [label, str(hits)])
	# Let the death cinematic finish (complete flow).
	for i in 720: # LOTE 11: was 600, exactly the 20 m of scroll at 2 m/s; the death hit stop costs a few frames.
		await physics_frame
		if stage.sector_complete:
			break
	check(stage.sector_complete and stage.status.text.begins_with("SECTOR DESPEJADO"), label + ": no SECTOR DESPEJADO after the UFO")
	Engine.time_scale = 1.0
	return result


func _snapshot(boss: UfoBoss01, damage: int) -> Dictionary:
	var min_tele := INF
	for hazard in boss.hazards:
		min_tele = minf(min_tele, float(hazard["telegraph"]))
	return {"seconds": boss.fight_seconds, "damage": damage, "untelegraphed": boss.untelegraphed_damage, "hp": boss.max_hp,
			"sweeps": boss.assault.sweeps, "rams": boss.assault.rams, "phases": boss.phases_seen.duplicate(), "raises": boss.shield_raises, "windows": boss.shield_windows, "absorbed": boss.shield_absorbed,
			"beams": boss.beams, "mines": boss.mines_thrown, "aimed": boss.fired_aimed, "fans": boss.fired_fan, "minions": boss.summons, "min_tele": min_tele}


func trace_hit(amount: int) -> void:
	var boss := wave.boss
	if boss == null or not is_instance_valid(boss):
		return
	var nearest := INF
	for mine in boss.live_mines():
		nearest = minf(nearest, (mine as UfoBossMine).spot().distance_to(bee.global_position))
	print("HIT %d at t=%.1f state=%s step=%s pattern=%s bee=(%.1f,%.1f) boss=(%.1f,%.1f) cam=%.1f mines=%d nearest=%.2f" % [amount, boss.fight_seconds,
			UfoBoss01.State.keys()[boss.state], boss._attack_step, boss._pattern, bee.global_position.x, bee.global_position.y,
			boss.global_position.x, boss.global_position.y, stage.camera.global_position.x, boss.live_mines().size(), nearest])
