extends SceneTree
const NOTICES := preload("res://scripts/ui/bee_hud_notices.gd")
const S := preload("res://scripts/game/bee_hud_text_settings.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		push_error(text)
func run() -> void:
	root.size = Vector2i(1154, 648)
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 3: await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	var n := NOTICES.for_host(stage)
	n.set_process(false)
	n.pending.clear()
	n.left = 0
	n.active_kind = ""
	var devices := root.get_node("InputDevices")
	BeeGameSettings.last_input_joypad = false
	var pad := InputEventJoypadButton.new()
	pad.device = 0
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	devices._input(pad)
	check(n.active_kind == "device" and is_equal_approx(n.left, 2), "Device switch shows a 2s banner")
	devices._input(pad)
	check(n.pending.is_empty(), "Repeated same-device inputs do not produce notices")
	n._process(1.8)
	check(n.panel.modulate.a > 0 and n.panel.modulate.a < 1, "Device banner fades")
	n._process(.3)
	check(not n.panel.visible, "Device banner disappears")
	var cp := stage.get_node("CheckpointQoL")
	cp.activate_second_checkpoint()
	check(n.label.text == "CHECKPOINT 2" and is_equal_approx(n.left, 1.5), "Checkpoint uses the 1.5s banner")
	check(cp.beacon.get_node_or_null("CheckpointLabel") == null and cp.beacon_2.get_node_or_null("CheckpointLabel") == null, "No world-space checkpoint titles")
	n._process(1.6)
	for i in 8: BeeLiberation.float_text(stage, Vector3(i, 4, 0))
	check(n.label.text == "+8 LIBERADOS" and n.liberated_count == 8, "Counter includes every liberation")
	var signs := get_nodes_in_group("bee_liberated_text")
	check(signs.size() == 2, "Only two individual signs")
	for sign in signs:
		check(sign.font_size == S.INDIVIDUAL_FONT and is_equal_approx(sign.modulate.a, .6), "Individual signs are small and 60 percent opaque")
	n._process(.61)
	check(n.liberated_count == 0, "Fixed 0.6s window resets without extending")
	n.note_liberated()
	check(n.liberated_count == 1, "A new window starts at one")
	n.pending.clear()
	n.left = 0
	n.active_kind = ""
	stage.wave.species_seen.clear()
	stage.wave._announce_species("Ant")
	stage.wave._announce_species("Ant")
	check(n.label.text == "HORMIGA" and n.pending.is_empty(), "Species appears only once")
	var hud := stage.get_node("CanvasLayer/WeaponsHUD")
	hud.taught.clear()
	hud.show_hint(&"roll")
	hud.show_hint(&"roll")
	check(n.pending.size() == 1 and not hud.get_node("Hint").visible, "One contextual tip, no raw HUD control text")
	await process_frame
	var bounds: Rect2 = n.panel.get_global_rect()
	var hud_rect := Rect2(BeeGameSettings.HUD_PANEL_POSITION, BeeGameSettings.HUD_PANEL_SIZE)
	check(not bounds.intersects(hud_rect) and bounds.end.y <= 46, "Banner is above boss labels and clear of health HUD")
	var boss := preload("res://scenes/levels/tarantula_boss_01.tscn").instantiate() as TarantulaBoss01
	stage.add_child(boss)
	boss.begin(stage.camera, stage.bee)
	boss._boss_hint("PATAS BLINDADAS: APUNTÁ AL IMPLANTE")
	check(boss._hint_label.get_theme_font_size("font_size") >= 32 and boss._hint_label.offset_top >= 120, "Boss hint is doubled below its bar")
	print("T1B_HUD failures=", failures)
	quit(1 if failures else 0)
