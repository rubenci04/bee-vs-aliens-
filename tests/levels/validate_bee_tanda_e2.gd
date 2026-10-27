extends SceneTree
## Tanda E2: (1) fly groups 6 / 9 with 14 HP members, first volley 0.85 s, then 2.2 s, dive pair every 3 s; (2) the stag beetle's aerial cannonball bursts
## in the air (1.5 m, damage 8) and sheds 4 short fragments; (3) the robot hops 3.5 m / jumps 4.4 m, bursts at 10 m/s and answers a high Bee;
## (4) the 4 s introductory flight with the COMO JUGAR card (keyboard / gamepad wording); (5) music default 25 %, effects 100 %.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func load_stage(intro := false) -> BeeShmupStage:
	BeeGameSettings.level_intro_pending = intro
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	return stage
func run() -> void:
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	BeeJuice.hit_stop_enabled = false
	var FS := preload("res://scripts/game/bee_fly_cloud_settings.gd")
	var ES := preload("res://scripts/game/bee_encounter_settings.gd")
	var CARD := preload("res://scripts/ui/bee_howto_card.gd")
	# --- 5. music ---
	check(is_equal_approx(BeeGameSettings.MUSIC_DEFAULT_VOLUME, 0.25) and is_equal_approx(BeeGameSettings.SFX_DEFAULT_VOLUME, 1.0), "Default music 25 %, effects 100 %")
	# --- 4. intro ---
	var stage := await load_stage(true)
	var wave := stage.wave as BeeLevel01Controller
	check(wave.intro_active() and stage.scroll_speed == 0.0 and wave._pending.is_empty(), "Intro active: no scroll, no spawns")
	check(stage.get_node_or_null("HowToCard") != null, "The how-to-play card is on screen")
	var keys := "\n".join(CARD.lines(false))
	var pad := "\n".join(CARD.lines(true))
	for word in ["WASD", "X / Clic", "Shift", "Z", "Q", "Polen", "Bomba"]:
		check(keys.contains(word), "Keyboard card mentions " + word)
	for word in ["Stick", "RT", "LB", "RB", "LT", "Bomba"]:
		check(pad.contains(word), "Gamepad card mentions " + word)
	await frames(60 * 4 + 20)
	check(not wave.intro_active() and is_equal_approx(stage.scroll_speed, BeeLevel01Controller.LEVEL_SCROLL) and not stage.has_node("HowToCard"), "After 4 s the card goes and the level starts")
	stage.queue_free()
	await frames(2)
	stage = await load_stage(true)
	wave = stage.wave as BeeLevel01Controller
	await frames(30)
	var press := InputEventKey.new()
	press.physical_keycode = KEY_SPACE
	press.pressed = true
	stage.get_node("HowToCard")._input(press)
	check(wave.intro_active(), "Cannot be dismissed before 1.5 s")
	await frames(70)
	stage.get_node("HowToCard")._input(press)
	await frames(3)
	check(not wave.intro_active() and not stage.has_node("HowToCard"), "Dismissed after 1.5 s")
	stage.queue_free()
	await frames(2)
	stage = await load_stage(false)
	check(not stage.wave.intro_active() and not stage.has_node("HowToCard"), "No intro when the level is not started from the beginning")
	# --- 1. fly groups ---
	wave = stage.wave as BeeLevel01Controller
	var bee := stage.bee
	stage.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	stage.distance = 138
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(134, 3, 0)
	check(BeeGameSettings.ENEMY_HEALTH.COMMON_HP["FlyCloud"] == 6 and ES.FINAL_GROUP_SIZE == 9 and FS.FLY_HP == 14 and ES.MAX_FLY_GROUPS == 2, "6 / 9 flies, 14 HP, two groups at most")
	check(is_equal_approx(FS.FIRST_VOLLEY_SECONDS, 0.85) and is_equal_approx(FS.VOLLEY_SECONDS, 2.2) and is_equal_approx(FS.DIVE_INTERVAL, 3.0) and is_equal_approx(FS.WARNING_SECONDS, 0.5), "Volley 0.85 s then 2.2 s; dive pair every 3 s; 0.5 s warning")
	wave._spawn({"family": "FlyCloud", "event": 606, "slot": 0, "hard": false})
	var cloud = wave.active_units.back()
	var active_at := -1
	for i in 60 * 6:
		await physics_frame
		if active_at < 0 and cloud.is_active():
			active_at = i
		if cloud.volleys >= 1:
			var gap := float(i - active_at) / 60.0
			check(gap >= 0.7 and gap <= 1.1, "First volley %.2f s after it is active" % gap)
			break
	check(cloud.volleys >= 1, "The group fires before dying")
	check(cloud.population == 6 and cloud.members.size() == 6 and cloud.members.all(func(m): return m.hp.max_health == 14), "Six members with 14 HP each")
	stage.distance = 240
	wave.active_units.clear()
	wave._spawn({"family": "FlyCloud", "event": 607, "slot": 0, "hard": false})
	var cloud2 = wave.active_units.back()
	check(cloud2.population == 9 and cloud2.members.size() == 9, "Nine flies from X >= 240")
	# --- 2. beetle cannonball ---
	stage.distance = 200
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 3.4, 0)
	bee.health.damage_blocked = false
	bee.health.current_health = bee.health.max_health
	var frag := [0]
	var spot := func(node: Node):
		if node is AlienEnemyProjectile and node.get_meta("shot_style", &"") == &"pellet": frag[0] += 1
	node_added.connect(spot)
	var ball := BeetleCannonball.new()
	ball.flight_time = 0.1
	stage.add_child(ball)
	ball.global_position = bee.global_position + Vector3(0.8, 0, 0)
	check(ball.is_in_group("alien_projectiles"), "The ball is a clearable projectile")
	await frames(14)
	node_added.disconnect(spot)
	check(not is_instance_valid(ball) and frag[0] == 4, "It bursts in the air and sheds 4 fragments")
	check(bee.health.current_health <= bee.health.max_health - BeetleCannonball.BURST_DAMAGE, "The burst (radius 1.5 m) hurts for 8")
	check(is_equal_approx(BeetleCannonball.BURST_RADIUS, 1.5) and is_equal_approx(BeetleCannonball.FRAGMENT_REACH, 1.8) and BeetleCannon.WARNING == 0.5, "Cannon constants")
	await frames(120)
	bee.health.current_health = bee.health.max_health
	var far := BeetleCannonball.new()
	far.flight_time = 0.05
	stage.add_child(far)
	far.global_position = bee.global_position + Vector3(2.6, 0, 0)
	await frames(8)
	check(bee.health.current_health == bee.health.max_health, "Outside 1.5 m nothing hurts")
	# --- 3. robot ---
	check(WalkerMiniboss.HOP_APEX == 3.5 and WalkerMiniboss.JUMP_APEX == 4.4 and WalkerMiniboss.BURST_SPEED == 10.0, "Hop 3.5 m, jump 4.4 m, burst 10 m/s")
	stage.queue_free()
	await frames(2)
	stage = await load_stage(false)
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	stage.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	stage.distance = 294
	stage._update_camera_and_bounds()
	var gate: Dictionary = {}
	for event: Dictionary in BeeLevel01Controller.EVENTS_ROSTER:
		if bool(event.get("miniboss", false)):
			gate = event
	wave._spawn({"family": "Walker", "slot": 0, "event": 0, "hard": true, "miniboss": true, "escort_wave": gate["escort_wave"]})
	var robot := wave.miniboss
	var max_y := -1.0
	for i in 60 * 40:
		bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 4.6, 0)
		await physics_frame
		max_y = maxf(max_y, robot.global_position.y)
		if robot.air_priority_picks >= 3 and max_y > 3.0:
			break
	check(robot.air_priority_picks >= 1, "A Bee that stays high makes the robot answer (%d priority picks)" % robot.air_priority_picks)
	check(max_y > 3.0, "The robot actually leaps into the upper band (max y %.2f)" % max_y)
	print("TANDA_E2 failures=", failures)
	quit(1 if failures else 0)
