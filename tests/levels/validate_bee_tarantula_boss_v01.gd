extends SceneTree

# LOTE 12 · ETAPA 3 — the TARANTULA, final boss of Level 1 (TarantulaBoss01). Structure + reproducible bot fights.
# LOTE 15 · ETAPA 5.3 — the dynamic tarantula (ground stalk, corner-to-corner jumps, ceiling crawl, pendulum swing, trapping net,
# fury combos). Two bots:
#   EXPERT  (same rules as validate_bee_boss_fight_v04): three taps/s, 60 % aimed, reacts to every warning but every other time
#           LATE (half of the warning gone), sees half of the shots coming, aims at the implant once the legs are armoured, clears
#           the flies first, struggles against the net (6 key presses/s) while it keeps shooting.
#   STILL   parked in a corner (top-left and bottom-left), never moves, shoots like the expert: a camper must still lose >= 40.
# HP capacity is raised only to finish the measurement; the received damage is counted (honey not subtracted).
# Targets: 80-110 s with Base and with sustained Spread (Normal and Easy), expert Normal damage 55-80, Easy hurts less, still bot
# (Normal) >= 40 in both corners, every attack warned >= 0.42 s, the charge 0.8 s, the net 0.5 s; the roll never destroys the stomp
# wave or the charge (it still destroys web shots and the flying net).
# Dev: -- report (prints, never fails) · -- first (Normal Base only) · -- trace · -- expert (skip the still bot)

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const BOT_TAPS_PER_SECOND := 3.0
const AIM_PATTERN := [true, true, false, true, false]
const LATE_FRACTION := 0.5
const BULLET_LOOKAHEAD := 0.9
const DRIFT := 1.0
const DRIFT_PERIOD := 3.4
const STRUGGLE_RATE := 6.0
const FIGHT_SECONDS := Vector2(80.0, 110.0) # LOTE 15: 70-100 -> 80-110 (the user's target for the dynamic boss).
const NORMAL_DAMAGE := Vector2(55.0, 80.0) # Lote 17's lower camera centre slightly changes the expert dodge window.
const STILL_MIN_DAMAGE := 40

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
	create_timer(2400.0, true, false, true).timeout.connect(func(): quit(1))
	Engine.max_physics_steps_per_frame = 16
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var args := OS.get_cmdline_user_args()
	await test_structure()
	await test_roll_rules()
	await test_web_trap()
	await test_moves()
	var normal: Array[Dictionary] = []
	for difficulty in [BeeGameSettings.NORMAL, BeeGameSettings.EASY]:
		BeeGameSettings.difficulty = difficulty
		for spread in [false, true]:
			if "first" in args and (difficulty != BeeGameSettings.NORMAL or spread):
				continue
			use_spread = spread
			var label := ("NORMAL" if difficulty == BeeGameSettings.NORMAL else "EASY") + (" SPREAD" if spread else " BASE")
			var result := await fight(label, &"expert")
			print("MEASURE EXPERT ", label, " ", result)
			check(float(result.seconds) >= FIGHT_SECONDS.x and float(result.seconds) <= FIGHT_SECONDS.y, label + ": duration outside 80-110 s: " + str(result.seconds))
			if difficulty == BeeGameSettings.NORMAL:
				normal.append(result)
				check(int(result.damage) >= NORMAL_DAMAGE.x and int(result.damage) <= NORMAL_DAMAGE.y, label + ": expert damage outside 55-80: " + str(result.damage))
			elif normal.size() > int(spread):
				check(int(result.damage) < int(normal[int(spread)].damage), label + ": Easy must hurt less")
			if "expert" in args:
				continue
			for corner in [&"still_top", &"still_bottom"]:
				var still := await fight(label, corner)
				print("MEASURE ", str(corner).to_upper(), " ", label, " ", still)
				if difficulty == BeeGameSettings.NORMAL:
					check(int(still.damage) >= STILL_MIN_DAMAGE, label + " " + str(corner) + ": a bot parked in a corner must lose >= 40 (lost %d)" % still.damage)
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
	check(boss.hit_flash.flash_color == BeeGameSettings.TARANTULA_HIT_FLASH_COLOR and boss.hit_flash.flash_color.a < 0.5,
		"Tarantula hits use a brief warm accent instead of a pale wash")
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
	var gold_outline_found := false
	for mesh: MeshInstance3D in boss.visual_root.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var body := mesh.get_active_material(surface) as ShaderMaterial
			if body == null or body.next_pass == null:
				continue
			var outline := body.next_pass as ShaderMaterial
			if outline.get_shader_parameter("outline_color") == BeeGameSettings.TARANTULA_EXPOSED_OUTLINE_COLOR:
				gold_outline_found = true
	check(gold_outline_found, "The exposed implant window gives the tarantula a gold outline")
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


