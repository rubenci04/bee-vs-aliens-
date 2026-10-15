extends SceneTree

# LOTE 11 · ETAPA C — life and emotion (structure, never "fun"): hit flash 0.06 s, hit stop 40-60 ms, camera shake with an off
# switch, pollen burst, item magnet, roll (Shift: 0.35 s invulnerable, 2.5 s recharge, common shots destroyed), combo x N
# (reset after 3 s) + score, honey mode (every 17 pollen: 6 s of double shot), foreground grass layers, speed lines and the
# watering-can water columns (1 s warning, moderate damage).

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const PROJECTILE := preload("res://scenes/bee_prototype/alien_enemy_projectile.tscn")
const POLLEN := preload("res://scenes/items/toon/pollen.tscn")
const HEALING := preload("res://scenes/items/toon/pollen_cluster.tscn")

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var juice: BeeLevel01Juice

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

func run() -> void:
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	juice = stage.get_node("Juice") as BeeLevel01Juice
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	stage.distance = 100.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 3.5, 0.0)
	await test_flash()
	await test_hit_stop_and_shake()
	test_pollen_burst()
	await test_roll()
	await test_combo_and_score()
	await test_honey()
	await test_magnet()
	test_foreground_and_lines()
	await test_watering()
	await test_title()
	print("BEE_LOTE11_JUICE_V01_OK")
	quit(0)

func clear_units() -> void:
	for unit in wave.active_units + wave.swarm_units:
		if is_instance_valid(unit):
			unit.queue_free()
	wave.active_units.clear()
	wave.swarm_units.clear()
	await frames(2)

# --- C1 ------------------------------------------------------------------------------------------------------------------

func test_flash() -> void:
	for family in ["Wasp", "Mosquito", "Swarm"]:
		await clear_units()
		wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false, "y": 3.5, "path": "sine", "shooter": false})
		var unit: Node3D = (wave.swarm_units if family == "Swarm" else wave.active_units).back()
		var flash := unit.get_node_or_null("HitFlash3D") as HitFlash3D
		check(flash != null, "%s has no HitFlash3D" % family)
		check(is_equal_approx(flash.duration, BeeJuice.HIT_FLASH_SECONDS) and is_equal_approx(BeeJuice.HIT_FLASH_SECONDS, 0.06), "Flash must last 0.06 s")
		check(flash.flash_color == BeeJuice.HIT_FLASH_COLOR and is_equal_approx(flash.flash_color.a,.55), "T4e flash mixes warm white at 55 percent")
		var health := unit.get_node("HealthComponent") as HealthComponent
		var hits := [0]
		wave.enemy_hit.connect(func(): hits[0] += 1, CONNECT_ONE_SHOT)
		health.take_damage(1)
		check(hits[0] == 1, "enemy_hit not emitted")
		check(flash.is_flashing() or flash.activation_count > 0, "%s did not flash on impact" % family)
		await frames(6) # 0.1 s
		check(not flash.is_flashing(), "The flash must end after ~0.06 s")
	await clear_units()
	print("LOTE11_JUICE flash=0.06s on Wasp/Mosquito/Swarm OK")

func test_hit_stop_and_shake() -> void:
	BeeJuice.hit_stop_enabled = true
	var before := BeeJuice.hit_stops
	Engine.time_scale = 1.0
	BeeJuice.hit_stop(self)
	check(BeeJuice.hit_stops == before + 1 and Engine.time_scale < 0.1, "Hit stop did not slow the game")
	check(BeeJuice.HIT_STOP_SECONDS >= 0.04 and BeeJuice.HIT_STOP_SECONDS <= 0.06, "Hit stop outside 40-60 ms")
	var waited := 0
	while Engine.time_scale < 0.9 and waited < 30:
		await process_frame
		waited += 1
	check(is_equal_approx(Engine.time_scale, 1.0), "The time scale must be restored after the hit stop")
	BeeJuice.hit_stop_enabled = false
	BeeJuice.hit_stop(self)
	check(is_equal_approx(Engine.time_scale, 1.0), "A disabled hit stop must not touch the time scale")
	BeeJuice.hit_stop_enabled = true
	# Shake: on by default, off with the setting, and Bee being hurt shakes the camera.
	var camera := stage.camera
	camera.remove_meta("shake_until") if camera.has_meta("shake_until") else null
	BeeGameSettings.screen_shake_enabled = false
	BeeCameraShake.kick(bee, 0.05, 0.2)
	check(not camera.has_meta("shake_until"), "Shake must do nothing when switched off")
	BeeGameSettings.screen_shake_enabled = true
	bee.health.take_damage(5)
	check(camera.has_meta("shake_until") and float(camera.get_meta("shake_amplitude")) <= BeeCameraShake.MAX_AMPLITUDE + 0.0001, "Damage taken must shake the camera (leve)")
	bee.health.restore_health(5)
	await frames(30)
	print("LOTE11_JUICE hit_stop=50ms restored OK shake on/off OK damage_shake OK")

