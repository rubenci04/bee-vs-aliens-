extends Control
## Five-slide story interlude. `intro_texts.json` owns the editable text and duration.

var current_slide := 0
var slide_duration := BeeGameSettings.INTRO_SLIDE_SECONDS
var elapsed := 0.0
var _transitioning := false
var _final_logo := false
var _texts: Array[String] = []
var background: TextureRect
var caption: Label
var lower_gradient: TextureRect
var fade: ColorRect
var skip_hint: Label
var final_logo: TextureRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_story()
	_build_ui()
	_set_slide(0)
	BeeMusic.set_intro_duck(true)


func _exit_tree() -> void:
	BeeMusic.set_intro_duck(false)


func _load_story() -> void:
	var file := FileAccess.open(BeeGameSettings.INTRO_TEXTS_PATH, FileAccess.READ)
	if file == null:
		_texts = ["2026. La humanidad cree estar sola. No lo está: alguien la vigila."]
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_texts = ["2026. La humanidad cree estar sola. No lo está: alguien la vigila."]
		return
	slide_duration = maxf(0.7, float(parsed.get("duration_seconds", BeeGameSettings.INTRO_SLIDE_SECONDS)))
	for line: Variant in parsed.get("slides", []):
		_texts.append(str(line))
	if _texts.is_empty():
		_texts = ["2026. La humanidad cree estar sola. No lo está: alguien la vigila."]


func _build_ui() -> void:
	background = TextureRect.new()
	background.name = "IntroBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	lower_gradient = TextureRect.new()
	lower_gradient.name = "IntroTextGradient"
	lower_gradient.anchor_top = 1.0 - BeeGameSettings.INTRO_TEXT_BAND_HEIGHT_FRACTION
	lower_gradient.anchor_bottom = 1.0
	lower_gradient.anchor_right = 1.0
	lower_gradient.offset_top = 0.0
	lower_gradient.offset_bottom = 0.0
	lower_gradient.texture = _make_bottom_gradient()
	lower_gradient.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lower_gradient.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(lower_gradient)

	caption = Label.new()
	caption.name = "IntroCaption"
	caption.anchor_left = BeeGameSettings.INTRO_TEXT_MARGIN_X
	caption.anchor_right = 1.0 - BeeGameSettings.INTRO_TEXT_MARGIN_X
	caption.anchor_top = 1.0 - BeeGameSettings.INTRO_TEXT_BAND_HEIGHT_FRACTION + BeeGameSettings.INTRO_TEXT_TOP_INSET
	caption.anchor_bottom = 0.94
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", BeeGameSettings.INTRO_TEXT_FONT_SIZE)
	caption.add_theme_color_override("font_color", Color("fff8e8"))
	caption.add_theme_constant_override("outline_size", BeeGameSettings.INTRO_TEXT_OUTLINE_SIZE)
	caption.add_theme_color_override("font_outline_color", Color("10121b"))
	add_child(caption)

	skip_hint = Label.new()
	skip_hint.name = "IntroSkipHint"
	skip_hint.text = "Enter / A: saltar"
	skip_hint.anchor_left = 1.0
	skip_hint.anchor_right = 1.0
	skip_hint.anchor_top = 1.0
	skip_hint.anchor_bottom = 1.0
	skip_hint.offset_left = -BeeGameSettings.INTRO_SKIP_RIGHT_MARGIN - BeeGameSettings.INTRO_SKIP_WIDTH
	skip_hint.offset_right = -BeeGameSettings.INTRO_SKIP_RIGHT_MARGIN
	skip_hint.offset_top = -BeeGameSettings.INTRO_SKIP_BOTTOM_MARGIN - BeeGameSettings.INTRO_SKIP_HEIGHT
	skip_hint.offset_bottom = -BeeGameSettings.INTRO_SKIP_BOTTOM_MARGIN
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip_hint.add_theme_font_size_override("font_size", BeeGameSettings.INTRO_SKIP_FONT_SIZE)
	skip_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))
	skip_hint.add_theme_constant_override("outline_size", 3)
	skip_hint.add_theme_color_override("font_outline_color", Color("10121b"))
	add_child(skip_hint)

	final_logo = TextureRect.new()
	final_logo.name = "IntroEndLogo"
	final_logo.texture = load(BeeGameSettings.TITLE_LOGO_PATH) as Texture2D if ResourceLoader.exists(BeeGameSettings.TITLE_LOGO_PATH) else null
	final_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	final_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	final_logo.anchor_left = 0.5
	final_logo.anchor_right = 0.5
	final_logo.anchor_top = 0.5
	final_logo.anchor_bottom = 0.5
	final_logo.offset_left = -BeeGameSettings.INTRO_END_LOGO_WIDTH * 0.5
	final_logo.offset_right = BeeGameSettings.INTRO_END_LOGO_WIDTH * 0.5
	final_logo.offset_top = -BeeGameSettings.INTRO_END_LOGO_HEIGHT * 0.5
	final_logo.offset_bottom = BeeGameSettings.INTRO_END_LOGO_HEIGHT * 0.5
	final_logo.modulate.a = 0.0
	add_child(final_logo)

	fade = ColorRect.new()
	fade.name = "IntroFade"
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 0.0
	add_child(fade)


