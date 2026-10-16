extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void: pass
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func fixture() -> BeeShmupStage:
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	BeeJuice.hit_stop_enabled = false
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("Juice").set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.distance = 294
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(291, 4, 0)
	return stage
func robot(stage: BeeShmupStage) -> WalkerMiniboss:
	stage.wave._spawn({"family":"Walker", "slot":0, "event":77, "hard":true, "miniboss":true})
	var actor := stage.wave.miniboss as WalkerMiniboss
	actor.set_physics_process(false)
	actor.global_position = Vector3(294, -0.2, 0)
	actor._step = &"rest"
	return actor
func spider(stage: BeeShmupStage) -> TarantulaBoss01:
	stage.wave._start_tarantula()
	var actor := stage.wave.tarantula as TarantulaBoss01
	actor.set_physics_process(false)
	actor.state = TarantulaBoss01.State.PHASE_2
	actor.health.damage_blocked = false
	actor.global_position = Vector3(294, 4, 0)
	return actor
func done() -> void:
	print("T7B failures=", failures)
	quit(1 if failures else 0)