func test_pollen_burst() -> void:
	var burst := BeeJuice.pollen_burst(stage, bee.global_position)
	check(burst != null and burst.one_shot and burst.amount == BeeJuice.POLLEN_BURST_AMOUNT, "Pollen burst missing")
	burst.queue_free()
	print("LOTE11_JUICE pollen_burst OK")

# --- C2 ------------------------------------------------------------------------------------------------------------------

func test_roll() -> void:
	check(InputMap.has_action("bee_roll"), "bee_roll action missing")
	var shift := false
	for event in InputMap.action_get_events("bee_roll"):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_SHIFT:
			shift = true
	check(shift, "bee_roll must be Shift")
	check(is_equal_approx(bee.roll_duration, 0.35) and is_equal_approx(bee.roll_cooldown, BeeGameSettings.PIRUETA_COOLDOWN_SEC), "Roll constants must be 0.35 s / 2.5 s")
	bee.set_physics_process(true)
	check(bee.roll_ready_ratio() >= 1.0, "Roll must start ready")
	check(bee.start_roll(), "Roll did not start")
	var roll_start_frame := Engine.get_physics_frames()
	check(bee.health.invulnerable and bee.is_rolling, "Roll must be invulnerable")
	check(bee.health.take_damage(20) == 0, "Damage during the roll must be ignored")
	check(not bee.start_roll(), "No roll while rolling")
	# A common enemy shot that touches Bee is destroyed without damage.
	var shot := PROJECTILE.instantiate() as AlienEnemyProjectile
	stage.add_child(shot)
	shot.global_position = bee.global_position
	shot.launch(Vector3.LEFT, wave)
	shot.speed = 0.0
	var hp := bee.health.current_health
	var absorbed := bee.roll_absorbed_shots
	for i in 6:
		await physics_frame
		if not is_instance_valid(shot) or shot.is_queued_for_deletion():
			break
	check(not is_instance_valid(shot) or shot.is_queued_for_deletion(), "A common shot touching Bee during the roll must be destroyed")
	check(bee.roll_absorbed_shots == absorbed + 1 and bee.health.current_health == hp, "The absorbed shot must cost no HP")
	# Roll length and recharge.
	var rolled := 0
	while bee.is_rolling and rolled < 120:
		await physics_frame
		rolled += 1
	var seconds := float(Engine.get_physics_frames() - roll_start_frame) / 60.0
	check(seconds > 0.25 and seconds < 0.5, "Roll lasted %.2f s" % seconds)
	check(not bee.health.invulnerable, "Roll must end")
	check(bee.health.take_damage(5) == 5, "Damage applies again after the roll")
	bee.health.restore_health(5)
	check(not bee.start_roll() and bee.roll_ready_ratio() < 1.0, "No new roll while recharging")
	await frames(30)
	check(not bee.start_roll(), "Still recharging before 1.2 s")
	await frames(35)
	check(bee.roll_ready_ratio() >= 1.0 and bee.start_roll(), "The roll must be ready ~2.5 s after the previous one")
	await frames(5)
	var hud := stage.get_node("CanvasLayer/WeaponsHUD") as Control
	check(hud != null and is_equal_approx(float(hud.call("pirueta_ready_ratio")), bee.roll_ready_ratio()), "HUD recharge ring is not synced to pirueta cooldown")
	var lines := stage.get_node("CanvasLayer/SpeedLines") as BeeLevel01SpeedLines
	check(lines != null and lines.intensity > 0.0, "Speed lines must show during the roll")
	await frames(60)
	bee.set_physics_process(false)
	await frames(200) # recharge
	bee.set_physics_process(true)
	await frames(1)
	bee.set_physics_process(false)
	print("LOTE11_JUICE roll=%.2fs recharge=2.5s absorbs_common_shot OK hud OK" % seconds)

