extends SceneTree

# LOTE 9 — before / after captures of Level 01 (needs a rendering window, never headless):
#   godot --path D:\proyectos\bee_alien_3d --script res://dev/visual_target/capture_lote9.gd -- before
# Saves res://dev/visual_target/lote9_<prefix>_<shot>.png: shots by day / at dusk, the 4 items on the ochre ground and at
# dusk, controlled animals at dusk (cyan implants), the moth, the UFO boss.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/visual_target/"
const ITEMS := {"pollen": "res://scenes/items/toon/pollen.tscn", "spread": "res://scenes/items/toon/spread.tscn",
		"bomb": "res://scenes/items/toon/bomb.tscn", "healing": "res://scenes/items/toon/healing.tscn"}

var prefix := "after"
var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		prefix = args[0]
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(OUT + "lote9_%s_%s.png" % [prefix, label])
	root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path)

func load_level() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await frames(3)
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(6)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.health.damage_blocked = true
	wave.set_physics_process(false)

func at(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 3.2, 3.2, 0.0)
	await frames(30) # Lights / sky follow the distance.

func spawn(family: String, y: float, x := 0.0) -> Node3D:
	wave._spawn({"family": family, "slot": wave.active_units.size(), "event": 0, "due": 0.0, "hard": true, "y": y, "x": x})
	return wave.active_units.back()

func clear() -> void:
	for unit in wave.active_units:
		if is_instance_valid(unit):
			unit.queue_free()
	wave.active_units.clear()
	for group in ["alien_projectiles", "ufo_boss_projectiles"]:
		for node in get_nodes_in_group(group):
			node.queue_free()
	await frames(2)

func shots(label: String, distance: float) -> void:
	await at(distance)
	var probe := spawn("Probe", 5.0, -3.0)
	var eye := spawn("EyeDrone", 2.4, -3.4)
	await frames(80)
	for i in 6:
		bee.set_aim_point(probe.global_position if i % 2 == 0 else eye.global_position)
		bee.fire()
		await frames(9)
	await capture(label)
	await clear()

func items(label: String, distance: float) -> void:
	await at(distance)
	var x := stage.camera.global_position.x - 2.6
	for key in ITEMS:
		var item := (load(ITEMS[key]) as PackedScene).instantiate() as Node3D
		item.name = "Capture_" + key
		stage.add_child(item)
		item.global_position = Vector3(x, 1.1, 0.0)
		x += 1.9
	await frames(40)
	await capture(label)
	for node in stage.get_children():
		if str(node.name).begins_with("Capture_"):
			node.queue_free()
	await frames(2)

func run() -> void:
	await load_level()
	await shots("shots_day", 100.0)
	await shots("shots_dusk", 300.0)
	await items("items_ground", 60.0)
	await items("items_dusk", 300.0)
	await at(296.0)
	for spec in [["Ladybird", 4.6, -2.0], ["Mosquito", 3.0, -3.6], ["Snail", -0.2, -0.6], ["Wasp", 2.0, -1.2]]:
		spawn(str(spec[0]), float(spec[1]), float(spec[2]))
	await frames(70)
	bee.clear_aim()
	bee.refresh_auto_aim()
	await capture("implants_dusk")
	await clear()
	await at(150.0)
	spawn("Moth", 4.4, -3.0)
	await frames(50)
	await capture("moth")
	await clear()
	# The UFO: straight to the fight.
	await at(340.0)
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	wave._start_boss()
	await frames(260)
	bee.set_aim_point(wave.boss.global_position)
	for i in 4:
		bee.fire()
		await frames(8)
	await capture("boss")
	print("LOTE9_CAPTURE_DONE")
	quit(0)
