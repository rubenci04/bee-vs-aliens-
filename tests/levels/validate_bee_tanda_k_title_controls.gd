extends SceneTree
const GUIDE := preload("res://scripts/game/bee_controls_guide.gd")
var failures := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var title := (load("res://scenes/game/bee_title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	BeeGameSettings.last_input_joypad = false
	title._show_controls()
	var help := title.controls_panel.get_child(0).get_child(0) as Label
	check(help.text.contains(GUIDE.device_icon(false)) and help.text.contains("WASD") and help.text.contains("poca vida"), "Title Controls explains keyboard actions and when to use them")
	check(help.get_theme_font_size("font_size") >= BeeGameSettings.TITLE_CONTROLS_FONT_SIZE, "Title Controls uses larger text")
	BeeGameSettings.last_input_joypad = true
	title._show_controls()
	help = title.controls_panel.get_child(0).get_child(0) as Label
	check(help.text.contains(GUIDE.device_icon(true)) and help.text.contains("STICK") and help.text.contains("LT"), "Title Controls follows InputDevices gamepad state")
	BeeGameSettings.last_input_joypad = false
	print("TANDA_K_TITLE_CONTROLS failures=", failures)
	quit(1 if failures else 0)