# --- C3 ------------------------------------------------------------------------------------------------------------------

func test_combo_and_score() -> void:
	await clear_units()
	check(juice.combo == 0 and juice.score == 0, "Combo must start empty")
	wave._spawn({"family": "Swarm", "slot": 0, "event": 0, "hard": false, "y": 3.5, "path": "sine", "shooter": false})
	var popcorn: Node3D = wave.swarm_units.back()
	wave.unit_downed.emit(popcorn, false)
	wave.unit_downed.emit(popcorn, false)
	wave.unit_downed.emit(popcorn, false)
	check(juice.combo == 3 and juice.best_combo == 3, "Combo xN not counted")
	check(is_equal_approx(juice.combo_multiplier(), 1.2), "Combo multiplier")
	check(juice.score == roundi(10.0 * 1.0) + roundi(10.0 * 1.1) + roundi(10.0 * 1.2), "Score per kill x multiplier (%d)" % juice.score)
	check(juice.combo_label.visible and juice.combo_label.text == "x3", "Combo label")
	# Hits keep it alive; 3 s without impacts reset it.
	await frames(120)
	wave.enemy_hit.emit()
	await frames(120)
	check(juice.combo == 3, "A hit must keep the combo alive")
	await frames(int(BeeLevel01Juice.COMBO_RESET_SECONDS * 60.0) + 12)
	check(juice.combo == 0 and not juice.combo_label.visible and juice.best_combo == 3, "Combo must reset after 3 s without impacts")
	var score_before := juice.score
	juice.liberations_seen = BeeLevel01Juice.LIBERATION_POLLEN_EVERY - 1 # LOTE 14: a freed animal drops pollen one time in 3; this is the third
	wave.unit_downed.emit(popcorn, true) # a liberation: 150 points + pollen + burst
	check(juice.score == score_before + BeeLevel01Juice.POINTS_LIBERATION and juice.pollen_total == BeeLevel01Juice.POLLEN_PER_LIBERATION, "Liberation points / pollen")
	check(stage.find_child("PollenBurst", true, false) != null, "Liberation must burst pollen")
	check(juice.summary_text().begins_with("PUNTAJE %d" % juice.score), "Score summary for the SECTOR DESPEJADO card")
	await clear_units()
	print("LOTE11_JUICE combo x3 mult=1.2 reset=3s score=%d liberation OK" % juice.score)

# --- C3 honey ------------------------------------------------------------------------------------------------------------

