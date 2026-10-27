extends CanvasLayer
## Tanda E2: "CÓMO JUGAR" card shown during the 4 s introductory flight of Level 1 (keyboard or gamepad wording from the last device used).
## It can be dismissed after MIN_SECONDS with any key / button / click.
signal dismissed
const MIN_SECONDS := 1.5
var age := 0.0
var closed := false
var panel: PanelContainer
var body: Label

static func lines(gamepad: bool) -> Array[String]:
	if gamepad:
		return ["Moverse: Stick izq.", "Disparar: A / RT (R2)", "Pirueta (esquivar, romper red): B / LB (L1)", "Puñetazo (cerca): Y / RB (R1)",
				"Polen (curar +25 % y escudo 2,5 s): LT (L2) · 1 cartucho = 7 granos", "Bomba: X"]
	return ["Moverse: WASD / Flechas", "Disparar: X / Clic izq.", "Pirueta (esquivar, romper red): Shift", "Puñetazo (cerca): Z",
			"Polen (curar +25 % y escudo 2,5 s): Q · 1 cartucho = 7 granos", "Bomba: C"]

func _ready() -> void:
	name = "HowToCard"
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(620, 0)
	panel.offset_left = -310.0
	panel.offset_right = 310.0
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
	title.text = "CÓMO JUGAR"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.16))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	body = Label.new()
	body.add_theme_font_size_override("font_size", 19)
	box.add_child(body)
	add_child(panel)
	_refresh()

func _refresh() -> void:
	body.text = "\n".join(lines(BeeGameSettings.last_input_joypad))

func _process(delta: float) -> void:
	age += delta
	_refresh()

func _input(event: InputEvent) -> void:
	if closed or age < MIN_SECONDS or event.is_echo():
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
		close()

func close() -> void:
	if closed:
		return
	closed = true
	dismissed.emit()
	queue_free()