## The roll (Lote 11) still destroys the web shots and the flying net but never the stomp wave or the charge.
func test_roll_rules() -> void:
	var boss := await start_arena()
	boss.set_physics_process(false)
	bee.set_physics_process(false)
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 1.0, 0.0)
	bee.health.damage_blocked = false
	bee._roll_cooldown_left = 0.0
	var web := boss._spawn_web(bee.global_position + Vector3(1.0, 0.0, 0.0), Vector3.LEFT, 6.0)
	bee.start_roll()
	await frames(14)
	check(not is_instance_valid(web) or web.is_queued_for_deletion(), "The roll destroys a web shot")
	bee._roll_cooldown_left = 0.0
	var wave_node := BeeGroundShockwave.launch(stage, boss, bee.global_position.x + 1.2, bee.global_position.x - 8.0, 8, 7.0, 1.3)
	bee.start_roll()
	await frames(12)
	check(is_instance_valid(wave_node) and not wave_node.is_queued_for_deletion() and wave_node.hitbox.enabled, "The roll must not destroy the stomp wave")
	wave_node.stop()
	check(not (boss._charge_box.get_parent() is AlienEnemyProjectile), "The charge is not a projectile")
	await frames(30)
	bee._roll_cooldown_left = 0.0
	var net := TarantulaWebNet.launch(stage, boss, bee, bee.global_position + Vector3(1.2, 0.0, 0.0), Vector3.LEFT)
	bee.start_roll()
	await frames(14)
	check(not is_instance_valid(net) and not bee.web_locked, "The roll tears a flying net")
	bee.health.damage_blocked = true


## The net: Bee stuck (shoots, cannot move), freed by shots or by mashing the keys or after 2 s, then 1.5 s of grace.
func test_web_trap() -> void:
	var boss := await start_arena()
	boss.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 3.0, 0.0)
	var net := TarantulaWebNet.launch(stage, boss, bee, bee.global_position + Vector3(1.5, 0.0, 0.0), Vector3.LEFT)
	await frames(20)
	check(bee.web_locked and net.trapping and boss.traps == 1, "The net traps Bee")
	var at := bee.global_position
	Input.action_press("move_forward")
	await frames(20)
	Input.action_release("move_forward")
	check(bee.global_position.distance_to(at) < 0.05, "Trapped Bee cannot move (moved %.2f)" % bee.global_position.distance_to(at))
	check(not bee.start_roll() and not bee.start_melee(), "No roll and no sting while trapped")
	check(bee.fire() != null, "Trapped Bee can shoot")
	for i in TarantulaWebNet.tears_needed() - 1:
		bee.fire()
	await frames(2)
	check(not bee.web_locked and not is_instance_valid(net), "%d shots tear the net" % TarantulaWebNet.tears_needed())
	check(boss.web_immune(), "Grace after the trap")
	var second := TarantulaWebNet.launch(stage, boss, bee, bee.global_position + Vector3(1.5, 0.0, 0.0), Vector3.LEFT)
	await frames(20)
	check(not bee.web_locked and not is_instance_valid(second) and boss.traps == 1, "Nothing chains the trap: no second trap in the grace window")
	for i in int(60 * TarantulaWebNet.GRACE_SECONDS) + 5:
		boss._web_immune_left = maxf(0.0, boss._web_immune_left - 1.0 / 60.0)
		await physics_frame
	# Struggling (movement keys) also frees her.
	var third := TarantulaWebNet.launch(stage, boss, bee, bee.global_position + Vector3(1.5, 0.0, 0.0), Vector3.LEFT)
	await frames(20)
	check(bee.web_locked, "Trapped again after the grace")
	for i in TarantulaWebNet.struggles_needed():
		Input.action_press("move_left" if i % 2 == 0 else "move_right")
		await frames(2)
		Input.action_release("move_left" if i % 2 == 0 else "move_right")
		await frames(2)
	await frames(2)
	check(not bee.web_locked and not is_instance_valid(third), "Mashing the movement keys frees her (%d presses)" % TarantulaWebNet.struggles_needed())
	# Doing nothing: free after TRAP_SECONDS.
	boss._web_immune_left = 0.0
	var fourth := TarantulaWebNet.launch(stage, boss, bee, bee.global_position + Vector3(1.5, 0.0, 0.0), Vector3.LEFT)
	await frames(20)
	var held := 0
	while bee.web_locked and held < 400:
		held += 1
		await physics_frame
	check(held > 60 * (TarantulaWebNet.TRAP_SECONDS - 0.4) and held < 60 * (TarantulaWebNet.TRAP_SECONDS + 0.2), "Free after at most 2 s (%d frames)" % held)
	lines.append("TARANTULA web_trap shots=%d struggles=%d max=%.1fs grace=%.1fs" % [TarantulaWebNet.tears_needed(), TarantulaWebNet.struggles_needed(), TarantulaWebNet.TRAP_SECONDS, TarantulaWebNet.GRACE_SECONDS])