func test_honey() -> void:
	# LOTE 13: pollen fills a bar (heal 15 % per 10 pollen); FRENESI (double shot) comes from a combo of 8.
	juice.pollen_total = 0
	juice.frenzy_activations = 0
	juice.pollen_heals = 0
	juice.combo = 0
	var dummy := Node3D.new()
	dummy.name = "FlyCommon_0_0"
	bee.honey_left = 0.0
	var projectiles := func() -> int: return stage.find_children("*", "Area3D", true, false).filter(func(n): return n.get_parent() is BeeEnergyProjectile).size()
	var base := projectiles.call() as int
	var shot := bee.fire()
	check(shot != null, "Bee must fire")
	var after_base := projectiles.call() as int
	check(after_base - base == 1, "Without frenzy a shot is one projectile")
	bee.health.take_damage(40)
	var hp_before := bee.health.current_health
	juice.add_pollen(BeeLevel01Juice.POLLEN_PER_HEAL - 1)
	check(bee.health.current_health == hp_before and juice.pollen_progress() == BeeLevel01Juice.POLLEN_PER_HEAL - 1 and bee.honey_left == 0.0, "Pollen must NOT heal at once: the bar waits for 10")
	juice.add_pollen(1)
	var expected := ceili(float(bee.health.max_health) * BeeLevel01Juice.POLLEN_HEAL_FRACTION)
	check(bee.health.current_health == hp_before + expected and juice.pollen_heals == 1 and bee.honey_left == 0.0, "A full bar heals 15 %% of max HP (got %d, want %d) and does not start frenzy" % [bee.health.current_health - hp_before, expected])
	check(stage.find_child("PollenHealFlash", true, false) != null and stage.find_children("*", "Label3D", true, false).any(func(l): return str(l.text).begins_with("+")), "The heal has a flash and a floating text")
	check(juice.pollen_label.text.begins_with("POLEN") and not juice.pollen_label.text.contains("MIEL"), "Visible text says POLEN, never MIEL")
	for i in BeeLevel01Juice.FRENZY_COMBO - 1:
		wave.unit_downed.emit(dummy, false)
	check(bee.honey_left == 0.0, "Frenzy waits for the combo of 8")
	wave.unit_downed.emit(dummy, false)
	check(is_equal_approx(bee.honey_left, 6.0) and juice.frenzy_activations == 1, "Combo x8 starts 6 s of FRENESI")
	check(juice.frenzy_label.text.begins_with("FRENESÍ"), "Frenzy label")
	var before := projectiles.call() as int
	bee.fire()
	check((projectiles.call() as int) - before == 2, "Frenzy = double shot")
	bee.set_physics_process(true)
	bee.honey_left = 0.1
	await frames(10)
	check(bee.honey_left == 0.0, "Frenzy must end")
	bee.set_physics_process(false)
	before = projectiles.call() as int
	bee.fire()
	check((projectiles.call() as int) - before == 1, "Back to a single shot after frenzy")
	print("LOTE13_JUICE pollen 10 -> +15 pct HP, combo x8 -> 6 s FRENESI OK")

# --- C1 magnet -----------------------------------------------------------------------------------------------------------

func test_magnet() -> void:
	bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 3.5, 0.0)
	var near := POLLEN.instantiate() as BeePollenPickup
	stage.add_child(near)
	near.global_position = bee.global_position + Vector3(0.95, 0.0, 0.0) # T3i: 0.48 × 2.5 attraction radius.
	var far := POLLEN.instantiate() as BeePollenPickup
	stage.add_child(far)
	far.global_position = bee.global_position + Vector3(5.0, 0.0, 0.0)
	var jar := HEALING.instantiate() as Node3D
	stage.add_child(jar)
	jar.global_position = bee.global_position + Vector3(0.0, 1.6, 0.0)
	await frames(3)
	var far_start := far.global_position
	var jar_start := jar.global_position
	var pollen_before := juice.pollen_total
	var collected := false
	for i in 90:
		await physics_frame
		if not is_instance_valid(near) or near.was_collected:
			collected = true
			break
	check(collected, "A pollen passing close to Bee must drift in and be collected")
	check(juice.pollen_total >= pollen_before + 1, "The magnet-collected pollen must count for the pollen bar")
	check(far.global_position.is_equal_approx(far_start), "Far items must not move")
	await frames(60)
	check(not is_instance_valid(jar) or jar.was_collected or jar.global_position.distance_to(jar_start) > 0.2, "A pollen cluster within reach must come to Bee (any HP)")
	for node in [far, jar]:
		if is_instance_valid(node):
			node.queue_free()
	print("LOTE11_JUICE magnet radius=%.1f OK (far items stay, clusters come at any HP)" % BeeLevel01Juice.MAGNET_RADIUS)

# --- C4 ------------------------------------------------------------------------------------------------------------------

