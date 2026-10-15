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
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	check(InputMap.has_action(BeeGameSettings.HUD_DEBUG_ACTION), "F3 debug HUD action is mapped")
	check(not stage.status.visible and not stage.debug_label.visible, "Debug text starts hidden")
	check(not juice.pollen_label.visible and not juice.frenzy_label.visible and not juice.combo_label.visible, "Legacy debug counters are hidden")
	check(BeeGameSettings.HUD_HEALTH_CELLS == 10 and BeeGameSettings.HUD_BOMB_ICON_COUNT == 5, "HUD shows configured honeycomb health and up to five bombs")
	check(BeeGameSettings.HUD_PANEL_SIZE.y <= 110.0 and hud.call("control_text").contains("BOMBA C"), "HUD is compact (T1) and still names the keyboard/mouse buttons")
	BeeGameSettings.last_input_joypad = true
	check(hud.call("control_text").contains("PIRUETA B / LB") and hud.call("control_text").contains("PUÑETAZO Y / RB"), "HUD names the current joypad buttons")
	BeeGameSettings.last_input_joypad = false
	Input.action_press(BeeGameSettings.HUD_DEBUG_ACTION)
	hud._process(1.0 / 60.0)
	check(hud.debug_visible and stage.status.visible and stage.debug_label.visible, "F3 reveals the stage debug text")
	check(juice.pollen_label.visible and juice.frenzy_label.visible, "F3 reveals the technical pollen/combo lines")
	Input.action_release(BeeGameSettings.HUD_DEBUG_ACTION)
	Input.action_press(BeeGameSettings.HUD_DEBUG_ACTION)
	hud._process(1.0 / 60.0)
	check(not hud.debug_visible and not stage.status.visible and not juice.pollen_label.visible, "F3 hides the debug text again")
	Input.action_release(BeeGameSettings.HUD_DEBUG_ACTION)
	print("LOTE17 HUD failures=", failures)
	quit(1 if failures else 0)
