extends SceneTree
## GARDEN IDENTITY 04 — vertical spider threat contract (Level 01).
##   spawn       on screen, born above the top edge, counted as a threat, HP from LEVEL_HP (role MEDIUM)
##   telegraph   implant charges, column + ring visible, ONLY while fully inside the screen; target locks before the drop
##   strike      drops to the locked height (never below min_strike_y: the low lane is always free); one hit per strike
##   escape      a Bee in the low lane (or above the dropped body) is never hit
##   retreat     two attacks, then it climbs out of the top edge and the director drops it at once
##   freed       shooting the implant out: no more damage, out of auto-aim, `defeated` once
##   level       3 appearances (acts 2, 3, 4), soft events only, never above the threat cap
##   checkpoint  respawn at X=190 keeps the late spider ahead and clears the early ones
##   restart     R reloads a clean level (no spider left over)
##   godot --headless --path . --script res://tests/levels/validate_bee_controlled_spider_v01.gd

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var failed := false


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok and not failed:
		failed = true
		push_error(message)
		print("SPIDER_V01_FAIL ", message)
		quit(1)


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func fresh(distance: float) -> void:
	if stage != null:
		stage.queue_free()
		await frames(2)
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.set_physics_process(false)
	wave.set_physics_process(false)
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 3.6, 0.0)
	await frames(2)


func spider_spawn(x := 0.0) -> ControlledSpider:
	wave._spawn({"family": "Spider", "slot": 0, "event": 0, "hard": false, "x": x})
	return wave.active_units.back() as ControlledSpider