func test_foreground_and_lines() -> void:
	var foreground := stage.get_node("Foreground") as BeeLevel01Foreground
	check(foreground != null and foreground.layers.size() >= 2 and foreground.layers.size() <= 3, "2-3 foreground layers expected")
	var camera_z := stage.camera.global_position.z
	for i in foreground.layers.size():
		var spec: Dictionary = BeeLevel01Foreground.LAYERS[i]
		check(float(spec["z"]) > 0.0 and float(spec["z"]) < camera_z, "Layer %d must sit between the flight plane and the camera" % i)
		check(float(spec["alpha"]) <= 0.45, "Foreground layers must stay faint")
		check(foreground.layers[i].multimesh.instance_count > 20, "Layer %d too sparse" % i)
	check(stage.get_node("CanvasLayer/SpeedLines").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Speed lines must ignore the mouse")
	print("LOTE11_JUICE foreground layers=%d speed_lines OK" % foreground.layers.size())

# --- C5 ------------------------------------------------------------------------------------------------------------------

func test_watering() -> void:
	var moments := BeeLevel01Controller.EVENTS.filter(func(e): return e.get("moment", "") == "watering_can")
	check(moments.size() == 1 and float(moments[0]["at"]) >= 120.0 and float(moments[0]["at"]) <= 135.0 and int(moments[0]["act"]) == 2 and (moments[0]["units"] as Array).is_empty(), "Watering-can moment must be one enemy-free event in act 2 near the can")
	var event := stage.get_node("WateringEvent") as BeeLevel01WateringEvent
	check(event.WARNING_SECONDS >= 1.0 and event.DAMAGE >= 4 and event.DAMAGE <= 12, "1 s warning and moderate damage")
	bee.global_position = Vector3(stage.camera.global_position.x + 5.5, 3.5, 0.0) # far from the first lanes
	bee.health.damage_blocked = false
	var hp := bee.health.current_health
	wave.director_moment.emit(&"watering_can")
	check(event.played and event.running, "The moment must start the event")
	await frames(40)
	check(event.columns.size() == 2 and event.columns_spawned == 2, "Two columns per wave")
	for column in event.columns:
		check(column["state"] == &"warning" and not (column["hitbox"] as DamageHitbox3D).enabled and (column["mark"] as Node3D).visible, "A warning mark (no damage) first")
		check(not (column["beam"] as Node3D).visible, "No water before the warning ends")
	# Standing in a lane during the warning costs nothing; once the water falls it does the moderate damage, once.
	var first_x := float(event.columns[0]["x"])
	bee.global_position = Vector3(first_x, 3.5, 0.0)
	await frames(30) # ~0.77 s since the warning started
	check(bee.health.current_health == hp, "No damage during the warning")
	await frames(18) # past 1 s: the column falls
	check(event.min_warning_measured >= 1.0 and event.min_warning_measured < 1.1, "Warning measured %.2f s" % event.min_warning_measured)
	await frames(8)
	check(bee.health.current_health == hp - BeeLevel01WateringEvent.DAMAGE and event.columns_hit == 1, "A column must do exactly %d damage once (%d)" % [BeeLevel01WateringEvent.DAMAGE, hp - bee.health.current_health])
	bee.global_position = Vector3(stage.camera.global_position.x + 5.5, 3.5, 0.0)
	await frames(400)
	check(event.columns_spawned == 6 and event.columns.is_empty() and not event.running, "Three waves of two columns, then the event ends (%d / %d)" % [event.columns_spawned, event.columns.size()])
	var second := event.played
	wave.director_moment.emit(&"watering_can")
	check(second and event.columns_spawned == 6, "The event plays once")
	bee.health.restore_health(100)
	print("LOTE11_JUICE watering warning=%.2fs damage=%d columns=%d hit_by_columns=%d OK" % [event.min_warning_measured, BeeLevel01WateringEvent.DAMAGE, event.columns_spawned, event.columns_hit])

# --- settings / title ----------------------------------------------------------------------------------------------------

func test_title() -> void:
	var title: Node = (load("res://scenes/game/bee_title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await frames(3)
	var button := title.find_child("ShakeButton", true, false) as Button
	check(button != null and button.text == "Temblor de pantalla: SÍ", "The title menu needs the shake option")
	button.pressed.emit()
	check(not BeeGameSettings.screen_shake_enabled and button.text == "Temblor de pantalla: NO", "The option must switch the shake off")
	button.pressed.emit()
	check(BeeGameSettings.screen_shake_enabled, "...and on again")
	title.queue_free()
	await frames(2)
	print("LOTE11_JUICE title shake option OK")
