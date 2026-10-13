extends Node
## InputMap applies to ALL devices. Autoload also runs in title/pause screens.
var notice: Label
var notice_left := 0.0
var startup_time_msec := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	startup_time_msec = Time.get_ticks_msec()
	configure_actions()
	Input.joy_connection_changed.connect(_connection_changed)
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	notice = Label.new()
	notice.position = BeeGameSettings.JOYPAD_NOTICE_POSITION
	notice.add_theme_font_size_override("font_size", 20)
	layer.add_child(notice)
	for device in Input.get_connected_joypads():
		# A controller already connected at launch is expected; do not place a toast over the title artwork.
		BeeGameSettings.last_joypad_device = device

func configure_actions() -> void:
	for action in InputMap.get_actions():
		for event in InputMap.action_get_events(action):
			event.device = -1
	for action in [&"move_left", &"move_right", &"move_forward", &"move_back", &"aim_left", &"aim_right", &"aim_up", &"aim_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_set_deadzone(action, BeeGameSettings.JOYPAD_DEADZONE)
	for spec in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0], ["move_forward", JOY_AXIS_LEFT_Y, -1.0], ["move_back", JOY_AXIS_LEFT_Y, 1.0], ["aim_left", JOY_AXIS_RIGHT_X, -1.0], ["aim_right", JOY_AXIS_RIGHT_X, 1.0], ["aim_up", JOY_AXIS_RIGHT_Y, -1.0], ["aim_down", JOY_AXIS_RIGHT_Y, 1.0], ["throw_orange", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0], ["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var event := InputEventJoypadMotion.new()
		event.device = -1
		event.axis = spec[1]
		event.axis_value = spec[2]
		InputMap.action_add_event(spec[0], event)
	InputMap.action_set_deadzone("throw_orange", BeeGameSettings.JOYPAD_TRIGGER_THRESHOLD)
	for spec in [["throw_orange", JOY_BUTTON_A], ["bee_bomb", JOY_BUTTON_X], ["bee_roll", JOY_BUTTON_B], ["bee_roll", JOY_BUTTON_LEFT_SHOULDER], ["debug_attack", JOY_BUTTON_Y], ["debug_attack", JOY_BUTTON_RIGHT_SHOULDER], ["bee_pause", JOY_BUTTON_START], ["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT], ["restart", JOY_BUTTON_Y]]:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = spec[1]
		InputMap.action_add_event(spec[0], event)
	var mouse := InputEventMouseButton.new()
	mouse.device = -1
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("throw_orange", mouse)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > BeeGameSettings.JOYPAD_DEADZONE):
		BeeGameSettings.last_input_joypad = true
		BeeGameSettings.last_joypad_device = event.device
	elif event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length_squared() > 0.0):
		BeeGameSettings.last_input_joypad = false

func _connection_changed(device: int, connected: bool) -> void:
	if connected:
		BeeGameSettings.last_joypad_device = device
		if Time.get_ticks_msec() - startup_time_msec < BeeGameSettings.JOYPAD_STARTUP_NOTICE_SUPPRESS_MSEC:
			return
		notice.text = "Mando detectado: " + Input.get_joy_name(device)
		notice_left = BeeGameSettings.JOYPAD_NOTICE_SEC
		notice.show()
	elif device == BeeGameSettings.last_joypad_device:
		BeeGameSettings.last_input_joypad = false
		BeeGameSettings.last_joypad_device = -1

func _process(delta: float) -> void:
	notice_left = maxf(0.0, notice_left - delta)
	notice.visible = notice_left > 0.0
