extends SceneTree

# LOTE 12 · ETAPA 3 — the TARANTULA, final boss of Level 1 (TarantulaBoss01). Structure + four reproducible bot fights
# (Normal/Easy x Base/Spread), same bot rules as validate_bee_boss_fight_v04 (UFO): three taps/s, 60 % aimed, it reacts to every
# warning but every other time LATE (half of the warning gone), it sees half of the shots coming. A reasonable player aims at the
# implant once the legs are armoured (phase 2+), clears the flies first and does not chase the small spiders.
# HP capacity is raised only to finish the measurement; the received damage is counted (honey not subtracted).
# Targets: 75-100 s with Base and with sustained Spread (budget), Normal damage 50-70, Easy hurts less, every attack warned
# >= 0.42 s, the charge warned 0.8 s, the roll never destroys the stomp wave or the charge (it still destroys web shots).
# Dev: -- report (prints, never fails) · -- first (Normal Base only) · -- trace

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const BOT_TAPS_PER_SECOND := 3.0
const AIM_PATTERN := [true, true, false, true, false]
const LATE_FRACTION := 0.5
const BULLET_LOOKAHEAD := 0.9
const DRIFT := 1.0
const DRIFT_PERIOD := 3.4
const FIGHT_SECONDS := Vector2(70.0, 100.0) # LOTE 14: 75 -> 70 (the nerfed summons / spiders of the roster make the bot kill it ~7 s sooner; the boss itself is untouched)
const NORMAL_DAMAGE := Vector2(35.0, 70.0) # LOTE 14: 50 -> 35 (the wider camera and the real-damage roster make the spiders and summons hit less)

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var report_only := false
var trace := false
var use_spread := false
var lines: Array[String] = []

func _initialize() -> void:
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
	create_timer(1500.0, true, false, true).timeout.connect(func(): quit(1))
	Engine.max_physics_steps_per_frame = 16
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	await test_structure()
	await test_roll_rules()
	var normal: Array[Dictionary] = []
	for difficulty in [BeeGameSettings.NORMAL, BeeGameSettings.EASY]:
		BeeGameSettings.difficulty = difficulty
		for spread in [false, true]:
			if "first" in OS.get_cmdline_user_args() and (difficulty != BeeGameSettings.NORMAL or spread):
				continue
			use_spread = spread
			var label := ("NORMAL" if difficulty == BeeGameSettings.NORMAL else "EASY") + (" SPREAD" if spread else " BASE")
			var result := await fight(label)
			print("MEASURE ", label, " ", result)
			check(float(result.seconds) >= FIGHT_SECONDS.x and float(result.seconds) <= FIGHT_SECONDS.y, label + ": duration outside 70-100 s: " + str(result.seconds))
			if difficulty == BeeGameSettings.NORMAL:
				normal.append(result)
				check(int(result.damage) >= NORMAL_DAMAGE.x and int(result.damage) <= NORMAL_DAMAGE.y, label + ": damage outside 35-70: " + str(result.damage))
			elif normal.size() > int(spread):
				check(int(result.damage) < int(normal[int(spread)].damage), label + ": Easy must hurt less")
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	Engine.time_scale = 1.0
	for line in lines:
		print(line)
	print("BEE_TARANTULA_BOSS_V01_OK")
	quit(0)


## Jumps to the arena after the robot gate and lets the tarantula walk in.
func start_arena() -> TarantulaBoss01:
	await load_level()
	stage.scroll_speed = 0.0
	stage.distance = 296.0
	stage._update_camera_and_bounds()
	wave.event_index = BeeLevel01Controller.EVENTS_ROSTER.size()
	for unit in wave.active_units:
		unit.queue_free()
	wave.active_units.clear()
	bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 3.4, 0.0)
	wave._tarantula_breather_left = 0.01
	var boss: TarantulaBoss01
	for i in 600:
		await physics_frame
		boss = wave.tarantula
		if boss != null and boss.state == TarantulaBoss01.State.PHASE_1:
			break
	return boss


