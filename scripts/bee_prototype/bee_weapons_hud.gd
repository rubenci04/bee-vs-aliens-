extends Control

@export var bee_path: NodePath
@onready var bee: BeePlayer = get_node(bee_path)
var taught: Dictionary = {}
var debug_visible := false

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
	$Hint.position = Vector2(BeeGameSettings.HUD_PANEL_POSITION.x, BeeGameSettings.HUD_PANEL_POSITION.y + BeeGameSettings.HUD_PANEL_SIZE.y + BeeGameSettings.HUD_HINT_GAP)
	$Hint.offset_right = 620.0
	_sync_text_debug()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(BeeGameSettings.HUD_DEBUG_ACTION):
		debug_visible = not debug_visible
	_sync_text_debug()
	queue_redraw()
	if not taught.has(&"roll") and get_tree().get_nodes_in_group("alien_projectiles").size() >= BeeGameSettings.PIRUETA_HINT_SHOT_COUNT:
		taught[&"roll"] = true
		$Hint.text = "PIRUETA · %s: esquiva y rompe disparos" % ("B / LB" if BeeGameSettings.last_input_joypad else "SHIFT")
		$Hint.show()
		$HintTimer.start()

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
	draw_string(font, panel + Vector2(16, BeeGameSettings.HUD_ROW_HEALTH_Y), "VIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)
	for i in health_cells:
		var fill := clampf(hp_ratio * health_cells - i, 0.0, 1.0)
		_draw_hex(panel + Vector2(BeeGameSettings.HUD_HEALTH_CELL_START_X + i * (cell_w + BeeGameSettings.HUD_CELL_GAP), BeeGameSettings.HUD_ROW_HEALTH_Y - 14.0), cell_w, cell_h, BeeGameSettings.HUD_HEALTH_COLOR.lerp(BeeGameSettings.HUD_EMPTY_COLOR, 1.0 - fill))
	draw_string(font, panel + Vector2(BeeGameSettings.HUD_VALUE_START_X, BeeGameSettings.HUD_ROW_HEALTH_Y), "%d/%d" % [health.current_health, health.max_health], HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

	var pollen_progress := 0
	var banked_heals := 0
	if juice != null:
		pollen_progress = int(juice.call("pollen_progress"))
		banked_heals = int(juice.get("banked_heals"))
	draw_string(font, panel + Vector2(16, BeeGameSettings.HUD_ROW_POLLEN_Y), "POLEN", HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)
	for i in BeeGameSettings.HUD_POLLEN_CELLS:
		var fill := clampf(float(pollen_progress) / BeeLevel01Juice.POLLEN_PER_HEAL * BeeGameSettings.HUD_POLLEN_CELLS - i, 0.0, 1.0)
		_draw_hex(panel + Vector2(BeeGameSettings.HUD_HEALTH_CELL_START_X + i * (cell_w + BeeGameSettings.HUD_CELL_GAP), BeeGameSettings.HUD_ROW_POLLEN_Y - 14.0), cell_w, cell_h, BeeGameSettings.HUD_POLLEN_COLOR.lerp(BeeGameSettings.HUD_EMPTY_COLOR, 1.0 - fill))
	var pollen_text := "%d/%d" % [pollen_progress, BeeLevel01Juice.POLLEN_PER_HEAL]
	if banked_heals > 0:
		pollen_text += "  +"
	draw_string(font, panel + Vector2(BeeGameSettings.HUD_VALUE_START_X, BeeGameSettings.HUD_ROW_POLLEN_Y), pollen_text, HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

	_draw_bombs(panel + Vector2(38, BeeGameSettings.HUD_ROW_ABILITY_Y - 13.0))
	_draw_roll(panel + Vector2(200, BeeGameSettings.HUD_ROW_ABILITY_Y - 2.0))
	_draw_stinger(panel + Vector2(356, BeeGameSettings.HUD_ROW_ABILITY_Y - 4.0))
	var spread_text := "SPREAD %.0f s" % ceilf(bee.spread_ammo) if bee.spread_ammo > 0.0 else "BASE"
	draw_string(font, panel + Vector2(442, BeeGameSettings.HUD_ROW_ABILITY_Y + 1.0), spread_text, HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_POLLEN_COLOR if bee.spread_ammo > 0.0 else BeeGameSettings.HUD_LABEL_COLOR)

	_draw_combo(viewport_size, juice, font)

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
	var font := ThemeDB.fallback_font
	draw_string(font, origin + Vector2(-18, -5), "BOMBAS", HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_SMALL_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)
	for i in BeeGameSettings.HUD_BOMB_ICON_COUNT:
		var center := origin + Vector2(12 + i * 22, 15)
		var color := BeeGameSettings.HUD_POLLEN_COLOR if i < bee.bomb_charges else BeeGameSettings.HUD_EMPTY_COLOR
		draw_circle(center, 7.0, color)
		draw_arc(center, 7.0, 0, TAU, 16, BeeGameSettings.HUD_LABEL_COLOR, 1.2, true)
		draw_line(center + Vector2(0, -6), center + Vector2(4, -11), BeeGameSettings.HUD_LABEL_COLOR, 2.0, true)

func _draw_roll(center: Vector2) -> void:
	var ratio := bee.roll_ready_ratio()
	draw_arc(center, 15.0, 0.0, TAU, 32, BeeGameSettings.HUD_EMPTY_COLOR, 3.0, true)
	if ratio < 1.0:
		draw_arc(center, 15.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 32, BeeGameSettings.HUD_READY_COLOR, 3.0, true)
	else:
		draw_arc(center, 15.0, 0.0, TAU, 32, BeeGameSettings.HUD_READY_COLOR, 2.0, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(7, -9), center + Vector2(13, -11), center + Vector2(11, -4)]), BeeGameSettings.HUD_READY_COLOR)
	var button := "B/LB" if BeeGameSettings.last_input_joypad else "SHIFT"
	draw_string(ThemeDB.fallback_font, center + Vector2(22, 5), "PIRUETA %s" % button, HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_SMALL_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

func _draw_stinger(origin: Vector2) -> void:
	var color := BeeGameSettings.HUD_HEALTH_COLOR
	draw_line(origin + Vector2(0, 14), origin + Vector2(28, 0), color, 4.0, true)
	draw_colored_polygon(PackedVector2Array([origin + Vector2(29, -2), origin + Vector2(41, -7), origin + Vector2(34, 4)]), color)
	draw_line(origin + Vector2(3, 18), origin + Vector2(10, 6), BeeGameSettings.HUD_LABEL_COLOR, 3.0, true)
	var button := "Y/RB" if BeeGameSettings.last_input_joypad else "Z"
	draw_string(ThemeDB.fallback_font, origin + Vector2(46, 12), "AGUIJÓN %s" % button, HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_SMALL_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

func _draw_combo(viewport_size: Vector2, juice: Node, font: Font) -> void:
	var rect := Rect2(Vector2(maxf(BeeGameSettings.HUD_PANEL_POSITION.x + BeeGameSettings.HUD_PANEL_SIZE.x + 18.0, viewport_size.x - BeeGameSettings.HUD_COMBO_PANEL_SIZE.x - 20.0), BeeGameSettings.HUD_PANEL_POSITION.y), BeeGameSettings.HUD_COMBO_PANEL_SIZE)
	_draw_panel(rect)
	var combo := int(juice.get("combo")) if juice != null else 0
	var frenzy_left := bee.honey_left
	draw_string(font, rect.position + Vector2(16, 28), "COMBO", HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)
	draw_string(font, rect.position + Vector2(102, 31), "x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, BeeGameSettings.HUD_COMBO_COLOR)
	var bar := Rect2(rect.position + Vector2(16, 43), Vector2(rect.size.x - 32, 10))
	draw_rect(bar, BeeGameSettings.HUD_EMPTY_COLOR, true, -1.0, true)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(float(combo) / BeeLevel01Juice.FRENZY_COMBO, 0.0, 1.0), bar.size.y)), BeeGameSettings.HUD_COMBO_COLOR, true, -1.0, true)
	var state_text := "FRENESÍ %.1f s" % frenzy_left if frenzy_left > 0.0 else "META x%d" % BeeLevel01Juice.FRENZY_COMBO
	draw_string(font, rect.position + Vector2(16, 78), state_text, HORIZONTAL_ALIGNMENT_LEFT, -1, BeeGameSettings.HUD_SMALL_FONT_SIZE, BeeGameSettings.HUD_LABEL_COLOR)

func show_hint(kind: StringName) -> void:
	if taught.has(kind):
		return
	taught[kind] = true
	$Hint.text = ("SPREAD · A / RT — DISPARAR" if BeeGameSettings.last_input_joypad else "SPREAD · X / CLIC — DISPARAR") if kind == &"spread" else ("BOMBA · X — USAR" if BeeGameSettings.last_input_joypad else "BOMBA · C — USAR")
	$Hint.show()
	$HintTimer.start()
