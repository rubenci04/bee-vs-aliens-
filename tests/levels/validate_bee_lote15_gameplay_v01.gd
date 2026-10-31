extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	var bee := stage.bee
	var wave := stage.wave as BeeLevel01Controller
	var hud := stage.get_node("CanvasLayer/WeaponsHUD") as Control
	var controls := str(hud.call("control_text"))
	wave.set_physics_process(false)
	stage.scroll_speed = 0.0
	bee.health.damage_blocked = true
	bee.set_physics_process(false)
	BeeGameSettings.last_input_joypad = false
	hud.refresh()
	check(controls.contains("FUEGO X / CLIC") and controls.contains("BOMBA C"), "HUD shows keyboard/mouse buttons")
	BeeGameSettings.last_input_joypad = true
	hud.refresh()
	controls = str(hud.call("control_text"))
	check(controls.contains("FUEGO A / RT") and controls.contains("BOMBA X"), "HUD switches to the most recently used joypad")
	BeeGameSettings.last_input_joypad = false
	bee.spread_ammo = 0.0
	check(bee.collect_spread() and bee.spread_ammo == 20.0, "Spread starts at 20 seconds")
	for i in 80:
		bee.fire()
	check(bee.spread_ammo == 20.0, "Projectiles never spend Spread time")
	bee.collect_spread()
	check(bee.spread_ammo == 30.0, "Second pickup extends by 10 seconds")
	for i in 4:
		bee.collect_spread()
	check(bee.spread_ammo == 45.0, "Spread capped at 45 seconds")
	bee.spread_ammo = 0.02
	bee.set_physics_process(true)
	await frames(4)
	check(bee.spread_ammo == 0.0 and bee.fire().damage == int(bee.weapon_profile()["damage"][0]), "Spread expires to the plain shot (Base: 3 since the weapon tiers)")
	bee.clear_aim()
	bee.global_position = Vector3(stage.distance, 4, 0)
	Input.action_press("move_right")
	var start := bee.global_position
	check(bee.start_roll(), "Pirueta available without charge")
	await frames(12)
	Input.action_release("move_right")
	check(bee.global_position.x - start.x > 2.5, "Pirueta moves approximately 3 metres")
	check(not bee.start_roll(), "Pirueta respects short interval")
	await frames(65)
	check(bee.start_roll(), "Pirueta available again after 1.2 seconds")
	await frames(30)
	bee.set_physics_process(false)
	bee.facing_x = 1.0
	bee.visual_root.rotation.y = -PI * 0.5
	bee._turn_left = 0.0
	bee.set_aim_point(bee.global_position + Vector3.LEFT * 5.0)
	bee._update_free_aim(0.01)
	check(bee.facing_x == -1.0 and bee.aim_direction().x < -0.9, "Shot points left immediately during visual turn")
	check(bee.visual_root.rotation.y < 0.0, "Visual does not snap to final yaw")
	await frames(20)
	check(absf(bee.visual_root.rotation.y - PI * 0.5) < 0.02, "Yaw completes in 0.22 seconds")
	bee._turn_left = 0.0
	bee._face_towards(0.1)
	check(bee.facing_x == -1.0, "Hysteresis rejects tiny offset")
	bee.health.current_health = 20
	bee.bomb_charges = 0
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	juice.pollen_total = 3
	wave._tarantula_breather_left = -1.0
	var camera_start := stage.camera.global_position.x
	wave._advance_tarantula(0.0)
	check(bee.health.current_health == 70 and bee.bomb_charges == 3 and juice.pollen_progress() >= 10, "Post-robot guarantees health bombs and pollen")
	check(stage.scroll_speed > 0.0 and wave.tarantula == null, "Calm scroll starts before tarantula")
	for i in 350:
		wave._advance_tarantula(1.0 / 60.0)
		await physics_frame
	check(stage.camera.global_position.x - camera_start > 10.0 and is_instance_valid(wave.tarantula), "One screen scroll and 5.5-second calm before tarantula")
	check(WalkerMiniboss.LASER_WARNING >= 0.8, "Robot laser warning at least 0.8 seconds")
	print("LOTE15 GAMEPLAY failures=", failures)
	quit(1 if failures else 0)