func test_structure() -> void:
	var boss := await start_arena()
	check(boss != null and boss.state == TarantulaBoss01.State.PHASE_1, "The tarantula must walk in and start phase 1")
	check(BeeLevel01Controller.roster_only and wave.boss == null, "Level 1 has no UFO: the tarantula is its boss")
	check(boss.global_position.x > stage.camera.global_position.x, "It enters from the right")
	check(boss.health_bar_visible() and boss.is_in_group("bee_auto_aim_targets"), "Bar and auto-aim")
	check(boss.max_hp == BeeGameSettings.scaled_hp(1200), "Normal HP")
	check(boss.implant_hurtbox != null and boss._implant_core != null and boss._implant_core.visible, "The implant is its own piece of the model")
	for plate in TarantulaBoss01.HIDDEN_PLATES:
		for mesh: Node3D in boss.model.find_children(plate + "*", "MeshInstance3D", true, false):
			check(not mesh.visible, "Alien plate %s must be hidden (roster: implant only)" % mesh.name)
	check(wave.animals_total >= 1, "The tarantula counts as an animal")
	# Bomb: BOMB_FRACTION of its life.
	bee.bomb_charges = 1
	bee.global_position = boss.global_position + Vector3(-3.0, 1.4, 0.0)
	var applied := [0]
	var bomb := bee.use_bomb()
	bomb.hit_confirmed.connect(func(hurt, amount):
		if hurt.health_component == boss.health: applied[0] += amount)
	bomb.global_position = boss.global_position + Vector3(0.0, 1.4, 0.0)
	bomb.detonate()
	await frames(18)
	check(absf(float(applied[0]) / float(boss.max_hp) - TarantulaBoss01.BOMB_FRACTION) < 0.01, "The bomb takes ~8 %% (took %.1f %%)" % (float(applied[0]) / boss.max_hp * 100.0))
	# Phase 2: legs armoured (absorbed, no damage), the implant exposed after a big attack takes x2.
	boss.health.current_health = int(boss.max_hp * 0.74)
	boss.health.take_damage(1)
	await frames(90)
	check(boss.state == TarantulaBoss01.State.PHASE_2 and boss.legs_armoured, "Phase 2 armours the legs (state %d)" % boss.state)
	var before := boss.health.current_health
	var probe := DamageHitbox3D.new()
	probe.damage = 10
	probe.team_id = &"bee"
	stage.add_child(probe)
	probe.set_enabled(true)
	boss.legs_hurtbox.receive_hit(probe)
	check(boss.health.current_health == before and boss.legs_absorbed == 1, "Armoured legs absorb the shot")
	boss._expose_implant()
	boss._hull_tokens = 100.0
	probe.set_enabled(true)
	var dealt := boss.implant_hurtbox.receive_hit(probe)
	check(dealt == 20 and boss.implant_exposed, "Exposed implant takes x2 (%d)" % dealt)
	probe.queue_free()
	# Liberation: it is freed (never explodes), walks away, the level completes with LIBERADOS.
	var freed_before := wave.liberated_count
	boss.health.take_damage(99999)
	await frames(2)
	check(boss.state == TarantulaBoss01.State.FREED and wave.liberated_count == freed_before + 1, "Breaking the implant frees it")
	check(not boss.health_bar_visible() and not boss.is_in_group("bee_auto_aim_targets"), "Freed: no bar, no target")
	check(get_nodes_in_group("bee_liberated_text").size() >= 1, "LIBERADO text")
	for i in 900:
		await physics_frame
		if stage.sector_complete:
			break
	check(stage.sector_complete and stage.status.text.begins_with("SECTOR DESPEJADO · LIBERADOS"), "SECTOR DESPEJADO · LIBERADOS n/N after it leaves (%s)" % stage.status.text)
	check(wave.tarantula_freed and wave.roster_complete, "Level complete")
	lines.append("TARANTULA structure bomb=%.1f%% legs_absorbed=%d exposed_x2=OK freed=OK banner='%s'" % [float(applied[0]) / boss.max_hp * 100.0 if is_instance_valid(boss) else 8.0, 1, stage.status.text])


## The roll (Lote 11) still destroys the web shots but never the stomp wave or the charge.
func test_roll_rules() -> void:
	var boss := await start_arena()
	boss.set_physics_process(false)
	bee.set_physics_process(false)
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 1.0, 0.0)
	bee.health.damage_blocked = false
	bee._roll_cooldown_left = 0.0
	# Web shot into a rolling Bee: destroyed.
	var web := boss._spawn_web(bee.global_position + Vector3(1.0, 0.0, 0.0), Vector3.LEFT, 6.0)
	bee.start_roll()
	await frames(14)
	check(not is_instance_valid(web) or web.is_queued_for_deletion(), "The roll destroys a web shot")
	# Stomp wave into a rolling Bee: Bee is invulnerable for the roll, the wave goes on.
	bee._roll_cooldown_left = 0.0
	var wave_node := BeeGroundShockwave.launch(stage, boss, bee.global_position.x + 1.2, bee.global_position.x - 8.0, 8, 7.0, 1.3)
	bee.start_roll()
	await frames(12)
	check(is_instance_valid(wave_node) and not wave_node.is_queued_for_deletion() and wave_node.hitbox.enabled, "The roll must not destroy the stomp wave")
	wave_node.stop()
	# Charge box: never a projectile.
	check(not (boss._charge_box.get_parent() is AlienEnemyProjectile), "The charge is not a projectile")
	bee.health.damage_blocked = true


