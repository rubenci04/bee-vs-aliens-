extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 3:
		await process_frame
	var hud := stage.get_node("CanvasLayer/WeaponsHUD") as Control
	var checkpoint := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	BeeGameSettings.last_input_joypad = false
	hud.call("_show_death_message")
	var death_panel := hud.get_node("DeathMessage") as Panel
	var death_label := death_panel.get_child(0) as Label
	check(death_panel.visible and death_label.text == "PULSÁ R PARA REINICIAR", "Keyboard death message is Spanish and centered")
	checkpoint.checkpoint_active = true
	BeeGameSettings.last_input_joypad = true
	hud.call("_show_death_message")
	check(death_label.text == "PULSÁ Y PARA REAPARECER", "Controller death message names its restart button")
	check(is_equal_approx(death_panel.size.x, BeeGameSettings.HUD_TERMINAL_PANEL_SIZE.x), "Death panel has configured centered size")
	stage.set_physics_process(false)
	var section := stage.get_node("CanvasLayer/Section") as Label
	section.text = "LEVEL 01 COMPLETADO"
	stage.call("_layout_victory_title")
	stage.call("_show_clear_banner")
	await process_frame
	var banner := stage.get_node("CanvasLayer/ClearBanner") as Label
	check(section.text.contains("LEVEL 01 COMPLETADO") and banner.text.begins_with("SECTOR DESPEJADO"), "Victory keeps the two messages distinct")
	check(section.get_global_rect().end.y < banner.get_global_rect().position.y, "Victory title and sector card do not overlap")
	print("LOTE17 TERMINAL UI failures=", failures)
	quit(1 if failures else 0)
