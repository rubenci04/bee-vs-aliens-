extends "res://tests/levels/bee_t7b_fixture.gd"
const NOTICES := preload("res://scripts/ui/bee_hud_notices.gd")
const GROUNDED := preload("res://scripts/levels/bee_grounded_prop.gd")
func run() -> void:
	var stage := await fixture()
	var wave := stage.wave as BeeLevel01Controller
	var banners := NOTICES.for_host(stage)
	banners.set_process(false)
	banners.pending.clear()
	banners.left = 0
	var devices := root.get_node("InputDevices")
	devices.set_process(false)
	devices.device_notice_cooldown = 0
	BeeGameSettings.last_input_joypad = false
	var pad := InputEventJoypadButton.new()
	pad.device = 0
	pad.pressed = true
	devices._input(pad)
	check(banners.active_kind == "device" and banners.panel.visible, "Real device switch shows a notice in a quiet zone")
	var jitter := InputEventMouseMotion.new()
	jitter.relative = Vector2(1, 1)
	devices._input(jitter)
	check(BeeGameSettings.last_input_joypad, "Tiny mouse movement does not switch input device")
	var key := InputEventKey.new()
	key.keycode = KEY_X
	key.pressed = true
	banners._process(3.0)
	devices._process(14.9)
	while Time.get_ticks_msec() < 3500: await process_frame # Tanda P: the keyboard must be in use 3 s in a row to switch
	devices._keyboard_since_msec = Time.get_ticks_msec() - 3200
	devices._keyboard_last_msec = Time.get_ticks_msec()
	devices._input(key)
	check(not BeeGameSettings.last_input_joypad and not banners.panel.visible and banners.pending.is_empty(), "Device state updates immediately but banner is suppressed before fifteen seconds")
	devices._process(0.1)
	devices._input(pad)
	check(banners.panel.visible and banners.active_kind == "device", "Fifteen seconds permits the next real change")
	wave._arena = {"label":"test"}
	banners._process(0.01)
	check(not banners.panel.visible, "Combat entering cancels an already visible device notice")
	devices._process(15.0)
	while Time.get_ticks_msec() < 3500: await process_frame # Tanda P: the keyboard must be in use 3 s in a row to switch
	devices._keyboard_since_msec = Time.get_ticks_msec() - 3200
	devices._keyboard_last_msec = Time.get_ticks_msec()
	devices._input(key)
	check(banners.pending.is_empty() and not banners.panel.visible, "Combat switch is discarded, never deferred")
	wave._arena.clear()
	var robot_actor := robot(stage)
	devices._input(pad)
	check(not banners.panel.visible, "Robot blocks device notices even outside a director arena")
	robot_actor.health.current_health = 0
	var tarantula := spider(stage)
	while Time.get_ticks_msec() < 3500: await process_frame # Tanda P: the keyboard must be in use 3 s in a row to switch
	devices._keyboard_since_msec = Time.get_ticks_msec() - 3200
	devices._keyboard_last_msec = Time.get_ticks_msec()
	devices._input(key)
	check(not banners.panel.visible, "Tarantula blocks device notices")
	var banana_count := 0
	for prop: Node3D in stage.find_children("*", "Node3D", true, false):
		if prop.scene_file_path != "res://scenes/art_labs/ground_litter_v02/banana_peel.tscn": continue
		banana_count += 1
		var bottom := INF
		for mesh: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
			for vertex in mesh.mesh.get_faces():
				bottom = minf(bottom, (mesh.global_transform * vertex).y)
		check(absf(bottom - GROUNDED.GROUND_Y) < 0.001 and is_equal_approx(prop.rotation.z, GROUNDED.TILT), "Every banana actually rests on the ground with a small tilt")
	check(banana_count == 3, "Audit covers decorative banana X63 and obstacles X120/X242")
	check(stage.find_children("CheckpointRing", "", true, false).is_empty(), "No old checkpoint torus remains")
	var target := stage.find_child("VisualTarget", true, false) as BeeLevel01VisualTarget
	if target == null:
		for node in stage.get_children():
			if node is BeeLevel01VisualTarget: target = node
	check(target != null, "Background visual target exists")
	if target != null:
		for color in ["petal_pink", "petal_warm", "petal_violet"]:
			var material := target._material(color, false)
			check(material.shader == BeeToonStyle.TOON and material.next_pass == BeeToonStyle.shared_outline(BeeToonStyle.OUTLINE_PROP), "Tall flower petals use the standard toon and prop outline: " + color)
	print("TANDA_A_CLEANUP failures=", failures)
	done()