## Moves: the jump lands on the ceiling (upside down, implant facing down), the swing hangs from a thread inside the screen.
func test_moves() -> void:
	var boss := await start_arena()
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	var cam_x := stage.camera.global_position.x
	var top := BeeLevel01Framing.top_y()
	var saw := {}
	for i in 60 * 40:
		await physics_frame
		bee.global_position = Vector3(cam_x - 3.0 + 2.0 * sin(float(i) / 90.0), 3.2, 0.0)
		saw[boss.mode] = true
		if boss.mode == &"ceiling":
			check(boss.implant_hurtbox.global_position.y < top and boss.implant_hurtbox.global_position.y > top - 3.0, "On the ceiling the implant hangs inside the screen (%.2f)" % boss.implant_hurtbox.global_position.y)
			check(boss.body_hurtbox.global_position.y > boss.implant_hurtbox.global_position.y, "Upside down: the implant faces down")
		if boss.mode == &"hang":
			check(boss.body_hurtbox.global_position.y < top and boss.body_hurtbox.global_position.y > 1.0, "The swinging body stays inside the screen")
		if boss.crawls >= 1 and boss.jumps >= 2 and boss.stalks >= 1:
			break
	check(saw.has(&"ground") and saw.has(&"ceiling") and saw.has(&"air"), "Ground, jump and ceiling in phase 1 %s" % str(saw.keys()))
	check(boss.jumps >= 2 and boss.crawls >= 1 and boss.stalks >= 1, "Phase 1 stalks, jumps up and crawls (jumps %d crawls %d stalks %d)" % [boss.jumps, boss.crawls, boss.stalks])
	lines.append("TARANTULA moves phase1 modes=%s jumps=%d crawls=%d stalks=%d nets=%d" % [str(saw.keys()), boss.jumps, boss.crawls, boss.stalks, boss.nets])


