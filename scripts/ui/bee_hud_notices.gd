extends CanvasLayer
## One top-centre lane: notices queue instead of overlapping HUD/boss labels.
const S := preload("res://scripts/game/bee_hud_text_settings.gd")
var label: Label
var panel: Panel
var pending: Array[Dictionary] = []
var active_kind := ""
var left := 0.0
var liberated_count := 0
var window_left := 0.0
var bucket := 0
var active_bucket := -1

static func for_host(host: Node) -> CanvasLayer:
	var owner_node := host
	while owner_node.get_parent() != null and owner_node.get_parent() != host.get_tree().root:
		owner_node = owner_node.get_parent()
	var existing := owner_node.get_node_or_null("HUDNotices")
	if existing != null:
		return existing as CanvasLayer
	var notices := load("res://scripts/ui/bee_hud_notices.gd").new() as CanvasLayer
	notices.name = "HUDNotices"
	owner_node.add_child(notices)
	return notices

func _ready() -> void:
	layer = 30
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -S.BANNER_WIDTH / 2
	panel.offset_right = S.BANNER_WIDTH / 2
	panel.offset_top = S.BANNER_TOP
	panel.offset_bottom = S.BANNER_TOP + S.BANNER_HEIGHT
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.035, 0.055, 0.88)
	style.border_color = Color(0.82, 0.69, 0.33, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 0.96, 0.8))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	panel.hide()

func show_notice(text: String, seconds: float, kind := "notice", small := false) -> void:
	var item := {"text": text, "seconds": seconds, "kind": kind, "small": small}
	if left <= 0:
		_display(item)
	else:
		pending.append(item)

func _display(item: Dictionary) -> void:
	active_kind = item.kind
	active_bucket = int(item.get("bucket", -1))
	label.text = ("Nova de polen lista: " + preload("res://scripts/game/bee_pollen_nova_settings.gd").button_hint()) if item.kind == "pollen_ready" else str(item.text)
	label.add_theme_font_size_override("font_size", S.SMALL_FONT if item.small else S.BANNER_FONT)
	left = item.seconds
	panel.modulate.a = 1
	panel.show()

func note_liberated() -> void:
	if window_left <= 0:
		liberated_count = 0
		window_left = S.LIBERATION_WINDOW
		bucket += 1
	liberated_count += 1
	var text := "+%d LIBERADOS" % liberated_count
	if active_kind == "liberated" and active_bucket == bucket and left > 0:
		label.text = text
		left = window_left + S.FADE_SECONDS
	elif left <= 0:
		_display({"text": text, "seconds": window_left + S.FADE_SECONDS, "kind": "liberated", "small": false, "bucket": bucket})
	else:
		# Only one pending accumulated notice, also when another banner owns the lane.
		for item in pending:
			if item.kind == "liberated" and int(item.get("bucket", -1)) == bucket:
				item.text = text
				return
		pending.append({"text": text, "seconds": S.LIBERATION_WINDOW + S.FADE_SECONDS, "kind": "liberated", "small": false, "bucket": bucket})

func _process(delta: float) -> void:
	if active_kind == "pollen_ready":
		label.text = "Nova de polen lista: " + preload("res://scripts/game/bee_pollen_nova_settings.gd").button_hint()
	if active_kind == "device" and combat_active(get_parent()):
		left = 0.0
	window_left = maxf(0, window_left - delta)
	if window_left <= 0:
		liberated_count = 0
	left = maxf(0, left - delta)
	panel.modulate.a = clampf(left / S.FADE_SECONDS, 0, 1)
	if left <= 0:
		panel.hide()
		active_kind = ""
		if not pending.is_empty():
			_display(pending.pop_front())


static func combat_active(host: Node) -> bool:
	if host == null: return false
	var wave := host.get_node_or_null("WaveController") as BeeLevel01Controller
	if wave == null and host is BeeShmupStage: wave = host.wave as BeeLevel01Controller
	if wave == null: return false
	return wave.in_arena() or wave.boss_active() or not wave.active_units.is_empty() or (is_instance_valid(wave.miniboss) and wave.miniboss.health.current_health > 0)