## Plays a whole fight with the bot; returns {seconds, damage}.
func fight(label: String) -> Dictionary:
	var boss := await start_arena()
	check(boss != null, label + ": no tarantula")
	bee.set_physics_process(false)
	bee.bomb_charges = 0
	bee.spread_ammo = 0
	bee.honey_seconds = 0.0
	for group_name in ["Powerups", "Pollen", "PreBossSupply"]:
		var group := stage.get_node_or_null(group_name)
		if group != null:
			for item in group.get_children():
				item.queue_free()
	bee.health.max_health = 1000
	bee.health.current_health = 1000
	bee.health.damage_blocked = false
	var damage := [0]
	var hits := {}
	var by_kind := {}
	bee.health.health_changed.connect(func(_c: int, _m: int, change: int):
		if change < 0:
			damage[0] += -change
			hits[-change] = int(hits.get(-change, 0)) + 1
			var kind := str(boss.attack_kind) if is_instance_valid(boss) else "?"
			for minion in wave.boss_minions(): # Who hit: a fly in contact, a web shot in contact, else the attack in progress.
				if is_instance_valid(minion) and minion.global_position.distance_to(bee.global_position) < 1.6:
					kind = "fly"
			for node in get_nodes_in_group(TarantulaBoss01.PROJECTILE_GROUP):
				if is_instance_valid(node) and (node as Node3D).global_position.distance_to(bee.global_position) < 0.9:
					kind = "web"
			for spider in (boss.live_spiders() if is_instance_valid(boss) else []):
				if (spider as Node3D).global_position.distance_to(bee.global_position) < 1.0:
					kind = "spider"
			by_kind[kind] = int(by_kind.get(kind, 0)) + -change
			if trace:
				print("HIT -%d t=%.1f step=%s bee=(%.1f,%.1f) boss=%.1f" % [-change, boss.fight_seconds, boss._step, bee.global_position.x, bee.global_position.y, boss.global_position.x]))
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var clock := 0.0
	var fire_left := 0.0
	var taps := 0
	var last_attack := -1
	var react_at := -1.0
	var react_kind := &"none"
	var dodge_until := 0.0
	var dodge_goal := Vector3.ZERO
	var bullet_seen := {}
	var bullet_until := 0.0
	var bullet_goal := Vector3.ZERO
	var snapshot := {}
	var phase_log: Array[String] = []
	var last_state := -1
	while is_instance_valid(boss) and boss.state != TarantulaBoss01.State.DONE and clock < 400.0:
		await physics_frame
		clock += tick
		if not is_instance_valid(boss):
			break
		if boss.state != last_state:
			phase_log.append("%s@%.1fs dmg=%d hp=%d hits(body/implant/legs)=%d/%d/%d" % [TarantulaBoss01.State.keys()[boss.state], boss.fight_seconds, damage[0], boss.health.current_health,
					boss.body_hurtbox.hits_taken, boss.implant_hurtbox.hits_taken, boss.legs_hurtbox.hits_taken])
			last_state = boss.state
		if boss.state == TarantulaBoss01.State.FREED:
			if snapshot.is_empty():
				snapshot = _snapshot(boss, damage[0])
			continue
		var cam_x := stage.camera.global_position.x
		var side := boss.side
		if trace and int(clock * 60.0) % 300 == 0:
			print("T t=%.0f hp=%d step=%s kind=%s bee=(%.1f,%.1f) boss=(%.1f) side=%d tokens=%.1f hits b/i/l=%d/%d/%d exposed=%s" % [boss.fight_seconds, boss.health.current_health, boss._step, boss.attack_kind,
					bee.global_position.x - cam_x, bee.global_position.y, boss.global_position.x - cam_x, int(side), boss._hull_tokens,
					boss.body_hurtbox.hits_taken, boss.implant_hurtbox.hits_taken, boss.legs_hurtbox.hits_taken, boss.implant_exposed],
					" flies=", wave.boss_minions().map(func(m): return "%s(%.1f,%.1f) hp=%d active=%s depth=%s" % [m.name, m.global_position.x - cam_x, m.global_position.y, m.health.current_health, m.is_active(), CinematicDepthEntry.is_in_depth(m)]))
		# --- reactions: every warning, every other one LATE ---
		if boss.attacks_started != last_attack:
			last_attack = boss.attacks_started
			react_kind = boss.attack_kind
			var late := last_attack % 2 == 1
			react_at = clock + (boss.attack_left * LATE_FRACTION if late else 0.0)
		var goal := Vector3(cam_x - side * 3.4, clampf(2.9 + DRIFT * sin(clock * TAU / DRIFT_PERIOD), 1.4, 5.6), 0.0)
		if react_at >= 0.0 and clock >= react_at:
			react_at = -1.0
			match react_kind:
				&"stomp":
					dodge_goal = Vector3(bee.global_position.x, 3.0, 0.0)
					dodge_until = clock + boss.attack_left + 1.6
				&"charge", &"double_charge":
					dodge_goal = Vector3(bee.global_position.x, TarantulaBoss01.CHARGE_TOP + 1.2, 0.0)
					dodge_until = clock + boss.attack_left + 1.4 + (1.6 if react_kind == &"double_charge" else 0.0)
				&"threads":
					dodge_goal = Vector3(bee.global_position.x, TarantulaBoss01.THREAD_BOTTOM - 1.1, 0.0)
					dodge_until = clock + boss.attack_left + 3.2
				&"curtain":
					var best := 3.0
					var best_d := INF
					for gap in boss.curtain_gaps:
						if absf(gap - bee.global_position.y) < best_d:
							best_d = absf(gap - bee.global_position.y)
							best = gap
					dodge_goal = Vector3(bee.global_position.x, best, 0.0)
					dodge_until = clock + boss.attack_left + 3.0
				_:
					pass
		if clock < dodge_until:
			goal = dodge_goal
		# Hanging spiders: step out of their column.
		for spider in boss.live_spiders():
			if absf(spider.global_position.x - bee.global_position.x) < 1.1 and spider.is_active():
				goal.x = spider.global_position.x + (1.8 if bee.global_position.x >= spider.global_position.x else -1.8)
		# A fly about to ram: move off its height (like the route bot).
		for minion in wave.boss_minions():
			if is_instance_valid(minion) and minion.global_position.distance_to(bee.global_position) < 2.0 and clock >= dodge_until:
				goal.y = clampf(bee.global_position.y + (1.8 if minion.global_position.y < bee.global_position.y else -1.8), 1.4, 5.8)
		# Shots: it sees half of them.
		if clock >= bullet_until:
			for node in get_nodes_in_group("alien_projectiles"):
				var shot := node as AlienEnemyProjectile
				if shot == null or not is_instance_valid(shot) or shot.is_queued_for_deletion():
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
					perp = -perp
				bullet_goal = bee.global_position + Vector3(perp.x, perp.y, 0.0) * 1.6
				bullet_until = clock + 0.4
				break
		if clock < bullet_until and clock >= dodge_until:
			goal = bullet_goal
		goal.x = clampf(goal.x, cam_x - 5.6, cam_x + 5.6)
		goal.y = clampf(goal.y, bee.flight_min.y, bee.flight_max.y)
		var p := bee.global_position
		p.x = move_toward(p.x, goal.x, bee.horizontal_speed * tick)
		p.y = move_toward(p.y, goal.y, bee.vertical_speed * tick)
		# Keep off the body (except when it charges through).
		if boss._step != &"charge_run" and absf(p.x - boss.global_position.x) < 2.6 and p.y < 2.8:
			p.x = boss.global_position.x - side * 2.6
		bee.global_position = p
		# --- fire ---
		bee.spread_ammo = 9999 if use_spread else 0
		fire_left -= tick
		if fire_left <= 0.0 and boss.is_active():
			fire_left = 1.0 / BOT_TAPS_PER_SECOND
			var aimed: bool = AIM_PATTERN[taps % AIM_PATTERN.size()]
			taps += 1
			var target_point := boss.body_hurtbox.global_position
			if boss.state != TarantulaBoss01.State.PHASE_1 or boss.implant_exposed:
				target_point = boss.implant_hurtbox.global_position
			var closest := INF
			for minion in wave.boss_minions(): # A player clears the flies first (only the ones on screen).
				if not is_instance_valid(minion) or CinematicDepthEntry.is_in_depth(minion) or not minion.is_in_group("bee_auto_aim_targets"):
					continue
				if not BeeShmupFairness.is_on_screen(minion, -0.4):
					continue
				var d := minion.global_position.distance_to(bee.global_position)
				if d < closest:
					closest = d
					target_point = bee._target_point(minion)
			if not aimed:
				target_point += Vector3(0.0, 5.0, 0.0)
			bee.set_aim_point(target_point)
			bee.fire()
	var result := {"seconds": INF, "damage": damage[0]}
	if not snapshot.is_empty():
		var s := snapshot
		check(float(s["min_tele"]) >= TarantulaBoss01.MIN_TELEGRAPH - 0.001, label + ": an attack warned only %.2f s" % s["min_tele"])
		check(float(s["charge_tele"]) >= 0.8 - 0.001, label + ": the charge must warn 0.8 s")
		check(int(s["untelegraphed"]) <= TarantulaBoss01.CONTACT_DAMAGE, label + ": %d untelegraphed damage" % s["untelegraphed"])
		check(s["phases"] == [TarantulaBoss01.State.PHASE_1, TarantulaBoss01.State.PHASE_2, TarantulaBoss01.State.PHASE_3, TarantulaBoss01.State.PHASE_4], label + ": phases %s" % str(s["phases"]))
		check(int(s["stomps"]) >= 1 and int(s["threads"]) >= 1 and int(s["charges"]) >= 2 and int(s["curtains"]) >= 1 and int(s["spiders"]) >= 1 and int(s["fans"]) >= 1, label + ": every attack must occur %s" % str(s))
		check(int(s["exposures"]) >= 1 and int(s["honey"]) >= 1 and int(s["summons"]) >= 1, label + ": implant window, honey and flies %s" % str(s))
		result = {"seconds": float(s["seconds"]), "damage": int(s["damage"])}
		lines.append("TARANTULA %s fight=%.1fs damage=%d untelegraphed=%d hp=%d phases=%s fans=%d stomps=%d threads=%d charges=%d curtains=%d spiders=%d summons=%d exposures=%d exposed_damage=%d legs_absorbed=%d honey=%d min_telegraph=%.2fs taps=%d" % [
				label, s["seconds"], s["damage"], s["untelegraphed"], s["hp"], str(s["phases"]), s["fans"], s["stomps"], s["threads"], s["charges"], s["curtains"],
				s["spiders"], s["summons"], s["exposures"], s["exposed_damage"], s["legs"], s["honey"], s["min_tele"], taps])
	else:
		lines.append("TARANTULA %s did not finish (clock %.0f s, damage %d, hp %d)" % [label, clock, damage[0], boss.health.current_health if is_instance_valid(boss) else -1])
	lines.append("TARANTULA %s timeline: %s" % [label, " | ".join(phase_log)])
	lines.append("TARANTULA %s damage by attack: %s · hits: %s" % [label, str(by_kind), str(hits)])
	for i in 900:
		await physics_frame
		if stage.sector_complete:
			break
	check(stage.sector_complete and stage.status.text.begins_with("SECTOR DESPEJADO · LIBERADOS"), label + ": no SECTOR DESPEJADO · LIBERADOS after the tarantula")
	return result


func _snapshot(boss: TarantulaBoss01, damage: int) -> Dictionary:
	var min_tele := INF
	var charge_tele := INF
	for hazard in boss.hazards:
		min_tele = minf(min_tele, float(hazard["telegraph"]))
		if hazard["kind"] == &"charge":
			charge_tele = minf(charge_tele, float(hazard["telegraph"]))
	return {"seconds": boss.fight_seconds, "damage": damage, "untelegraphed": boss.untelegraphed_damage, "hp": boss.max_hp,
			"phases": boss.phases_seen.duplicate(), "fans": boss.fired_fan, "stomps": boss.stomps, "threads": boss.threads, "charges": boss.charges,
			"curtains": boss.curtains, "spiders": boss.spiders_dropped, "summons": boss.summons, "exposures": boss.exposures,
			"exposed_damage": boss.exposed_damage, "legs": boss.legs_absorbed, "honey": boss.honey_spawned, "min_tele": min_tele, "charge_tele": charge_tele}
