extends "res://scripts/art/title_screen_v01.gd"
## NOCHE 01 · ETAPA 2 — the game's title screen (main scene). It REUSES Codex's title POC (scripts/art/title_screen_v01.gd:
## garden backdrop, Bee, logo, warm buttons) without modifying it, and adapts the menu:
##   Jugar Nivel 01   opens Level 01 (and marks that we came from the title: the level returns here when completed)
##   Dificultad       toggles FÁCIL / NORMAL (BeeGameSettings)
##   Colección de arte  only in debug mode (editor runs or --debug-art): hidden in an exported game
##   Salir

const PLAY_TEXT := "Jugar Nivel 01"
const ART_TEXT := "Colección de arte"
const DIFFICULTY_PREFIX := "Dificultad: "
const SHAKE_PREFIX := "Temblor de pantalla: "
const LAKE_TEXT := "Laguna (prototipo · debug)"
const LAKE_SCENE := "res://scenes/levels/bee_level_02_lake.tscn"

var difficulty_button: Button
var shake_button: Button


func _ready() -> void:
	super._ready()
	BeeMusic.play(&"title") # LOTE 14: the title theme loops here (MusicManager).


static func debug_menu_enabled() -> bool:
	return OS.has_feature("editor") or "--debug-art" in OS.get_cmdline_user_args()


func _make_ui() -> void:
	super._make_ui()
	var play: Button = null
	for button: Button in ui.find_children("*", "Button", true, false):
		if button.text == ART_TEXT and not debug_menu_enabled():
			button.get_parent().remove_child(button)
			button.queue_free()
		elif button.text == PLAY_TEXT:
			play = button
	if play == null:
		return
	# The Play button keeps Codex's style; it now also tells the level it was opened from here.
	for connection in play.pressed.get_connections():
		play.pressed.disconnect(connection["callable"])
	difficulty_button = play.duplicate(0) as Button # No signals copied.
	play.pressed.connect(_play)
	difficulty_button.name = "DifficultyButton"
	play.get_parent().add_child(difficulty_button)
	play.get_parent().move_child(difficulty_button, play.get_index() + 1)
	difficulty_button.pressed.connect(_toggle_difficulty)
	shake_button = play.duplicate(0) as Button # LOTE 11: camera shake on / off.
	shake_button.name = "ShakeButton"
	play.get_parent().add_child(shake_button)
	play.get_parent().move_child(shake_button, difficulty_button.get_index() + 1)
	shake_button.pressed.connect(_toggle_shake)
	if debug_menu_enabled():
		# NOCHE 01 · ETAPA 4: the Level 02 "Laguna" prototype, debug only (the normal flow stays Level 01).
		var lake := play.duplicate(0) as Button
		lake.name = "LakePrototypeButton"
		lake.text = LAKE_TEXT
		play.get_parent().add_child(lake)
		play.get_parent().move_child(lake, difficulty_button.get_index() + 1)
		lake.pressed.connect(_play_lake)
	_refresh_difficulty()
	var vibration := play.duplicate(0) as Button
	vibration.name = "VibrationButton"
	vibration.text = "Vibración: " + ("SÍ" if BeeGameSettings.vibration_enabled else "NO")
	vibration.pressed.connect(func():
		BeeGameSettings.vibration_enabled = not BeeGameSettings.vibration_enabled
		vibration.text = "Vibración: " + ("SÍ" if BeeGameSettings.vibration_enabled else "NO"))
	play.get_parent().add_child(vibration)
	for spec in [["MÚSICA", BeeGameSettings.music_volume, BeeMusic.set_music_volume], ["EFECTOS", BeeGameSettings.sfx_volume, BeeMusic.set_sfx_volume]]:
		var row := HBoxContainer.new()
		var caption := Label.new()
		caption.text = "%s %d %%" % [spec[0], roundi(float(spec[1]) * 100.0)]
		caption.custom_minimum_size.x = 145
		row.add_child(caption)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = spec[1]
		slider.custom_minimum_size = Vector2(180, 24)
		slider.focus_mode = Control.FOCUS_ALL
		var setter: Callable = spec[2]
		var title: String = spec[0]
		slider.value_changed.connect(func(value: float):
			caption.text = "%s %d %%" % [title, roundi(value * 100.0)]
			setter.call(value))
		row.add_child(slider)
		play.get_parent().add_child(row)
	for spec in [["Aviso visual", "SHOT_WARNING_VISUAL_ENABLED"], ["Aviso sonoro", "SHOT_WARNING_AUDIO_ENABLED"], ["Flechas de borde", "SHOT_WARNING_EDGE_ENABLED"]]:
		var toggle := play.duplicate(0) as Button
		var title: String = spec[0]
		var setting: String = spec[1]
		toggle.text = title + (": SÍ" if BeeGameSettings.warning_enabled(setting) else ": NO")
		toggle.pressed.connect(func():
			var enabled := BeeGameSettings.toggle_warning(setting)
			toggle.text = title + (": SÍ" if enabled else ": NO"))
		play.get_parent().add_child(toggle)
	_fit_menu(play.get_parent() as VBoxContainer)
	play.grab_focus()

func _fit_menu(menu: VBoxContainer) -> void:
	var stack := menu.get_parent() as VBoxContainer
	var index := menu.get_index()
	var scroll := ScrollContainer.new()
	scroll.name = "TitleMenuScroll"
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(BeeGameSettings.TITLE_MENU_WIDTH, get_viewport().get_visible_rect().size.y * BeeGameSettings.TITLE_MENU_HEIGHT_FRACTION)
	stack.remove_child(menu)
	stack.add_child(scroll)
	stack.move_child(scroll, index)
	scroll.add_child(menu)
	var logo := ui.find_child("Logo", true, false) as TextureRect
	if logo != null:
		logo.custom_minimum_size.y = get_viewport().get_visible_rect().size.y * BeeGameSettings.TITLE_LOGO_HEIGHT_FRACTION
	stack.add_theme_constant_override("separation", 8)
	for child in stack.get_children():
		if child.get_class() == "Control":
			(child as Control).custom_minimum_size.y = 0.0
	var margin := stack.get_parent() as MarginContainer
	if margin != null:
		margin.add_theme_constant_override("margin_top", BeeGameSettings.TITLE_MENU_MARGIN)
		margin.add_theme_constant_override("margin_bottom", BeeGameSettings.TITLE_MENU_MARGIN)


func _toggle_shake() -> void:
	BeeGameSettings.screen_shake_enabled = not BeeGameSettings.screen_shake_enabled
	_refresh_difficulty()


func _play() -> void:
	BeeGameSettings.from_title = true
	get_tree().change_scene_to_file(BeeGameSettings.LEVEL_01)


func _toggle_difficulty() -> void:
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL if BeeGameSettings.difficulty == BeeGameSettings.EASY else BeeGameSettings.EASY
	_refresh_difficulty()


func _refresh_difficulty() -> void:
	if difficulty_button != null:
		difficulty_button.text = DIFFICULTY_PREFIX + BeeGameSettings.label()
	if shake_button != null:
		shake_button.text = SHAKE_PREFIX + BeeGameSettings.shake_label()


func _play_lake() -> void:
	BeeGameSettings.from_title = true
	get_tree().change_scene_to_file(LAKE_SCENE)
