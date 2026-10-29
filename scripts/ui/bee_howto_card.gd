extends CanvasLayer
## Tanda E2: "CÓMO JUGAR" card shown during the 4 s introductory flight of Level 1 (keyboard or gamepad wording from the last device used).
## It can be dismissed after MIN_SECONDS with any key / button / click.
signal dismissed
const GUIDE := preload("res://scripts/game/bee_controls_guide.gd")
const MIN_SECONDS := 0.2
var age := 0.0
var closed := false
var training := false
var bee: BeePlayer
var juice: BeeLevel01Juice
var step_index := 0
var _last_count := 0
var _skip_hold := 0.0
var _granted_bomb := false
var _granted_pollen := false
var panel: PanelContainer
var body: Label

static func lines(gamepad: bool) -> Array[String]:
	return GUIDE.lines(gamepad)

func _ready() -> void:
	if bee == null and get_parent() is BeeShmupStage:
		bee = (get_parent() as BeeShmupStage).bee
	if juice == null and get_parent() != null:
		juice = get_parent().get_node_or_null("Juice") as BeeLevel01Juice
	name = "HowToCard"
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(720, 0)
	panel.offset_left = -360.0
	panel.offset_right = 360.0
	panel.offset_top = -150.0
	panel.offset_bottom = 150.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.04, 0.82)
	style.border_color = Color(1.0, 0.78, 0.16)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = "ENTRENAMIENTO" if training else "CONTROLES"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.16))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	body = Label.new()
	body.add_theme_font_size_override("font_size", 22)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	add_child(panel)
	_prepare_step()
	_refresh()

func _refresh() -> void:
	if training:
		body.text = "%s  PASO %d/%d\n\n%s\n\nHacé la acción para seguir. Enter para saltear; mantené A 1 s en mando." % [GUIDE.device_icon(BeeGameSettings.last_input_joypad), step_index + 1, GUIDE.STEPS.size(), GUIDE.description(GUIDE.STEPS[step_index], BeeGameSettings.last_input_joypad)]
	else:
		body.text = "\n".join(lines(BeeGameSettings.last_input_joypad)) + "\n\nEnter / A: cerrar"

func _prepare_step() -> void:
	if not training or bee == null or step_index >= GUIDE.STEPS.size():
		return
	match GUIDE.STEPS[step_index].id:
		&"fire": _last_count = bee.fire_trigger_count
		&"roll": _last_count = bee.roll_count
		&"melee": _last_count = bee.melee_count
		&"bomb":
			if bee.bomb_charges <= 0:
				bee.bomb_charges = 1
				_granted_bomb = true
			_last_count = bee.bomb_charges
			bee.weapon_state_changed.emit()
		&"pollen":
			_last_count = juice.novas_used
			if juice.pollen_progress() < 7:
				juice.pollen_total += 7 - juice.pollen_progress()
				_granted_pollen = true
				juice._refresh_pollen()

func _process(delta: float) -> void:
	age += delta
	if BeeGameSettings.last_input_joypad and BeeGameSettings.last_joypad_device >= 0 and Input.is_joy_button_pressed(BeeGameSettings.last_joypad_device, JOY_BUTTON_A):
		_skip_hold += delta
		if _skip_hold >= GUIDE.SKIP_HOLD_SECONDS:
			close()
	else:
		_skip_hold = 0.0
	if training and bee != null and not closed:
		var done := false
		match GUIDE.STEPS[step_index].id:
			&"move": done = bee.velocity.length_squared() > 0.1
			&"fire": done = bee.fire_trigger_count > _last_count
			&"roll": done = bee.roll_count > _last_count
			&"melee": done = bee.melee_count > _last_count
			&"bomb": done = bee.bomb_charges < _last_count
			&"pollen": done = juice.novas_used > _last_count
		if done:
			step_index += 1
			if step_index >= GUIDE.STEPS.size():
				close()
				return
			_prepare_step()
	_refresh()

func _input(event: InputEvent) -> void:
	if closed or (not training and age < MIN_SECONDS) or event.is_echo():
		return
	if (event is InputEventKey and event.keycode == KEY_ENTER) or (not training and event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A):
		close()

func close() -> void:
	if closed:
		return
	closed = true
	if training:
		if _granted_bomb and bee.bomb_charges > 0:
			bee.bomb_charges -= 1
			bee.weapon_state_changed.emit()
		if _granted_pollen and juice != null and juice.novas_used == _last_count:
			juice.pollen_total -= 7
			juice._refresh_pollen()
		GUIDE.mark_seen()
	dismissed.emit()
	queue_free()
