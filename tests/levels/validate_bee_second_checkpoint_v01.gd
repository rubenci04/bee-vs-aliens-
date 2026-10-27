extends SceneTree

# LOTE 7 — SECOND CHECKPOINT (X = second_checkpoint_x). Reaching it saves the run (HP back to >= 60 %), shows "CHECKPOINT 2";
# a defeat after it respawns there (not at X=190) with every earlier event consumed and the Giant Human already gone.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

var stage: BeeShmupStage

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_children().filter(func(n): return n.name != "SceneFade").back() # Tanda E: the scene-fade cover is added after the level
	await frames(5)
	stage = current_scene as BeeShmupStage
	var qol := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	var wave := stage.wave as BeeLevel01Controller
	check(qol.checkpoint_list() == [190.0, qol.second_checkpoint_x], "Two checkpoints expected")
	check(qol.second_checkpoint_x > 266.0 and qol.second_checkpoint_x < 296.0, "Second checkpoint between the contaminated flower and the 296 gate")
	check(stage.get_node_or_null("CheckpointBeacon2") != null, "Second beacon missing")
	wave.set_physics_process(false)
	stage.scroll_speed = 0.0
	stage.distance = 191.0
	await frames(3)
	for i in 5:
		await process_frame
	check(qol.checkpoint_active and not qol.second_checkpoint_active, "First checkpoint first")
	stage.distance = qol.second_checkpoint_x + 0.5
	stage.bee.health.current_health = 20
	await frames(3)
	for i in 5:
		await process_frame # The QoL node works in _process.
	check(qol.second_checkpoint_active and float(qol.snapshot["distance"]) == qol.second_checkpoint_x, "Second checkpoint must save the run there")
	check(stage.bee.health.current_health >= 60, "Second checkpoint heals to 60 %")
	check(qol.notice.text == "CHECKPOINT 2", "Notice must say CHECKPOINT 2")
	stage.bee.health.take_damage(9999)
	await frames(2)
	var old := stage
	qol.restart_level(false)
	for i in 120:
		await process_frame
		if current_scene != null and current_scene != old and current_scene.is_node_ready():
			break
	await frames(3)
	stage = current_scene as BeeShmupStage
	var qol2 := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	var wave2 := stage.wave as BeeLevel01Controller
	check(absf(stage.distance - qol2.second_checkpoint_x) < 0.5, "Respawn must be at the second checkpoint (%.1f)" % stage.distance)
	check(qol2.checkpoint_active and qol2.second_checkpoint_active, "Both checkpoints stay taken after the respawn")
	for i in wave2.event_index:
		check(float(BeeLevel01Controller.EVENTS[i]["at"]) < qol2.second_checkpoint_x, "Only earlier events are consumed")
	check(wave2.event_index < BeeLevel01Controller.EVENTS.size() and float(BeeLevel01Controller.EVENTS[wave2.event_index]["at"]) >= qol2.second_checkpoint_x, "Next event is after the checkpoint")
	check(wave2.human.crossings_exited == 1, "The Giant Human is already behind")
	print("SECOND_CHECKPOINT x=%.0f save=OK heal=OK respawn=OK next_event=%s" % [qol2.second_checkpoint_x, BeeLevel01Controller.EVENTS[wave2.event_index]["label"]])
	print("BEE_SECOND_CHECKPOINT_V01_OK")
	quit(0)
