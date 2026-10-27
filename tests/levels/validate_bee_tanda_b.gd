extends SceneTree
const S := preload("res://scripts/game/bee_encounter_settings.gd")
var failures := 0
var stage: BeeShmupStage
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(count: int) -> void:
	for i in count: await physics_frame
func run() -> void:
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.get_node("CheckpointQoL").set_process(false)
	stage.get_node("Juice").set_process(false)
	stage.distance = 138
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(134,3,0)
	var wave := stage.wave
	check(BeeLevel01Controller.EVENTS_ROSTER[0].units.size() == 3,"First wave demonstrates three real arrivals")
	wave._spawn({"family":"FlyCommon","event":0,"slot":0,"hard":false,"y":3.0})
	var unit = wave.active_units.back()
	var hp: int = unit.health.current_health
	check(unit.get_meta("teleporting") and not unit.visible and unit.health.damage_blocked,"Passenger hidden, blocked and counted during floor mark")
	await frames(20)
	check(not unit.visible and not unit.is_active(),"No enemy or attack before 0.5 second mark")
	await frames(20)
	check(unit.visible and unit.get_meta("teleporting") and unit.process_mode == Node.PROCESS_MODE_DISABLED,"Dither passenger is inside the beam with inert subtree")
	var effect = stage.get_node("Enemies").get_node("EnemyTeleport")
	check(effect.beam.visible and absf(unit.global_position.x-effect.beam.global_position.x)<0.01,"Enemy materializes in its own beam")
	var time_before: float = effect.elapsed
	paused = true
	for i in 4: await process_frame
	check(effect.elapsed == time_before,"Pause stops arrival")
	paused = false
	await frames(40)
	check(not unit.get_meta("teleporting") and unit.is_active() and not unit.health.damage_blocked,"Arrival restores health and activates once")
	unit.set_physics_process(false)
	unit.global_position.x = stage.camera.global_position.x-20
	wave._retire_soft_units(1.0)
	check(wave.active_units.has(unit) and unit.health.current_health==hp and wave.escaped_count==0,"Off-left enemy returns without deletion, score or HP reset")
	await frames(18)
	check(unit.scale.x>1 and unit.scale.x<=1.1201,"Return has its own small scale cue")
	await frames(65)
	check(not unit.get_meta("teleporting") and unit.global_position.distance_to(stage.bee.global_position)<S.REACH,"Return arrives within Bee reach %s %s tele=%s" % [str(unit.global_position),str(stage.bee.global_position),str(unit.get_meta("teleporting"))])
	# E1: every beam arrival lands in the right third of the frame, >= 4.5 m ahead of Bee when there is room.
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(stage.get_viewport()))
	for bee_x in [stage.camera.global_position.x-6.0, stage.camera.global_position.x, stage.camera.global_position.x+3.0]:
		stage.bee.global_position.x = bee_x
		for slot in 3:
			var point: Vector3 = wave._arrival_point(unit,slot)
			var cam_x: float = stage.camera.global_position.x
			check(point.x >= cam_x+2.8-0.001 and point.x <= cam_x+half-1.0+0.001,"Arrival x=%.1f inside the right third (cam %.1f)" % [point.x,cam_x])
			if bee_x+4.5 <= cam_x+half-1.0: check(point.x >= bee_x+4.5-0.001,"Arrival >= 4.5 m ahead of Bee")
	stage.bee.global_position = Vector3(134,3,0)
	unit.set_physics_process(false)
	unit.global_position.x = stage.camera.global_position.x+30
	unit.set_meta("last_near",0.0)
	unit.set_meta("approach_distance",unit.global_position.distance_to(stage.bee.global_position))
	wave._clock = 13.0
	wave._retire_soft_units(0.0)
	check(unit.get_meta("teleporting"),"One unreachable survivor is rescued after twelve seconds")
	await frames(80)
	unit.set_physics_process(false)
	var event := {"units":["FlyCommon"],"arena":[],"arena_label":"TEST"}
	wave._begin_arena(event,0)
	check(stage.scroll_speed==0 and wave.zone_remaining()==1 and wave.player_label.contains("1 PENDIENTES"),"Gate and persistent counter include surviving enemy")
	wave._clock += 1000.0
	wave._arena["next_arrival"] = wave._clock+30.0
	wave._update_arena(0.0)
	check(wave.in_arena() and stage.scroll_speed==0,"Old arena timeout cannot open a gate")
	unit.health.take_damage(9999)
	wave._update_arena(0.0)
	check(not wave.in_arena() and stage.scroll_speed==wave.level_scroll() and wave.player_label=="ZONA DESPEJADA","Last real liberation opens gate and shows clear")
	wave._begin_arena({"units":["Ant"],"arena":[{"units":["Ant"],"no_companions":true}]},5)
	check(wave.zone_remaining()==1,"Future authored wave also blocks gate")
	wave._update_arena(wave.arena_cadence()+1.0)
	check(wave.active_units.size()==1 and wave.zone_remaining()==1 and stage.scroll_speed==0,"Queued wave becomes a real mandatory passenger")
	await frames(75)
	var ant = wave.active_units.back()
	check(ant.is_active() and not ant.get_meta("teleporting"),"Ground wave uses a real arrival")
	# Periodic arrival without an endless pending backlog.
	wave._clock += S.EXTRA_ARRIVAL_SECONDS
	wave._update_arena(0)
	check(not wave._pending.is_empty() or wave.active_units.size()>1,"Long zone receives another arrival at thirty seconds")
	# Exercise every authored zone with real arrivals and real health/liberation signals.
	for actor in wave.active_units.duplicate():
		actor.health.damage_blocked = false
		actor.health.take_damage(9999)
	wave._pending.clear()
	wave._arena = {}
	await frames(80)
	for authored: Dictionary in BeeLevel01Controller.EVENTS_ROSTER:
		if not authored.has("arena"): continue
		stage.distance = float(authored.at)
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(stage.distance-2,3,0)
		wave._solo_until = 0
		wave._queue_units(authored,100,0)
		wave._begin_arena(authored,100)
		var cleared := false
		for tick in 60*120:
			await physics_frame
			wave._clock += 1.0/60.0
			wave._spawn_pending()
			for actor in wave.active_units.duplicate():
				if actor.get_meta("teleporting",false): continue
				actor.health.take_damage(9999)
			wave._update_arena(1.0/60.0)
			if not wave.in_arena():
				cleared = true
				break
			check(stage.scroll_speed==0,"Authored zone cannot creep during combat")
		check(cleared and wave.zone_remaining()==0,"Every authored zone clears only after all waves and passengers")
	wave._spawn({"family":"Swarm","event":0,"slot":0,"hard":false,"path":"kamikaze"})
	await frames(75)
	var drone = wave.swarm_units.back()
	drone.set_physics_process(false)
	drone._kz_state = 2
	drone._kz_left = -1.0
	drone.escaped = true
	wave._return_enemy(drone)
	await frames(80)
	check(wave.swarm_units.has(drone) and drone._kz_state!=2 and not drone.escaped and not drone.get_meta("teleporting"),"Expired popcorn attack returns as a live enemy with a fresh warning, without a teleport loop")
	stage.bee.global_position = Vector3(134,3,0)
	wave._spawn({"family":"Ant","event":3,"slot":1,"hard":false})
	var walker_in = wave.active_units.back()
	check(not walker_in.get_meta("teleporting",false) and walker_in.global_position.x > stage.camera.global_position.x+half-0.5,"E1: route units (slot 1) walk in from the right edge instead of the beam")
	wave._spawn({"family":"Ant","event":3,"slot":3,"hard":false})
	check(wave.active_units.back().get_meta("teleporting",false),"E1: every third route unit still uses the beam")
	await frames(80)
	print("TANDA_B_OK failures=",failures)
	quit(1 if failures else 0)
