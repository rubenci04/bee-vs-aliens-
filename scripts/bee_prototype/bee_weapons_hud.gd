extends Control
const HUD_NOTICES := preload("res://scripts/ui/bee_hud_notices.gd")
const HUD_TEXT := preload("res://scripts/game/bee_hud_text_settings.gd")

@export var bee_path: NodePath
@onready var bee: BeePlayer = get_node(bee_path)
var taught: Dictionary = {}
var debug_visible := false
var death_panel: Panel
var death_label: Label
var legend_left := BeeGameSettings.HUD_LEGEND_SECONDS ## TANDA 1 · H-01: the controls legend is temporary.

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bee.weapon_state_changed.connect(queue_redraw)
	bee.powerup_collected.connect(show_hint)
	bee.defeated.connect(func(): $Hint.hide())
	$HintTimer.timeout.connect(func(): $Hint.hide())
	$Hint.add_theme_font_size_override("font_size", BeeGameSettings.HUD_FONT_SIZE)
	$Hint.add_theme_color_override("font_color", BeeGameSettings.HUD_LABEL_COLOR)
	$Hint.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.05, 1.0))
	$Hint.add_theme_constant_override("outline_size", 5)
	$Hint.position = Vector2(BeeGameSettings.HUD_PANEL_POSITION.x, BeeGameSettings.HUD_PANEL_POSITION.y + BeeGameSettings.HUD_PANEL_SIZE.y + BeeGameSettings.HUD_HINT_GAP + 18.0)
	$Hint.offset_right = 620.0
	_build_death_message()
	bee.defeated.connect(_show_death_message)
	_sync_text_debug()

func _process(delta: float) -> void:
	legend_left = maxf(0.0, legend_left - delta)
	if Input.is_action_just_pressed(BeeGameSettings.HUD_DEBUG_ACTION):
		debug_visible = not debug_visible
	_sync_text_debug()
	if death_panel != null and death_panel.visible:
		death_label.text = _death_prompt()
	queue_redraw()
	if not taught.has(&"roll") and get_tree().get_nodes_in_group("alien_projectiles").size() >= BeeGameSettings.PIRUETA_HINT_SHOT_COUNT:
		show_hint(&"roll")
	if not taught.has(&"stinger") and bee.nearest_melee_target() != null:
		show_hint(&"stinger")

func refresh() -> void:
	queue_redraw()

func spread_status_text() -> String:
	return "SPREAD %.0f s" % ceilf(bee.spread_ammo) if bee.spread_ammo > 0.0 else "BASE"

func displayed_bomb_icons() -> int:
	return clampi(bee.bomb_charges, 0, BeeGameSettings.HUD_BOMB_ICON_COUNT)

func pirueta_ready_ratio() -> float:
	return bee.roll_ready_ratio()

func control_text() -> String:
	if BeeGameSettings.last_input_joypad:
		return "FUEGO A / RT   BOMBA X   PIRUETA B / LB   AGUIJÓN Y / RB"
	return "FUEGO X / CLIC   BOMBA C   PIRUETA SHIFT   AGUIJÓN Z"

func _sync_text_debug() -> void:
	var stage := bee.get_parent() as Node
	if stage == null:
		return
	var status := stage.get_node_or_null("CanvasLayer/Status") as Label
	var debug := stage.get_node_or_null("CanvasLayer/Debug") as Label
	if status != null:
		status.visible = debug_visible
	if debug != null:
		debug.visible = debug_visible
	var juice := stage.get_node_or_null("Juice")
	if juice == null:
		return
	for property in [&"combo_label", &"pollen_label", &"frenzy_label"]:
		var label: Variant = juice.get(property)
		if label is Label:
			(label as Label).visible = debug_visible and (property != &"combo_label" or int(juice.get("combo")) >= 2)

func _build_death_message() -> void:
	death_panel = Panel.new()
	death_panel.name = "DeathMessage"
	death_panel.visible = false
	death_panel.set_anchors_preset(Control.PRESET_CENTER)
	death_panel.offset_left = -BeeGameSettings.HUD_TERMINAL_PANEL_SIZE.x * 0.5
	death_panel.offset_right = BeeGameSettings.HUD_TERMINAL_PANEL_SIZE.x * 0.5
	death_panel.offset_top = -BeeGameSettings.HUD_TERMINAL_PANEL_SIZE.y * 0.5
	death_panel.offset_bottom = BeeGameSettings.HUD_TERMINAL_PANEL_SIZE.y * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = BeeGameSettings.HUD_TERMINAL_PANEL_COLOR
	style.border_color = BeeGameSettings.HUD_PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	death_panel.add_theme_stylebox_override("panel", style)
	add_child(death_panel)
	death_label = Label.new()
	death_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_label.add_theme_font_size_override("font_size", BeeGameSettings.HUD_TERMINAL_FONT_SIZE)
	death_label.add_theme_color_override("font_color", BeeGameSettings.HUD_LABEL_COLOR)
	death_label.add_theme_color_override("font_outline_color", Color.BLACK)
	death_label.add_theme_constant_override("outline_size", 6)
	death_panel.add_child(death_label)