## Plays a whole fight with the expert or the still bot; returns {seconds, damage}.
func fight(label: String, bot: StringName) -> Dictionary:
	var boss := await start_arena()
	check(boss != null, label + ": no tarantula")
	var still := bot != &"expert"
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
			for minion in wave.boss_minions():
				if is_instance_valid(minion) and minion.global_position.distance_to(bee.global_position) < 1.6:
					kind = "fly"
			for node in get_nodes_in_group(TarantulaBoss01.PROJECTILE_GROUP):
				if is_instance_valid(node) and (node as Node3D).global_position.distance_to(bee.global_position) < 0.9:
					kind = "web"
			for spider in (boss.live_spiders() if is_instance_valid(boss) else []):
				if (spider as Node3D).global_position.distance_to(bee.global_position) < 1.0:
					kind = "spider"
			if bee.web_locked:
				kind += "(trapped)"
			by_kind[kind] = int(by_kind.get(kind, 0)) + -change
			if trace:
				print("HIT -%d t=%.1f step=%s mode=%s bee=(%.1f,%.1f) boss=%.1f" % [-change, boss.fight_seconds, boss._step, boss.mode, bee.global_position.x, bee.global_position.y, boss.global_position.x]))
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var clock := 0.0
	var fire_left := 0.0
	var struggle_left := 0.0
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
	var trapped_time := 0.0
	var corner := Vector3(bee.flight_min.x + 0.3, (bee.flight_max.y - 0.3) if bot == &"still_top" else (bee.flight_min.y + 0.3), 0.0)
	while is_instance_valid(boss) and boss.state != TarantulaBoss01.State.DONE and clock < 300.0:
		await physics_frame
		clock += tick
		if not is_instance_valid(boss):
			break
		if boss.state != last_state:
			phase_log.append("%s@%.1fs dmg=%d hp=%d" % [TarantulaBoss01.State.keys()[boss.state], boss.fight_seconds, damage[0], boss.health.current_health])
			last_state = boss.state
		if boss.state == TarantulaBoss01.State.FREED:
			if snapshot.is_empty():
				snapshot = _snapshot(boss, damage[0])
			continue
		var cam_x := stage.camera.global_position.x
		var side := boss.side
		if bee.web_locked:
			trapped_time += tick
		if trace and int(clock * 60.0) % 300 == 0:
			print("T t=%.0f hp=%d step=%s kind=%s mode=%s bee=(%.1f,%.1f) boss=(%.1f,%.1f) side=%d exposed=%s" % [boss.fight_seconds, boss.health.current_health, boss._step, boss.attack_kind, boss.mode,
					bee.global_position.x - cam_x, bee.global_position.y, boss.global_position.x - cam_x, boss.global_position.y, int(side), boss.implant_exposed])
		var p := bee.global_position
		if still:
			p = corner
		elif bee.web_locked:
			struggle_left -= tick
			if struggle_left <= 0.0:
				struggle_left = 1.0 / STRUGGLE_RATE
				bee.web_struggle()
		else:
			p = _expert_step(boss, clock, tick, side, cam_x, [last_attack, react_at, react_kind, dodge_until, dodge_goal, bullet_seen, bullet_until, bullet_goal])
			var memo: Array = _memo
			last_attack = memo[0]
			react_at = memo[1]
			react_kind = memo[2]
			dodge_until = memo[3]
			dodge_goal = memo[4]
			bullet_until = memo[6]
			bullet_goal = memo[7]
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
		result = {"seconds": float(s["seconds"]), "damage": int(s["damage"])}
		if not still:
			check(float(s["min_tele"]) >= TarantulaBoss01.MIN_TELEGRAPH - 0.001, label + ": an attack warned only %.2f s" % s["min_tele"])
			check(float(s["charge_tele"]) >= 0.8 - 0.001, label + ": the charge must warn 0.8 s")
			check(float(s["net_tele"]) >= 0.5 - 0.001, label + ": the net must warn 0.5 s")
			check(int(s["untelegraphed"]) <= TarantulaBoss01.CONTACT_DAMAGE, label + ": %d untelegraphed damage" % s["untelegraphed"])
			check(s["phases"] == [TarantulaBoss01.State.PHASE_1, TarantulaBoss01.State.PHASE_2, TarantulaBoss01.State.PHASE_3, TarantulaBoss01.State.PHASE_4], label + ": phases %s" % str(s["phases"]))
			check(int(s["fans"]) >= 4 and int(s["nets"]) >= 2 and int(s["jumps"]) >= 3 and int(s["hangs"]) >= 2 and int(s["crawls"]) >= 2 and int(s["stalks"]) >= 2
					and int(s["charges"]) >= 2 and int(s["spiders"]) >= 1 and int(s["stomps"]) >= 1 and int(s["combos"]) >= 1, label + ": every move and attack must occur %s" % str(s))
			check(s["modes"].has(&"ground") and s["modes"].has(&"ceiling") and s["modes"].has(&"hang") and s["modes"].has(&"air"), label + ": it must use the ground, the ceiling, the thread and jumps %s" % str(s["modes"]))
			check(int(s["exposures"]) >= 1 and int(s["honey"]) >= 1 and int(s["summons"]) >= 1, label + ": implant window, honey and flies %s" % str(s))
		lines.append("TARANTULA %s %s fight=%.1fs damage=%d untelegraphed=%d hp=%d fans=%d nets=%d traps=%d trapped=%.1fs jumps=%d hangs=%d crawls=%d stalks=%d charges=%d stomps=%d curtains=%d spiders=%d combos=%d summons=%d exposures=%d exposed_damage=%d legs_absorbed=%d min_telegraph=%.2fs taps=%d" % [
				bot, label, s["seconds"], s["damage"], s["untelegraphed"], s["hp"], s["fans"], s["nets"], s["traps"], trapped_time, s["jumps"], s["hangs"], s["crawls"], s["stalks"], s["charges"],
				s["stomps"], s["curtains"], s["spiders"], s["combos"], s["summons"], s["exposures"], s["exposed_damage"], s["legs"], s["min_tele"], taps])
	else:
		lines.append("TARANTULA %s %s did not finish (clock %.0f s, damage %d, hp %d)" % [bot, label, clock, damage[0], boss.health.current_health if is_instance_valid(boss) else -1])
	lines.append("TARANTULA %s %s timeline: %s" % [bot, label, " | ".join(phase_log)])
	lines.append("TARANTULA %s %s damage by attack: %s · hits: %s" % [bot, label, str(by_kind), str(hits)])
	for i in 900:
		await physics_frame
		if stage.sector_complete:
			break
	check(stage.sector_complete and stage.status.text.begins_with("SECTOR DESPEJADO · LIBERADOS"), label + ": no SECTOR DESPEJADO · LIBERADOS after the tarantula")
	return result


