extends SceneTree
## DEV ONLY. Replays the integrated test's progression harness (time_scale 3, kills each unit 2 s after it is seen)
## and prints the controller state periodically to find where the level stalls.
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	create_timer(500.0, true, false, true).timeout.connect(func(): quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4:
		await physics_frame
	var bee := stage.bee
	var wave := stage.wave as BeeLevel01Controller
	bee.hurtbox.monitorable = false
	Engine.time_scale = 3.0
	var seen := {}
	for frame in 20000:
		await physics_frame
		bee.global_position.y = 0.9 if wave._waiting_for_human else 7.0
		bee.global_position.x = stage.distance - 4.8
		for unit in wave.active_units.duplicate():
			var id: int = unit.get_instance_id()
			if not seen.has(id):
				seen[id] = wave._clock
			var event_id := int(str(unit.name).get_slice("_", 1))
			if event_id > 0 and wave._pending.is_empty() and wave._clock - float(seen[id]) > 2.0:
				unit.get_node("HealthComponent").take_damage(9999)
		if wave._waiting_for_human:
			bee.global_position.y = 7.0
			bee.global_position.x = stage.distance - 5.1
		if wave.boss != null and wave.boss.is_active():
			wave.boss.health.take_damage(99999)
		if frame % 600 == 0:
			var names := []
			for u in wave.active_units:
				names.append("%s:%s" % [u.name, str(u.get("current_state"))])
			print("T frame=%d dist=%.1f scroll=%.1f ev=%d pending=%d gate=%s human=%s units=%s" % [frame, stage.distance, stage.scroll_speed, wave.event_index, wave._pending.size(), wave._hard_gate, wave._waiting_for_human, str(names)])
		if stage.sector_complete:
			print("COMPLETE frame=", frame)
			break
	quit(0)
