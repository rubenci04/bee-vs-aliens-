extends Control

@export var bee_path: NodePath
@onready var bee: BeePlayer = get_node(bee_path)
var taught: Dictionary = {}
## LOTE 11: roll (Shift) recharge indicator under the weapon line.
const ROLL_BLOCKS := 10
const ROLL_READY_COLOR := Color(1.0, 0.9, 0.4)
const ROLL_CHARGING_COLOR := Color(0.75, 0.75, 0.8)
var roll_label: Label
## LOTE 14: sting (Z) recharge indicator under the roll line.
const STING_READY_COLOR := Color(0.85, 0.93, 1.0)
var sting_label: Label

func _ready() -> void:
	bee.weapon_state_changed.connect(refresh)
	bee.powerup_collected.connect(show_hint)
	bee.defeated.connect(func(): $Hint.hide())
	$HintTimer.timeout.connect(func(): $Hint.hide())
	_build_roll_label()
	_build_sting_label()
	refresh()

func _build_roll_label() -> void:
	roll_label = Label.new()
	roll_label.name = "RollLabel"
	roll_label.offset_left = 18.0
	roll_label.offset_top = 88.0
	roll_label.offset_right = 520.0
	roll_label.offset_bottom = 114.0
	roll_label.add_theme_font_size_override("font_size", 20)
	roll_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	roll_label.add_theme_constant_override("shadow_offset_x", 1)
	roll_label.add_theme_constant_override("shadow_offset_y", 1)
	roll_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(roll_label)

func _build_sting_label() -> void:
	sting_label = Label.new()
	sting_label.name = "StingLabel"
	sting_label.offset_left = 18.0
	sting_label.offset_top = 118.0
	sting_label.offset_right = 520.0
	sting_label.offset_bottom = 144.0
	sting_label.add_theme_font_size_override("font_size", 20)
	sting_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	sting_label.add_theme_constant_override("shadow_offset_x", 1)
	sting_label.add_theme_constant_override("shadow_offset_y", 1)
	sting_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sting_label)

func _process(_delta: float) -> void:
	refresh()
	if roll_label == null or bee == null:
		return
	var ratio := bee.roll_ready_ratio()
	var is_ready := ratio >= 1.0
	roll_label.text = "PIRUETA · " + ("B / LB" if BeeGameSettings.last_input_joypad else "SHIFT")
	roll_label.add_theme_color_override("font_color", ROLL_READY_COLOR if is_ready else ROLL_CHARGING_COLOR)
	sting_label.hide()
	queue_redraw()
	if not taught.has(&"roll") and get_tree().get_nodes_in_group("alien_projectiles").size() >= BeeGameSettings.PIRUETA_HINT_SHOT_COUNT:
		taught[&"roll"] = true
		$Hint.text = "PIRUETA · %s: esquiva y rompe disparos" % ("B / LB" if BeeGameSettings.last_input_joypad else "SHIFT")
		$Hint.show()
		$HintTimer.start()

func _draw() -> void:
	if is_instance_valid(bee) and bee.roll_ready_ratio() < 1.0:
		draw_arc(BeeGameSettings.PIRUETA_RING_POSITION, BeeGameSettings.PIRUETA_RING_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * bee.roll_ready_ratio(), 24, ROLL_READY_COLOR, 2.0, true)

func refresh() -> void:
	var weapon := "SPREAD %.1f s" % bee.spread_ammo if bee.spread_ammo > 0 else "BASE"
	var button := "X" if BeeGameSettings.last_input_joypad else "C"
	var action := button + (" — DETONAR" if is_instance_valid(bee.active_bomb) else " — BOMBA")
	$State.text = "%s · BOMB x%d · %s" % [weapon, bee.bomb_charges, action]

func show_hint(kind: StringName) -> void:
	if taught.has(kind):
		return
	taught[kind] = true
	$Hint.text = ("SPREAD · A / RT — DISPARAR" if BeeGameSettings.last_input_joypad else "SPREAD · X / CLIC — DISPARAR") if kind == &"spread" else ("BOMBA · X — USAR" if BeeGameSettings.last_input_joypad else "BOMBA · C — USAR")
	$Hint.show()
	$HintTimer.start()
