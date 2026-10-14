extends SceneTree
const SETTINGS := preload("res://scripts/game/bee_readability_settings.gd")
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func run() -> void:
	check(not SETTINGS.development_for(false, true, true) and not SETTINGS.development_for(false, true, false), "Both exported debug and release reject comparators")
	check(SETTINGS.development_for(true, false, true), "Editor debug accepts development comparators")
	check(SETTINGS.BACKGROUND_SATURATION.size() == 2 and SETTINGS.BEE_SCALES[SETTINGS.DEFAULT_BEE] == 1.4, "Fixed Bee size and no gray background mode")
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	var live := stage.get_node("LiveReadability")
	for index in SETTINGS.KEYS.size():
		var event := InputEventKey.new()
		event.keycode = SETTINGS.KEYS[index]
		event.pressed = true
		for step in 3: live._unhandled_key_input(event)
	check(live.background_level in [0, 1] and "J neón" in live.panel.text, "New keys cycle modes and update DEV legend")
	var chord := InputEventKey.new()
	chord.keycode = SETTINGS.KEYS[0]
	chord.pressed = true
	chord.ctrl_pressed = true
	var before_chord: int = live.bee_index
	live._unhandled_key_input(chord)
	check(live.bee_index == before_chord, "Editor modifier chords are not intercepted")
	live.enabled = false
	var scale_index: int = live.bee_index
	var event := InputEventKey.new()
	event.keycode = SETTINGS.KEYS[0]
	event.pressed = true
	live._unhandled_key_input(event)
	live.set_modes(1, 2, 0, 2)
	check(live.bee_index == scale_index, "Non-development mode rejects input and comparator API")
	for kind in [0, 1]:
		var item := preload("res://scenes/bee_prototype/bee_powerup_pickup.tscn").instantiate() as BeePowerupPickup
		item.kind = kind
		var shape: Shape3D = item.get_node("CollisionShape3D").shape
		stage.add_child(item)
		await process_frame
		check(item.has_node("PickupMedallion"), "Dynamically spawned old capsule automatically receives medallion")
		check(item.get_node("CollisionShape3D").shape == shape and is_equal_approx(shape.radius, 0.55), "Pickup collision resource/radius unchanged")
		check(not item.get_node("Label").visible and not item.get_node("ItemBeacon").visible, "Prototype letters and stacked old beacon hidden")
		check(item.get_node("PickupMedallion").get_script() == preload("res://scripts/items/toon_pickup_hover.gd"), "Same float animation as modern pickups")
		check(item.has_node("PickupMedallion/BombGlyph") if kind == 1 else item.has_node("PickupMedallion/SpreadGlyph0"), "Clear type glyph")
		stage.bee.spread_ammo = 0
		stage.bee.bomb_charges = 1
		check(item.collect(stage.bee), "Collection contract preserved")
		check(stage.bee.bomb_charges == 4 if kind == 1 else is_equal_approx(stage.bee.spread_ammo, 20.0), "Original +3 bombs / 20-second Spread amounts preserved")
	print("T3G_OK dev/export gate, new keys/defaults, fixed background count, dynamic medallions, pickup amounts and shape invariant")
	quit()
