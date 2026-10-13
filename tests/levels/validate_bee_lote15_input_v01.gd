extends SceneTree

var failures := 0
func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	await process_frame
	print("F9 key code: ", KEY_F9)
	for action in [&"move_left", &"move_right", &"move_forward", &"move_back", &"aim_left", &"aim_right", &"aim_up", &"aim_down"]:
		check(InputMap.has_action(action), "Missing action: " + str(action))
		check(is_equal_approx(InputMap.action_get_deadzone(action), 0.2), "Stick deadzone: " + str(action))
	for action in [&"throw_orange", &"bee_bomb", &"bee_roll", &"debug_attack", &"bee_pause"]:
		var joy := false
		for event in InputMap.action_get_events(action):
			check(event.device == -1, "Must listen to every device")
			joy = joy or event is InputEventJoypadButton or event is InputEventJoypadMotion
		check(joy, "Missing joypad event: " + str(action))
	Input.action_press("aim_right", 0.1)
	check(Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", 0.2) == Vector2.ZERO, "Deadzone rejects idle drift")
	Input.action_release("aim_right")
	var trigger := InputEventJoypadMotion.new()
	trigger.device = 3
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 0.29
	check(not trigger.is_action_pressed("throw_orange"), "RT below 0.3 must not fire")
	trigger.axis_value = 0.31
	check(trigger.is_action_pressed("throw_orange"), "RT above 0.3 must fire on every device")
	var bee := preload("res://scenes/bee_prototype/bee_player.tscn").instantiate() as BeePlayer
	root.add_child(bee)
	bee.set_physics_process(false)
	await process_frame
	Input.action_press("aim_up")
	for i in 30:
		bee._update_joypad_aim(1.0 / 60.0)
	check(bee.aim_direction().y > 0.95, "Right stick up aims up in world XY")
	Input.action_release("aim_up")
	Input.action_press("aim_left")
	for i in 40:
		bee._update_joypad_aim(1.0 / 60.0)
	check(bee.aim_direction().x < -0.95, "Right stick turns smoothly through the opposite direction")
	Input.action_release("aim_left")
	BeeGameSettings.last_input_joypad = true
	bee._update_joypad_aim(1.0 / 60.0)
	check(not bee.is_free_aiming(), "Quiet right stick restores autoaim")
	bee.facing_x = -1.0
	check(bee.aim_direction().x < -0.95, "No target aims forward")
	quit(1 if failures else 0)