func run() -> void:
	create_timer(240.0, true, false, true).timeout.connect(func(): print("SPIDER_V01_FAIL timeout"); quit(1)) # Never hang a suite runner.
	# --- 1. spawn / telegraph / strike / escape / retreat -------------------------------------------------------
	await fresh(92.0)
	var spider := spider_spawn(1.0)
	check(spider != null and spider.is_active(), "Spider not spawned/active")
	check(spider.health.max_health == int(BeeLevel01Controller.LEVEL_HP["Spider"]) and BeeLevel01Controller.ROLES["Spider"] == &"MEDIUM", "Spider HP/role")
	check(spider.global_position.y > BeeLevel01Framing.top_y(), "Spider must enter from above the visible top edge")
	check(BeeShmupFairness.is_on_screen(spider), "Spider entry X must be inside the screen")
	check(spider.is_in_group("bee_auto_aim_targets") and wave.active_units.has(spider), "Spider must be a targetable threat")
	var hp_before := bee.health.current_health
	var telegraphs_checked := 0
	var previous_state := spider.current_state
	var locked_y := -1.0
	var hits_at_strike: Array[int] = []
	var stats := {}
	for i in 60 * 14:
		await physics_frame
		if not is_instance_valid(spider) or not wave.active_units.has(spider):
			break
		stats = {"telegraphs": spider.telegraph_count, "strikes": spider.strike_count, "hits": spider.strike_hits, "deepest": spider.max_drop_seen,
				"min_y": spider.min_strike_y, "damage": spider.strike_damage, "escaped": spider.escaped, "token": BeeAttackTokens.held_by(spider)}
		var state := spider.current_state
		if state != previous_state:
			if state == ControlledSpider.State.TELEGRAPH:
				telegraphs_checked += 1
				check(BeeShmupFairness.is_inside_screen(spider, 0.8), "Telegraph started outside the readable screen")
				check(spider._column.visible and spider._ring.visible and spider.implant.mode == &"sting", "Telegraph visuals missing")
			if state == ControlledSpider.State.DROP:
				check(spider.locked, "Drop without a locked target")
				locked_y = spider.lock_y
				check(locked_y >= spider.min_strike_y - 0.001 and locked_y <= spider.hang_height - 0.99, "Strike target outside the escape-lane clamp")
				hits_at_strike.append(spider.strike_hits)
			previous_state = state
		# Bee: in the column at the locked height for the first strike; in the low lane for the second.
		if spider.current_state in [ControlledSpider.State.TELEGRAPH, ControlledSpider.State.DROP, ControlledSpider.State.HOLD]:
			var low_lane := spider.strike_count >= 2 or (spider.strike_count == 1 and spider.current_state == ControlledSpider.State.TELEGRAPH)
			bee.global_position = Vector3(spider.global_position.x, 1.0 if low_lane else 3.4, 0.0)
		if spider.escaped:
			stats["escaped"] = true
			stats["token"] = BeeAttackTokens.held_by(spider)
			stats["targetable"] = spider.is_in_group("bee_auto_aim_targets")
		wave._retire_soft_units(1.0 / 60.0)
	check(telegraphs_checked == 2 and stats["strikes"] == 2 and stats["telegraphs"] == 2, "Expected exactly two telegraphed strikes (got %d/%d)" % [stats["telegraphs"], stats["strikes"]])
	check(stats["hits"] == 1 and bee.health.current_health == hp_before - int(stats["damage"]), "First strike must hit once (14), the low lane must be safe (hits=%d hp=%d)" % [stats["hits"], bee.health.current_health])
	check(float(stats["deepest"]) >= float(stats["min_y"]) - 0.001, "Body went below the low-lane limit")
	check(bool(stats["escaped"]) and not bool(stats.get("targetable", true)) and (not is_instance_valid(spider) or not wave.active_units.has(spider)), "Spider did not leave after two attacks")
	check(not bool(stats["token"]), "Spider kept the heavy-pattern token")
	# --- 2. the thread never hurts: once the body has dropped, the column above it is a free lane ---------------------
	await fresh(165.0)
	spider = spider_spawn(0.5)
	hp_before = bee.health.current_health
	var crossed_on_thread := false
	for i in 60 * 6:
		await physics_frame
		if spider.current_state == ControlledSpider.State.HOLD:
			# On the thread, above the dropped body (the falling body would hit: that is the column threat itself).
			bee.global_position = Vector3(spider.global_position.x, spider.lock_y + 1.7, 0.0)
			crossed_on_thread = true
		else:
			bee.global_position = Vector3(spider.global_position.x - 3.0, 2.6, 0.0) # aside, at the height it locks on
		if spider.current_state == ControlledSpider.State.RETRACT:
			break
	check(crossed_on_thread and spider.strike_count >= 1 and bee.health.current_health == hp_before, "The thread / the space above the dropped body must be safe")
	# --- 3. freed by shooting the implant out ------------------------------------------------------------------------
	var defeated_count := [0]
	spider.defeated.connect(func(_s): defeated_count[0] += 1)
	spider.health.take_damage(9999)
	await frames(2)
	check(spider.current_state == ControlledSpider.State.FREED and not spider.contact.enabled and not spider.is_in_group("bee_auto_aim_targets"), "Freed spider still dangerous/targetable")
	check(defeated_count[0] == 1 and not wave.active_units.has(spider), "Freed spider still counted / defeated not emitted once")
	await frames(48) # FREED lasts 0.7 s; the director releases the node at 1.0 s.
	check(not is_instance_valid(spider) or not spider.visible, "Freed spider did not leave the frame")
	# --- 4. level placement: three appearances, soft, within caps ---------------------------------------------------
	var appearances: Array[float] = []
	for event: Dictionary in BeeLevel01Controller.EVENTS:
		if "Spider" in event["units"]:
			appearances.append(float(event["at"]))
			check(not bool(event.get("hard", false)), "Spider in a hard gate")
			check((event["units"] as Array).size() <= BeeLevel01Controller.threat_cap(float(event["at"])), "Spider event above the threat cap")
	check(appearances.size() == 3, "Expected 3 spider appearances, got %d" % appearances.size())
	var acts := []
	for x in appearances:
		var act := 0
		for i in BeeLevel01Controller.ACT_STARTS.size():
			if x >= BeeLevel01Controller.ACT_STARTS[i]:
				act = i + 1
		acts.append(act)
	check(acts == [2, 3, 4], "Spider appearances must be in acts 2, 3 and 4 (got %s)" % str(acts))
	# The director never exceeds the cap around a spider event (accelerated real progression, Bee fixture-protected).
	await fresh(appearances[1] - 2.0)
	wave.event_index = 0
	while float(BeeLevel01Controller.EVENTS[wave.event_index]["at"]) < appearances[1] - 2.0:
		wave.event_index += 1
	bee.health.damage_blocked = true
	stage.scroll_speed = 2.0
	stage.set_physics_process(true)
	wave.set_physics_process(true)
	var spider_seen := false
	for i in 60 * 12:
		await physics_frame
		check(wave.active_units.size() <= BeeLevel01Controller.threat_cap(stage.distance), "Threat cap exceeded near the spider")
		for unit in wave.active_units:
			spider_seen = spider_seen or unit is ControlledSpider
	check(spider_seen, "Director did not launch the act-3 spider")
	# --- 5. checkpoint: early spiders consumed, the late one still ahead ---------------------------------------------
	await fresh(190.0)
	wave.resume_after_checkpoint(190.0)
	var remaining := 0
	for index in range(wave.event_index, BeeLevel01Controller.EVENTS.size()):
		if "Spider" in BeeLevel01Controller.EVENTS[index]["units"]:
			remaining += 1
	check(remaining == 1, "After the checkpoint exactly the late spider must remain (got %d)" % remaining)
	# --- 6. restart: a clean level ------------------------------------------------------------------------------------
	spider = spider_spawn(0.0)
	await frames(10)
	var old := stage
	bee.health.take_damage(9999)
	await frames(2)
	stage.set_physics_process(true)
	Input.action_press("restart")
	for i in 6:
		await process_frame
	Input.action_release("restart")
	await frames(3)
	stage = current_scene as BeeShmupStage
	check(stage != old and is_instance_valid(stage), "R did not reload the level")
	var leftovers := 0
	for node in stage.find_children("*", "Node3D", true, false):
		if node is ControlledSpider:
			leftovers += 1
	check(leftovers == 0 and get_nodes_in_group("bee_auto_aim_targets").filter(func(n): return n is ControlledSpider).is_empty(), "Spider survived the restart")
	if not failed:
		print("BEE_CONTROLLED_SPIDER_V01_OK spawn telegraph_on_screen lock strike=14x1 low_lane thread_safe retreat freed appearances=%s caps checkpoint restart" % str(appearances))
		quit(0)