func _make_bottom_gradient() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.01, 0.015, 0.03, 0.0), BeeGameSettings.INTRO_GRADIENT_COLOR])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	return texture


func _make_fallback() -> Texture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([BeeGameSettings.INTRO_FALLBACK_TOP, BeeGameSettings.INTRO_FALLBACK_BOTTOM])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	return texture


func _process(delta: float) -> void:
	if _transitioning or _final_logo:
		return
	elapsed += delta
	if caption != null:
		caption.visible_characters = mini(caption.get_total_character_count(), floori(maxf(0.0, elapsed - BeeGameSettings.INTRO_TYPEWRITER_DELAY) * BeeGameSettings.INTRO_TYPEWRITER_CHARS_PER_SECOND))
	if elapsed >= slide_duration:
		_advance_slide()


func _unhandled_input(event: InputEvent) -> void:
	if elapsed < BeeGameSettings.INTRO_SKIP_LOCK_SECONDS or _transitioning or _final_logo:
		return
	var skip := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		skip = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if skip:
		get_viewport().set_input_as_handled()
		_advance_slide()


func _set_slide(index: int, image_override: String = "") -> void:
	current_slide = index
	if image_override.is_empty() and (index < 0 or index >= BeeGameSettings.INTRO_IMAGES.size()):
		background.texture = _make_fallback()
	else:
		var path := image_override if not image_override.is_empty() else str(BeeGameSettings.INTRO_IMAGES[index])
		background.texture = load(path) as Texture2D if ResourceLoader.exists(path) else _make_fallback()
	background.scale = Vector2.ONE * BeeGameSettings.INTRO_IMAGE_ZOOM_START
	background.pivot_offset = get_viewport_rect().size * 0.5
	var zoom := create_tween()
	zoom.tween_property(background, "scale", Vector2.ONE * BeeGameSettings.INTRO_IMAGE_ZOOM_END, slide_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	caption.text = _texts[clampi(index, 0, _texts.size() - 1)] if not _texts.is_empty() else ""
	caption.visible_characters = 0


func _advance_slide() -> void:
	if _transitioning or _final_logo:
		return
	if current_slide + 1 >= mini(_texts.size(), BeeGameSettings.INTRO_IMAGES.size()):
		_show_final_logo()
		return
	_transitioning = true
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, BeeGameSettings.INTRO_FADE_SECONDS * 0.5)
	tween.tween_callback(func():
		elapsed = 0.0
		_set_slide(current_slide + 1))
	tween.tween_property(fade, "modulate:a", 0.0, BeeGameSettings.INTRO_FADE_SECONDS * 0.5)
	tween.tween_callback(func(): _transitioning = false)


func _show_final_logo() -> void:
	if _transitioning or _final_logo:
		return
	_transitioning = true
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, BeeGameSettings.INTRO_FADE_SECONDS * 0.5)
	tween.tween_callback(func():
		_final_logo = true
		caption.hide()
		lower_gradient.hide()
		skip_hint.hide()
		background.texture = _make_fallback()
		final_logo.modulate.a = 0.0)
	tween.tween_property(fade, "modulate:a", 0.0, BeeGameSettings.INTRO_FADE_SECONDS * 0.5)
	tween.parallel().tween_property(final_logo, "modulate:a", 1.0, BeeGameSettings.INTRO_FADE_SECONDS)
	tween.tween_interval(BeeGameSettings.INTRO_LOGO_HOLD_SECONDS)
	tween.tween_property(fade, "modulate:a", 1.0, BeeGameSettings.INTRO_FADE_SECONDS)
	tween.tween_callback(_finish_intro)


func _finish_intro() -> void:
	BeeMusic.set_intro_duck(false)
	if BeeGameSettings.intro_return_to_title:
		BeeGameSettings.intro_return_to_title = false
		BeeGameSettings.from_title = false
		get_tree().change_scene_to_file(BeeGameSettings.TITLE_SCENE)
	else:
		get_tree().change_scene_to_file(BeeGameSettings.LEVEL_01)


func destination_scene_path() -> String:
	return BeeGameSettings.TITLE_SCENE if BeeGameSettings.intro_return_to_title else BeeGameSettings.LEVEL_01
