extends SceneTree
## DEV ONLY (lote 7). Captures (needs a rendering window, writes dev/visual_target/lote7_*.png):
##   zone{1,2,3}_*   each combat zone a few seconds after it opens and in its second wave
##   checkpoint2     the second checkpoint beacon (X=266)
##   fireflies       fireflies at dusk, facing their drift
## godot --path . --resolution 1152x648 --script res://dev/visual_target/capture_lote7.gd
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/visual_target/lote7_"

var stage: BeeShmupStage
var wave: BeeLevel01Controller

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + label + ".png"))
	print("saved ", label)

func _initialize() -> void:
	call_deferred("run")

func jump(distance: float) -> void:
	stage.distance = distance
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 3.4, 0)
	wave.resume_after_checkpoint(distance)

func run() -> void:
	root.size = Vector2i(1152, 648)
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	wave = stage.wave as BeeLevel01Controller
	stage.bee.health.damage_blocked = true
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").controls_hint.hide()
	var index := 0
	for x in [112.0, 172.0, 233.0]:
		index += 1
		jump(x - 0.5)
		await frames(240)
		await shot("zone%d_open" % index)
		await frames(540)
		await shot("zone%d_wave2" % index)
		for unit in wave.active_units + wave.swarm_units:
			unit.queue_free()
		wave.active_units.clear()
		wave.swarm_units.clear()
		wave._pending.clear()
		wave._arena = {}
	stage.distance = 282.5
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	await frames(10)
	await shot("checkpoint2")
	stage.distance = 225.0
	stage._update_camera_and_bounds()
	await frames(90)
	await shot("fireflies")
	quit(0)
