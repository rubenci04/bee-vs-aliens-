extends SceneTree
## DEV ONLY. Camera D vs Camera E on the same staged situations (render required; writes PNGs here).
##   godot --path . --resolution 1152x648 --script res://dev/threat_camera_boss_v03_review/camera_compare.gd -- presets=D,E
## Output: cam_<preset>_<shot>.png. Nothing in the game changes (the preset switch is a runtime static).

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/threat_camera_boss_v03_review/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var presets: PackedStringArray = ["D", "E"]
var shots: PackedStringArray = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("presets="):
			presets = arg.substr(8).split(",")
		elif arg.begins_with("shots="):
			shots = arg.substr(6).split(",")
	call_deferred("run")

func want(name: String) -> bool:
	return shots.is_empty() or name in shots

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + file + ".png")
	print("SHOT ", file)

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

func spawn(family: String, slot := 0, y := -99.0) -> Node3D:
	var request := {"family": family, "slot": slot, "event": 0, "hard": false}
	if y > -50.0:
		request["y"] = y
	wave._spawn(request)
	return wave.active_units.back()

func live(seconds: float) -> void:
	for i in int(seconds * 60.0):
		bee.global_position.y = 3.6 + sin(float(i) / 60.0 * 2.0) * 1.0
		await physics_frame

func run() -> void:
	root.size = Vector2i(1152, 648)
	for preset in presets:
		BeeLevel01Framing.use_preset(StringName(preset))
		var p := "cam_%s_" % preset
		if want("combat"):
			await fresh()
			await at(46.0)
			spawn("Wasp", 0, 5.4)
			spawn("Probe", 1, 3.6)
			await live(2.4)
			await shot(p + "1_combat")
		if want("walker"):
			await fresh()
			await at(105.0, 4.6)
			spawn("Walker", 0)
			await live(3.0)
			await shot(p + "2_walker")
		if want("three"):
			await fresh()
			await at(172.0)
			spawn("EyeDrone", 0, 6.0)
			spawn("Turret", 1)
			spawn("Probe", 2, 3.0)
			await live(2.6)
			await shot(p + "3_three_threats")
		if want("organic"):
			await fresh()
			await at(214.0)
			spawn("OrganicAlien", 0, 3.6)
			spawn("Probe", 1, 5.8)
			spawn("EyeDrone", 2, 2.2)
			await live(3.0)
			await shot(p + "4_organic")
		if want("boss"):
			await fresh()
			await at(340.0)
			wave.event_index = BeeLevel01Controller.EVENTS.size()
			wave.set_physics_process(true)
			for i in 900:
				await physics_frame
				bee.global_position.y = 3.6 + sin(float(i) / 60.0 * 2.0) * 1.0
				if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1 and wave.boss._state_time > 2.5:
					break
			await shot(p + "5_boss")
	BeeLevel01Framing.use_preset(BeeLevel01Framing.DEFAULT_PRESET)
	quit(0)