func _death_prompt() -> String:
	var button := "Y" if BeeGameSettings.last_input_joypad else "R"
	var stage := bee.get_parent()
	var checkpoint := stage.get_node_or_null("CheckpointQoL") as BeeCheckpointQoL
	var verb := "REAPARECER" if checkpoint != null and checkpoint.checkpoint_active else "REINICIAR"
	return "PULSÁ %s PARA %s" % [button, verb]

func _show_death_message() -> void:
	if death_panel == null:
		return
	death_label.text = _death_prompt()
	death_panel.show()

func _draw() -> void:
	if not is_instance_valid(bee):
		return
	var viewport_size := get_viewport_rect().size
	var panel := BeeGameSettings.HUD_PANEL_POSITION
	var font := ThemeDB.fallback_font
	var main_rect := Rect2(panel, BeeGameSettings.HUD_PANEL_SIZE)
	_draw_panel(main_rect)
	var juice := bee.get_parent().get_node_or_null("Juice")
	var health := bee.health
	var hp_ratio := clampf(float(health.current_health) / maxf(1.0, float(health.max_health)), 0.0, 1.0)
	var health_cells := BeeGameSettings.HUD_HEALTH_CELLS
	var cell_w := BeeGameSettings.HUD_HEX_WIDTH
	var cell_h := BeeGameSettings.HUD_HEX_HEIGHT
	draw_string(font, panel + Vector2(10, BeeGameSettings.HUD_ROW_HEALTH_Y), "VIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)
	for i in health_cells:
		var fill := clampf(hp_ratio * health_cells - i, 0.0, 1.0)
		_draw_hex(panel + Vector2(BeeGameSettings.HUD_HEALTH_CELL_START_X + i * (cell_w + BeeGameSettings.HUD_CELL_GAP), BeeGameSettings.HUD_ROW_HEALTH_Y - 14.0), cell_w, cell_h, BeeGameSettings.HUD_HEALTH_COLOR.lerp(BeeGameSettings.HUD_EMPTY_COLOR, 1.0 - fill))
	draw_string(font, panel + Vector2(BeeGameSettings.HUD_VALUE_START_X, BeeGameSettings.HUD_ROW_HEALTH_Y), "%d/%d" % [health.current_health, health.max_health], HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

	var pollen_progress := 0
	var banked_heals := 0
	if juice != null:
		pollen_progress = int(juice.call("pollen_progress"))
		banked_heals = int(juice.get("banked_heals"))
	draw_string(font, panel + Vector2(10, BeeGameSettings.HUD_ROW_POLLEN_Y), "POLEN", HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)
	for i in BeeGameSettings.HUD_POLLEN_CELLS:
		var fill := clampf(float(pollen_progress) / BeeLevel01Juice.POLLEN_PER_HEAL * BeeGameSettings.HUD_POLLEN_CELLS - i, 0.0, 1.0)
		_draw_hex(panel + Vector2(BeeGameSettings.HUD_HEALTH_CELL_START_X + i * (cell_w + BeeGameSettings.HUD_CELL_GAP), BeeGameSettings.HUD_ROW_POLLEN_Y - 14.0), cell_w, cell_h, BeeGameSettings.HUD_POLLEN_COLOR.lerp(BeeGameSettings.HUD_EMPTY_COLOR, 1.0 - fill))
	var pollen_text := "%d/%d" % [pollen_progress, BeeLevel01Juice.POLLEN_PER_HEAL]
	if banked_heals > 0:
		pollen_text += "  +"
	draw_string(font, panel + Vector2(BeeGameSettings.HUD_VALUE_START_X, BeeGameSettings.HUD_ROW_POLLEN_Y), pollen_text, HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

	_draw_bombs(panel + Vector2(14, BeeGameSettings.HUD_ROW_ABILITY_Y - 8.0))
	_draw_roll(panel + Vector2(122, BeeGameSettings.HUD_ROW_ABILITY_Y - 3.0))
	_draw_stinger(panel + Vector2(184, BeeGameSettings.HUD_ROW_ABILITY_Y - 9.0))
	if bee.spread_ammo > 0.0: # H-02: no standalone "BASE" text; only the Spread timer, in its own slot.
		draw_string(font, panel + Vector2(252, BeeGameSettings.HUD_ROW_ABILITY_Y + 2.0), spread_status_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_POLLEN_COLOR)

	_draw_combo(viewport_size, juice, font)

func panel_bottom_gap() -> float:
	return BeeGameSettings.HUD_PANEL_SIZE.y + 14.0

func _draw_panel(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(3, 4), rect.size), Color(0.0, 0.0, 0.0, 0.35), true, -1.0, true)
	draw_rect(rect, BeeGameSettings.HUD_PANEL_COLOR, true, -1.0, true)
	draw_rect(rect, BeeGameSettings.HUD_PANEL_BORDER, false, 2.0, true)

func _draw_hex(origin: Vector2, width: float, height: float, color: Color) -> void:
	var points := PackedVector2Array([
		origin + Vector2(width * 0.25, 0), origin + Vector2(width * 0.75, 0),
		origin + Vector2(width, height * 0.5), origin + Vector2(width * 0.75, height),
		origin + Vector2(width * 0.25, height), origin + Vector2(0, height * 0.5),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[5], points[0]]), BeeGameSettings.HUD_LABEL_COLOR, 1.0, true)

func _draw_bombs(origin: Vector2) -> void:
	for i in BeeGameSettings.HUD_BOMB_ICON_COUNT:
		var center := origin + Vector2(6 + i * 17, 8)
		var color := BeeGameSettings.HUD_POLLEN_COLOR if i < displayed_bomb_icons() else BeeGameSettings.HUD_EMPTY_COLOR
		draw_circle(center, 6.0, color)
		draw_arc(center, 6.0, 0, TAU, 16, BeeGameSettings.HUD_LABEL_COLOR, 1.0, true)
		draw_line(center + Vector2(0, -5), center + Vector2(3, -9), BeeGameSettings.HUD_LABEL_COLOR, 1.6, true)

func _draw_roll(center: Vector2) -> void:
	var ratio := pirueta_ready_ratio()
	draw_arc(center, 11.0, 0.0, TAU, 32, BeeGameSettings.HUD_EMPTY_COLOR, 3.0, true)
	if ratio < 1.0:
		draw_arc(center, 11.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 32, BeeGameSettings.HUD_READY_COLOR, 3.0, true)
	else:
		draw_arc(center, 11.0, 0.0, TAU, 32, BeeGameSettings.HUD_READY_COLOR, 2.0, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(5, -7), center + Vector2(10, -8), center + Vector2(8, -3)]), BeeGameSettings.HUD_READY_COLOR)
	var button := "B/LB" if BeeGameSettings.last_input_joypad else "SHIFT"
	draw_string(ThemeDB.fallback_font, center + Vector2(16, 4), button, HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_SMALL_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

func _draw_stinger(origin: Vector2) -> void:
	var color := BeeGameSettings.HUD_HEALTH_COLOR
	draw_line(origin + Vector2(0, 12), origin + Vector2(20, 0), color, 3.0, true)
	draw_colored_polygon(PackedVector2Array([origin + Vector2(21, -2), origin + Vector2(30, -6), origin + Vector2(25, 3)]), color)
	draw_line(origin + Vector2(2, 15), origin + Vector2(7, 5), BeeGameSettings.HUD_LABEL_COLOR, 2.0, true)
	var button := "Y/RB" if BeeGameSettings.last_input_joypad else "Z"
	draw_string(ThemeDB.fallback_font, origin + Vector2(36, 11), button, HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_SMALL_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

func _draw_combo(viewport_size: Vector2, juice: Node, font: Font) -> void:
	var rect := Rect2(Vector2(maxf(BeeGameSettings.HUD_PANEL_POSITION.x + BeeGameSettings.HUD_PANEL_SIZE.x + 18.0, viewport_size.x - BeeGameSettings.HUD_COMBO_PANEL_SIZE.x - 12.0), BeeGameSettings.HUD_PANEL_POSITION.y), BeeGameSettings.HUD_COMBO_PANEL_SIZE)
	_draw_panel(rect)
	var combo := int(juice.get("combo")) if juice != null else 0
	var frenzy_left := bee.honey_left
	draw_string(font, rect.position + Vector2(12, 20), "COMBO", HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)
	draw_string(font, rect.position + Vector2(80, 22), "x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, BeeGameSettings.HUD_COMBO_COLOR)
	var bar := Rect2(rect.position + Vector2(12, 29), Vector2(rect.size.x - 24, 8))
	draw_rect(bar, BeeGameSettings.HUD_EMPTY_COLOR, true, -1.0, true)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(float(combo) / BeeLevel01Juice.FRENZY_COMBO, 0.0, 1.0), bar.size.y)), BeeGameSettings.HUD_COMBO_COLOR, true, -1.0, true)
	var state_text := "FRENESÍ %.1f s" % frenzy_left if frenzy_left > 0.0 else "META x%d" % BeeLevel01Juice.FRENZY_COMBO
	draw_string(font, rect.position + Vector2(12, 55), state_text, HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_SMALL_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

func show_hint(kind: StringName) -> void:
	if taught.has(kind):
		return
	taught[kind] = true
	var tips := {&"spread": "Spread: cubrí más espacio", &"bomb": "Bomba: despejá el grupo", &"roll": "Pirueta: esquivá y rompé disparos", &"stinger": "Aguijón: liberá de cerca"}
	if not tips.has(kind):
		return
	$Hint.text = tips[kind] # Kept hidden; ability buttons already live in the HUD icons.
	$Hint.hide()
	HUD_NOTICES.for_host(self).show_notice(tips[kind], HUD_TEXT.TIP_SECONDS, "tip", true)