var _memo: Array = []

## One frame of the expert bot's movement (returns Bee's next position; its memory goes back through `_memo`).
func _expert_step(boss: TarantulaBoss01, clock: float, tick: float, side: float, cam_x: float, memo: Array) -> Vector3:
	var last_attack: int = memo[0]
	var react_at: float = memo[1]
	var react_kind: StringName = memo[2]
	var dodge_until: float = memo[3]
	var dodge_goal: Vector3 = memo[4]
	var bullet_seen: Dictionary = memo[5]
	var bullet_until: float = memo[6]
	var bullet_goal: Vector3 = memo[7]
	if boss.attacks_started != last_attack:
		last_attack = boss.attacks_started
		react_kind = boss.attack_kind
		var late := last_attack % 2 == 1
		if react_kind == &"net":
			react_at = clock + maxf(boss.attack_left - 0.1, 0.0) + (0.2 if late else 0.0) # Moves when the line locks (earlier is useless: it follows Bee).
		else:
			react_at = clock + (boss.attack_left * LATE_FRACTION if late else 0.0)
	var home_x := clampf(boss.global_position.x - side * 4.2, cam_x - 5.6, cam_x + 5.6)
	var goal := Vector3(home_x, clampf(2.9 + DRIFT * sin(clock * TAU / DRIFT_PERIOD), 1.4, 5.6), 0.0)
	if react_at >= 0.0 and clock >= react_at:
		react_at = -1.0
		var here := bee.global_position
		match react_kind:
			&"stomp":
				dodge_goal = Vector3(here.x, 3.0, 0.0)
				dodge_until = clock + boss.attack_left + 1.6
			&"charge", &"double_charge", &"charge_spiders":
				dodge_goal = Vector3(here.x, TarantulaBoss01.CHARGE_TOP + 1.2, 0.0)
				dodge_until = clock + boss.attack_left + 1.4
			&"jump", &"jump_fan":
				var a: Vector3 = boss.jump_band[0]
				var b: Vector3 = boss.jump_band[1]
				var ab := Vector2(b.x - a.x, b.y - a.y)
				var normal := Vector2(-ab.y, ab.x).normalized()
				var off := Vector2(here.x - a.x, here.y - a.y).dot(normal)
				var push := normal * (signf(off) if off != 0.0 else 1.0) * maxf(0.0, 2.4 - absf(off))
				dodge_goal = here + Vector3(push.x, push.y, 0.0)
				var land_d := Vector2(here.x - b.x, here.y - b.y).length()
				if land_d < 2.6:
					dodge_goal = Vector3(cam_x, 3.4, 0.0)
				dodge_until = clock + boss.attack_left + TarantulaBoss01.JUMP_SECONDS + 0.3
			&"hang", &"hang_fan":
				var away := signf(here.x - boss.hang_pivot_x)
				if away == 0.0:
					away = signf(cam_x - here.x)
				var x := boss.hang_pivot_x + away * 3.6
				if absf(x - cam_x) > 5.6:
					x = boss.hang_pivot_x - away * 3.6
				dodge_goal = Vector3(clampf(x, cam_x - 5.6, cam_x + 5.6), here.y, 0.0)
				dodge_until = clock + boss.attack_left + TarantulaBoss01.HANG_DROP + TarantulaBoss01.HANG_SWING + TarantulaBoss01.HANG_UP
			&"net":
				var line: Array = boss.net_line
				var dir := Vector2(line[1].x - line[0].x, line[1].y - line[0].y).normalized()
				var perp := Vector2(-dir.y, dir.x)
				if here.y + perp.y * 1.8 > 5.8 or here.y + perp.y * 1.8 < 1.2:
					perp = -perp
				dodge_goal = here + Vector3(perp.x, perp.y, 0.0) * 1.8
				dodge_until = clock + 0.9
			&"curtain":
				var best := 3.0
				var best_d := INF
				for gap in boss.curtain_gaps:
					if absf(gap - here.y) < best_d:
						best_d = absf(gap - here.y)
						best = gap
				dodge_goal = Vector3(here.x, best, 0.0)
				dodge_until = clock + boss.attack_left + 3.0
	if clock < dodge_until:
		goal = dodge_goal
	for spider in boss.live_spiders():
		if absf(spider.global_position.x - bee.global_position.x) < 1.1 and spider.is_active():
			goal.x = spider.global_position.x + (1.8 if bee.global_position.x >= spider.global_position.x else -1.8)
	for minion in wave.boss_minions():
		if is_instance_valid(minion) and minion.global_position.distance_to(bee.global_position) < 2.0 and clock >= dodge_until:
			goal.y = clampf(bee.global_position.y + (1.8 if minion.global_position.y < bee.global_position.y else -1.8), 1.4, 5.8)
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
	# Keep off the body (except when it rushes or jumps: the warnings handle those).
	if not (boss._step in [&"charge_run", &"jump_run"]):
		var body := boss.body_hurtbox.global_position
		var gap := Vector2(p.x - body.x, p.y - body.y)
		if gap.length() < 2.3:
			var push := gap.normalized() if gap.length() > 0.01 else Vector2(-side, 0.0)
			p = Vector3(body.x + push.x * 2.3, body.y + push.y * 2.3, 0.0)
			p.y = clampf(p.y, bee.flight_min.y, bee.flight_max.y)
	_memo = [last_attack, react_at, react_kind, dodge_until, dodge_goal, bullet_seen, bullet_until, bullet_goal]
	return p


