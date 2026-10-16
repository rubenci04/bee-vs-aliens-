extends SceneTree
var stage: BeeShmupStage
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/tanda_b_%s.png"%label)
func run() -> void:
	root.size = Vector2i(1154,648)
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.get_node("Juice").set_process(false)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.distance = 138
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(134,3,0)
	for i in 3: stage.wave._spawn({"family":"FlyCommon","event":0,"slot":i,"hard":false,"y":2.4+1.2*i})
	stage.wave._begin_arena({"units":["FlyCommon"],"arena":[]},0)
	await frames(20)
	await capture("marca")
	await frames(20)
	await capture("dither")
	await frames(40)
	await capture("llegada")
	for unit in stage.wave.active_units.duplicate(): unit.health.take_damage(9999)
	stage.wave._update_arena(0)
	await frames(3)
	await capture("despejada")
	quit()
