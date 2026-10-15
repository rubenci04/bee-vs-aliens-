extends Control
## Main title screen. Artwork has a gradient fallback so the menu remains usable without imported images.

const INTRO_SCENE := "res://scenes/game/bee_intro_screen.tscn"
const LAKE_SCENE := "res://scenes/levels/bee_level_02_lake.tscn"

var difficulty_button: Button
var shake_button: Button
var options_panel: VBoxContainer
var controls_panel: PanelContainer
var _logo: TextureRect


func _ready() -> void:
	_build_screen()
	BeeMusic.play(&"title")
	preload("res://scripts/game/bee_scene_fade.gd").enter(self)


static func debug_menu_enabled() -> bool:
	return preload("res://scripts/game/bee_readability_settings.gd").development_enabled()


func _build_screen() -> void:
	var background := TextureRect.new()
	background.name = "TitleBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = load(BeeGameSettings.TITLE_BACKGROUND_PATH) as Texture2D if ResourceLoader.exists(BeeGameSettings.TITLE_BACKGROUND_PATH) else null
	add_child(background)
	if background.texture == null:
		background.add_child(_make_gradient_fallback())

	var shade := ColorRect.new()
	shade.name = "TitleShade"
	shade.color = Color(0.015, 0.025, 0.045, 0.22)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	move_child(shade, 1)

	_logo = TextureRect.new()
	_logo.name = "Logo"
	_logo.texture = load(BeeGameSettings.TITLE_LOGO_PATH) as Texture2D if ResourceLoader.exists(BeeGameSettings.TITLE_LOGO_PATH) else null
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.anchor_left = 0.5
	_logo.anchor_right = 0.5
	_logo.anchor_top = 0.015
	_logo.anchor_bottom = 0.015
	_logo.offset_left = -BeeGameSettings.TITLE_LOGO_WIDTH * 0.5
	_logo.offset_right = BeeGameSettings.TITLE_LOGO_WIDTH * 0.5
	_logo.offset_top = 0.0
	_logo.offset_bottom = preload("res://scripts/game/bee_flow_settings.gd").TITLE_LOGO_HEIGHT
	_logo.pivot_offset = Vector2(BeeGameSettings.TITLE_LOGO_WIDTH * 0.5, BeeGameSettings.TITLE_LOGO_HEIGHT * 0.5)
	_logo.scale = Vector2.ONE * BeeGameSettings.TITLE_LOGO_START_SCALE
	add_child(_logo)
	if _logo.texture != null:
		var glow := TextureRect.new()
		glow.name = "LogoGlow"
		glow.texture = _logo.texture
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glow.modulate = Color(1.0, 0.78, 0.27, 0.0)
		glow.material = CanvasItemMaterial.new()
		glow.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_logo.add_child(glow)
		var glow_tween := create_tween().set_loops()
		glow_tween.tween_property(glow, "modulate:a", BeeGameSettings.TITLE_LOGO_GLOW_ALPHA, BeeGameSettings.TITLE_LOGO_GLOW_SECONDS)
		glow_tween.tween_property(glow, "modulate:a", BeeGameSettings.TITLE_LOGO_GLOW_MIN_ALPHA, BeeGameSettings.TITLE_LOGO_GLOW_SECONDS)
	var intro := create_tween()
	intro.tween_property(_logo, "scale", Vector2.ONE, BeeGameSettings.TITLE_LOGO_INTRO_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.parallel().tween_property(_logo, "modulate:a", 1.0, BeeGameSettings.TITLE_LOGO_INTRO_SECONDS)

	var tagline := Label.new()
	tagline.name = "Tagline"
	tagline.text = "UNA PEQUEÑA ABEJA, UN MUNDO ENORME"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", BeeGameSettings.TITLE_TAGLINE_FONT_SIZE)
	tagline.add_theme_color_override("font_color", Color("fff2ca"))
	tagline.add_theme_constant_override("outline_size", 5)
	tagline.add_theme_color_override("font_outline_color", Color("251b20"))
	tagline.anchor_left = 0.5
	tagline.anchor_right = 0.5
	tagline.anchor_top = preload("res://scripts/game/bee_flow_settings.gd").TAGLINE_TOP
	tagline.anchor_bottom = tagline.anchor_top
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.offset_left = -BeeGameSettings.TITLE_TAGLINE_WIDTH * 0.5
	tagline.offset_right = BeeGameSettings.TITLE_TAGLINE_WIDTH * 0.5
	tagline.offset_top = 0.0
	tagline.offset_bottom = 44.0
	add_child(tagline)

	var panel := PanelContainer.new()
	panel.name = "MenuPanel"
	panel.anchor_left = 0.0
	panel.anchor_top = preload("res://scripts/game/bee_flow_settings.gd").MENU_TOP
	panel.anchor_bottom = 1.0 - BeeGameSettings.TITLE_PANEL_BOTTOM_MARGIN
	panel.offset_left = BeeGameSettings.TITLE_PANEL_MARGIN
	panel.offset_top = 0.0
	panel.offset_right = BeeGameSettings.TITLE_PANEL_WIDTH + BeeGameSettings.TITLE_PANEL_MARGIN
	panel.offset_bottom = 0.0
	panel.custom_minimum_size.x = BeeGameSettings.TITLE_PANEL_WIDTH
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = BeeGameSettings.TITLE_PANEL_COLOR
	panel_style.border_color = BeeGameSettings.TITLE_PANEL_BORDER
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(BeeGameSettings.TITLE_PANEL_RADIUS)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.name = "TitleMenuScroll"
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var menu := VBoxContainer.new()
	menu.name = "TitleMenu"
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.add_theme_constant_override("separation", BeeGameSettings.TITLE_MENU_GAP)
	scroll.add_child(menu)

	var play := _button("Jugar", _play)
	play.name = "PlayButton"
	menu.add_child(play)
	difficulty_button = _button("", _toggle_difficulty)
	difficulty_button.name = "DifficultyButton"
	menu.add_child(difficulty_button)
	_refresh_settings_labels()
	var options := _button("Opciones ▸", _toggle_options)
	options.name = "OptionsButton"
	menu.add_child(options)
	options_panel = VBoxContainer.new()
	options_panel.name = "OptionsPanel"
	options_panel.visible = false
	options_panel.add_theme_constant_override("separation", 6)
	menu.add_child(options_panel)
	_add_volume_slider(options_panel, "Música", BeeGameSettings.music_volume, BeeMusic.set_music_volume)
	_add_volume_slider(options_panel, "Efectos", BeeGameSettings.sfx_volume, BeeMusic.set_sfx_volume)
	shake_button = _button("", _toggle_shake)
	shake_button.name = "ShakeButton"
	options_panel.add_child(shake_button)
	_refresh_settings_labels()
	var controls := _button("Controles", _show_controls)
	options_panel.add_child(controls)
	var intro_button := _button("Ver introducción", _show_intro)
	options_panel.add_child(intro_button)
	if debug_menu_enabled():
		menu.add_child(_button("Laguna (prototipo - debug)", _play_lake))
	menu.add_child(_button("Salir", func(): get_tree().quit()))
	play.grab_focus.call_deferred()


func _make_gradient_fallback() -> Control:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([BeeGameSettings.TITLE_FALLBACK_TOP, BeeGameSettings.TITLE_FALLBACK_BOTTOM])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	var fill := TextureRect.new()
	fill.name = "MissingArtGradient"
	fill.texture = texture
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.stretch_mode = TextureRect.STRETCH_SCALE
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return fill


func _button(caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, BeeGameSettings.TITLE_BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", BeeGameSettings.TITLE_BUTTON_FONT_SIZE)
	button.add_theme_color_override("font_color", Color("fff1d2"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = BeeGameSettings.TITLE_BUTTON_COLOR if state == "normal" else BeeGameSettings.TITLE_BUTTON_FOCUS_COLOR
		style.border_color = BeeGameSettings.TITLE_BUTTON_BORDER
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(BeeGameSettings.TITLE_BUTTON_RADIUS)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(action)
	return button


func _add_volume_slider(parent: Control, caption: String, initial: float, setter: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = "%s  %d%%" % [caption, roundi(initial * 100.0)]
	label.custom_minimum_size.x = 96
	label.add_theme_font_size_override("font_size", BeeGameSettings.TITLE_OPTION_FONT_SIZE)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.custom_minimum_size.x = BeeGameSettings.TITLE_SLIDER_WIDTH
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(func(value: float):
		label.text = "%s  %d%%" % [caption, roundi(value * 100.0)]
		setter.call(value))
	row.add_child(slider)
	parent.add_child(row)


func _refresh_settings_labels() -> void:
	if difficulty_button != null:
		difficulty_button.text = "Dificultad: " + BeeGameSettings.label()
	if shake_button != null:
		shake_button.text = "Temblor de pantalla: " + BeeGameSettings.shake_label()


func _toggle_difficulty() -> void:
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL if BeeGameSettings.difficulty == BeeGameSettings.EASY else BeeGameSettings.EASY
	_refresh_settings_labels()


func _toggle_shake() -> void:
	BeeGameSettings.screen_shake_enabled = not BeeGameSettings.screen_shake_enabled
	_refresh_settings_labels()


func _toggle_options() -> void:
	options_panel.visible = not options_panel.visible
	var button := find_child("OptionsButton", true, false) as Button
	button.text = "Opciones ▾" if options_panel.visible else "Opciones ▸"


func _show_controls() -> void:
	if controls_panel != null:
		controls_panel.queue_free()
	controls_panel = PanelContainer.new()
	controls_panel.name = "ControlsOverlay"
	controls_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	controls_panel.offset_left = -BeeGameSettings.TITLE_CONTROLS_WIDTH * 0.5
	controls_panel.offset_right = BeeGameSettings.TITLE_CONTROLS_WIDTH * 0.5
	controls_panel.offset_top = -BeeGameSettings.TITLE_CONTROLS_HEIGHT * 0.5
	controls_panel.offset_bottom = BeeGameSettings.TITLE_CONTROLS_HEIGHT * 0.5
	controls_panel.add_theme_stylebox_override("panel", _panel_style(BeeGameSettings.TITLE_PANEL_COLOR))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	controls_panel.add_child(box)
	var help := Label.new()
	help.text = "CONTROLES\nMover: WASD / flechas / palanca izquierda\nApuntar: mouse / palanca derecha\nDisparar: X / clic / A\nAguijón: Z · Bomba: C / X · Pirueta: Shift / B\nPausa: Esc / Start"
	help.add_theme_font_size_override("font_size", BeeGameSettings.TITLE_OPTION_FONT_SIZE)
	box.add_child(help)
	var close_button := _button("Cerrar", _close_controls)
	box.add_child(close_button)
	add_child(controls_panel)
	close_button.grab_focus.call_deferred()


func _close_controls() -> void:
	if controls_panel != null:
		controls_panel.queue_free()
		controls_panel = null


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if controls_panel != null:
		_close_controls()
	elif options_panel != null and options_panel.visible:
		options_panel.visible = false
		(find_child("OptionsButton", true, false) as Button).text = "Opciones ▸"
		(find_child("OptionsButton", true, false) as Button).grab_focus()
	get_viewport().set_input_as_handled()


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BeeGameSettings.TITLE_PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(BeeGameSettings.TITLE_PANEL_RADIUS)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _play() -> void:
	BeeGameSettings.from_title = true
	BeeGameSettings.intro_return_to_title = false
	preload("res://scripts/game/bee_scene_fade.gd").go(self,INTRO_SCENE)


func _show_intro() -> void:
	BeeGameSettings.intro_return_to_title = true
	preload("res://scripts/game/bee_scene_fade.gd").go(self,INTRO_SCENE)


func _play_lake() -> void:
	BeeGameSettings.from_title = true
	preload("res://scripts/game/bee_scene_fade.gd").go(self,LAKE_SCENE)