func _snapshot(boss: TarantulaBoss01, damage: int) -> Dictionary:
	var min_tele := INF
	var charge_tele := INF
	var net_tele := INF
	for hazard in boss.hazards:
		min_tele = minf(min_tele, float(hazard["telegraph"]))
		if hazard["kind"] == &"charge":
			charge_tele = minf(charge_tele, float(hazard["telegraph"]))
		if hazard["kind"] == &"net":
			net_tele = minf(net_tele, float(hazard["telegraph"]))
	return {"seconds": boss.fight_seconds, "damage": damage, "untelegraphed": boss.untelegraphed_damage, "hp": boss.max_hp,
			"phases": boss.phases_seen.duplicate(), "fans": boss.fans, "nets": boss.nets, "traps": boss.traps, "jumps": boss.jumps, "hangs": boss.hangs,
			"crawls": boss.crawls, "stalks": boss.stalks, "stomps": boss.stomps, "charges": boss.charges, "combos": boss.combos,
			"curtains": boss.curtains, "spiders": boss.spiders_dropped, "summons": boss.summons, "exposures": boss.exposures, "modes": boss.modes_seen.duplicate(),
			"exposed_damage": boss.exposed_damage, "legs": boss.legs_absorbed, "honey": boss.honey_spawned, "min_tele": min_tele, "charge_tele": charge_tele, "net_tele": net_tele}
