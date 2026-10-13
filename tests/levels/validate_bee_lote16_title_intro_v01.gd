extends SceneTree

const TITLE := preload("res://scenes/game/bee_title_screen.tscn")
const INTRO := preload("res://scenes/game/bee_intro_screen.tscn")

var failures := 0


func _initialize() -> void:
	create_timer(30.0, true, false, true).timeout.connect(func(): quit(1))
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func run() -> void:
	var title := TITLE.instantiate() as Control
	root.add_child(title)
	current_scene = title
	await process_frame
	check(title.find_child("TitleBackground", true, false) is TextureRect, "Title scene builds a background with artwork")
	check(title.find_child("Logo", true, false) is TextureRect, "Title logo node exists")
	check(title.find_child("MenuPanel", true, false) is PanelContainer, "Title menu uses a readable rounded panel")
	check(title.find_child("TitleMenu", true, false).get_child_count() >= 5, "Title contains the main menu")
	var options_button := title.find_child("OptionsButton", true, false) as Button
	options_button.pressed.emit()
	var options := title.get("options_panel") as VBoxContainer
	check(options.visible and options.get_child_count() >= 5, "Options expands volumes and presentation controls")
	var controls_button: Button
	var replay_button: Button
	for button: Button in options.find_children("*", "Button", true, false):
		if button.text == "Controles":
			controls_button = button
		elif button.text == "Ver introducción":
			replay_button = button
	check(options.find_child("ShakeButton", true, false) is Button and controls_button != null and replay_button != null, "Options includes shake, controls and replay intro")
	if controls_button == null:
		quit(1)
		return
	controls_button.pressed.emit()
	check(title.get("controls_panel") is PanelContainer, "Controls help opens from Options")
	var back := InputEventAction.new()
	back.action = "ui_cancel"
	back.pressed = true
	title.call("_unhandled_input", back)
	check(title.get("controls_panel") == null, "B / cancel closes the controls overlay")
	title.call("_unhandled_input", back)
	check(not options.visible, "B / cancel closes Options")
	var fallback: Control = title.call("_make_gradient_fallback")
	check(fallback is TextureRect and (fallback as TextureRect).texture is GradientTexture2D, "Title can build its gradient fallback when artwork is absent")
	title.queue_free()
	await process_frame

	var intro := INTRO.instantiate() as Control
	root.add_child(intro)
	current_scene = intro
	await process_frame
	var background := intro.get("background") as TextureRect
	check(background.texture != null, "Intro screen loads a slide texture")
	intro.call("_set_slide", 0, "res://assets/ui/intro/missing_test_image.png")
	check(background.texture is GradientTexture2D, "Intro displays a dark gradient when a slide image is missing")
	intro.call("_set_slide", 0)
	check((intro.get("caption") as Label).text.begins_with("2026."), "Intro text is read from intro_texts.json")
	intro.elapsed = 0.59
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	intro.call("_unhandled_input", click)
	check(int(intro.get("current_slide")) == 0, "Intro skip stays locked for the first 0.6 seconds")
	intro.elapsed = 0.61
	intro.call("_unhandled_input", click)
	await wait(BeeGameSettings.INTRO_FADE_SECONDS + 0.1)
	check(int(intro.get("current_slide")) == 1, "A mouse click advances the intro after the skip lock")
	for slide in range(1, 5):
		intro.call("_advance_slide")
		await wait(BeeGameSettings.INTRO_FADE_SECONDS + 0.1)
	check(int(intro.get("current_slide")) == 4 and bool(intro.get("_final_logo")), "After all five slides, the ending logo appears")
	check(intro.destination_scene_path() == BeeGameSettings.LEVEL_01, "Playing from the title targets Level 01 after the intro")
	intro.call("_finish_intro")
	for frame in 8:
		await process_frame
	check(current_scene != null and current_scene.scene_file_path == BeeGameSettings.LEVEL_01, "Level 01 starts after the intro completes")
	if failures == 0:
		print("BEE_LOTE16_TITLE_INTRO_OK slides=5 skip_lock=0.6s missing_art=gradient level_after_intro=true")
		quit(0)
	else:
		quit(1)
