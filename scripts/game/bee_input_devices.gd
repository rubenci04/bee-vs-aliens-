extends Node
const HUD_NOTICES := preload("res://scripts/ui/bee_hud_notices.gd")
const HUD_TEXT := preload("res://scripts/game/bee_hud_text_settings.gd")
## InputMap applies to ALL devices. Autoload also runs in title/pause screens.
const DEVICE_NOTICE_INTERVAL := 15.0
const MOUSE_SWITCH_DISTANCE := 8.0
var device_notice_cooldown := 0.0
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
	notice.hide() # Compatibility handle; visible messages use the shared banner.
	notice.add_theme_font_size_override("font_size", 20)
	layer.add_child(notice)
	for device in Input.get_connected_joypads():
		# A controller already connected at launch is expected; do not place a toast over the title artwork.
		BeeGameSettings.last_joypad_device = device

func configure_actions() -> void:
	var nova := preload("res://scripts/game/bee_pollen_nova_settings.gd")
	if not InputMap.has_action(nova.ACTION):
		InputMap.add_action(nova.ACTION, nova.TRIGGER_THRESHOLD)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_Q
		InputMap.action_add_event(nova.ACTION, key)
		var trigger := InputEventJoypadMotion.new()
		trigger.device = -1
		trigger.axis = JOY_AXIS_TRIGGER_LEFT
		trigger.axis_value = 1.0
		InputMap.action_add_event(nova.ACTION, trigger)
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
	var was_joypad := BeeGameSettings.last_input_joypad
	var old_device := BeeGameSettings.last_joypad_device
	if (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > BeeGameSettings.JOYPAD_DEADZONE):
		BeeGameSettings.last_input_joypad = true
		BeeGameSettings.last_joypad_device = event.device
	elif (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventMouseMotion and event.relative.length() >= MOUSE_SWITCH_DISTANCE):
		BeeGameSettings.last_input_joypad = false

	if BeeGameSettings.last_input_joypad != was_joypad or (BeeGameSettings.last_input_joypad and old_device != BeeGameSettings.last_joypad_device):
		show_device_notice("Mando detectado: " + Input.get_joy_name(event.device) if BeeGameSettings.last_input_joypad else "Teclado y ratón")

func show_device_notice(text: String) -> void:
	if device_notice_cooldown > 0.0 or HUD_NOTICES.combat_active(get_tree().current_scene): return
	notice.text = text
	var host := get_tree().current_scene
	if host == null:
		host = self
	var banners := HUD_NOTICES.for_host(host)
	if banners.left > 0.0: return # Do not queue a stale device change.
	notice_left = HUD_TEXT.DEVICE_SECONDS
	device_notice_cooldown = DEVICE_NOTICE_INTERVAL
	banners.show_notice(text, HUD_TEXT.DEVICE_SECONDS, "device", true)

func _connection_changed(device: int, connected: bool) -> void:
	if connected:
		# Connecting alone is not a change of the device being used.
		if not BeeGameSettings.last_input_joypad:
			BeeGameSettings.last_joypad_device = device
	elif device == BeeGameSettings.last_joypad_device:
		var was_active := BeeGameSettings.last_input_joypad
		BeeGameSettings.last_input_joypad = false
		BeeGameSettings.last_joypad_device = -1
		if was_active:
			show_device_notice("Teclado y ratón")

func _process(delta: float) -> void:
	device_notice_cooldown = maxf(0.0, device_notice_cooldown - delta)
	notice_left = maxf(0.0, notice_left - delta)
	notice.hide()
