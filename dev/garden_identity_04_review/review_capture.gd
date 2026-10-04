extends SceneTree
## DEV ONLY (GARDEN IDENTITY & AUDIO PASS 04). Review captures of Level 01 (render required, writes PNGs here).
##   godot --path . --resolution 1152x648 --script res://dev/garden_identity_04_review/review_capture.gd -- prefix=after shots=all
## prefix=before is run on the baseline (before this pass) for the BEFORE/AFTER pairs: early, human, postcheckpoint.
## Spider shots only exist after this pass (the family is looked up by name, so the script also runs on the baseline).

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/garden_identity_04_review/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var wanted: PackedStringArray = []
var prefix := "after"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			wanted = arg.substr(6).split(",")
		elif arg.begins_with("prefix="):
			prefix = arg.substr(7)
	call_deferred("run")


func want(name: String) -> bool:
	return wanted.is_empty() or "all" in wanted or name in wanted


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + prefix + "_" + file + ".png")
	print("SHOT ", prefix, "_", file)


func fresh() -> void:
	if stage != null:
		stage.queue_free()
		await frames(2)
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	wave.set_physics_process(false)


func at(distance: float, y := 3.6) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x + BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.view_aspect(root)), y, 0)
	bee.facing_x = 1.0
	await frames(3)


func spawn(family: String, slot := 0, y := -99.0, extra := {}) -> Node3D:
	var request := {"family": family, "slot": slot, "event": 0, "hard": false}
	if y > -50.0:
		request["y"] = y
	request.merge(extra, true)
	wave._spawn(request)
	return wave.swarm_units.back() if family == "Swarm" else wave.active_units.back()


func live_until(seconds: float, until: Callable = Callable(), bob := true) -> void:
	for i in int(seconds * 60.0):
		if bob:
			bee.global_position.y = 3.6 + sin(float(i) / 60.0 * 2.0) * 1.0
		await physics_frame
		if until.is_valid() and until.call():
			return


func run() -> void:
	root.size = Vector2i(1152, 648)
	if want("opening"):
		await fresh()
		await at(4.0)
		await frames(30)
		await shot("01_opening")
	if want("early"):
		await fresh()
		await at(26.0, 3.2)
		await frames(20)
		await shot("02_early_garden")
	if want("domestic"):
		await fresh()
		await at(127.0, 3.6)
		await frames(40)
		await shot("03_giant_domestic_prop")
	if want("plants"):
		await fresh()
		await at(103.0, 3.6)
		await frames(20)
		await shot("04_plant_composition")
	if want("human"):
		await fresh()
		await at(140.0, 2.4)
		wave.set_physics_process(true)
		wave.event_index = 0
		while wave.event_index < BeeLevel01Controller.EVENTS.size() and not bool(BeeLevel01Controller.EVENTS[wave.event_index].get("human", false)):
			wave.event_index += 1
		await live_until(14.0, func(): return stage.get_node("GiantHuman").current_phase == GiantHumanCrossingHazard.Phase.CROSSING and stage.get_node("GiantHuman").animation_player.current_animation_position > 0.25, false)
		await live_until(1.6, Callable(), false)
		await shot("05_giant_human")
	if want("spider") and ResourceLoader.exists("res://scenes/levels/controlled_spider.tscn"):
		await fresh()
		await at(90.0, 3.4)
		var spider := spawn("Spider", 0, -99.0, {"x": 1.5})
		await live_until(3.0, func(): return int(spider.get("current_state")) == 2) # HANG
		await frames(10)
		await shot("06_spider_intro")
		await live_until(4.0, func(): return int(spider.get("current_state")) == 3 and float(spider.get("_state_left")) < 0.45) # TELEGRAPH, locked soon
		await shot("07a_spider_telegraph")
		await live_until(2.0, func(): return int(spider.get("current_state")) == 5) # HOLD
		await shot("07_spider_attack")
	if want("midgame"):
		await fresh()
		await at(176.0, 3.6)
		await frames(20)
		await shot("08_midgame_composition")
	if want("checkpoint"):
		await fresh()
		await at(189.0, 3.6)
		await frames(20)
		await shot("09_checkpoint_transition")
	if want("postcheckpoint"):
		await fresh()
		await at(214.0, 3.6)
		await frames(20)
		await shot("10_post_checkpoint_color")
	if want("alien"):
		await fresh()
		await at(234.0, 3.6)
		await frames(20)
		await shot("11_alien_garden")
	if want("late"):
		await fresh()
		await at(296.0)
		spawn("Walker", 0)
		spawn("EyeDrone", 1, 5.8)
		spawn("Wasp", 2, 3.0, {"sting_shots": 2, "overload_enabled": true})
		spawn("Probe", 3, 4.6)
		await live_until(4.0)
		await shot("12_late_combat")
	if want("power"):
		await fresh()
		await at(331.0, 3.8)
		wave.director_moment.emit(&"preboss_power")
		await frames(26)
		await shot("13_s_plus")
	if want("anticipation"):
		await fresh()
		await at(346.0)
		wave.director_moment.emit(&"last_silence")
		await frames(110)
		await shot("14_ufo_anticipation")
	if want("boss"):
		await fresh()
		await at(346.0)
		wave.event_index = BeeLevel01Controller.EVENTS.size()
		wave.set_physics_process(true)
		await live_until(15.0, func(): return wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1 and wave.boss._state_time > 3.0)
		await shot("15_boss")
	quit(0)
