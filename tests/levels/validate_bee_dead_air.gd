extends SceneTree
## Clean title -> level load, with a moving Bee and enemies living 3-6 seconds on screen.
## No game class names here: their resolution would change the boot order.
const TITLE := "res://scenes/game/bee_title_screen.tscn"
const LEVEL := "res://scenes/levels/bee_level_01_vertical_slice.tscn"
const ROBOT_SCRIPT := "res://scripts/levels/walker_miniboss.gd"
const MAX_GAME_SECONDS := 620.0
const MAX_ALLOWED_DEAD_AIR := 8.0
const BOT_MIN_LIFE := 3.0
const BOT_LIFE_STEP := 1.0
const BOT_LIFE_VARIANTS := 4
const START_X := -3.0
const BEE_SWAY_X := 1.6
const BEE_SWAY_Y := 1.0
var failures := 0
var first_seen: Dictionary = {}
var max_dead_air := 0.0
var previous_second := -1


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


func run() -> void:
	Engine.time_scale = 4.0
	create_timer(190.0, true, false, true).timeout.connect(func():
		print("FAIL: dead-air test wall timeout")
		quit(1))
	var title := load(TITLE) as PackedScene
	check(title != null, "Title loads")
	if title == null:
		finish()
		return
	var start := title.instantiate()
	root.add_child(start)
	current_scene = start
	for i in 6: await physics_frame
	check(change_scene_to_file(LEVEL) == OK, "Level change succeeds")
	for i in 8: await physics_frame
	var stage := current_scene
	check(stage != null, "Level becomes current scene")
	if stage == null:
		finish()
		return
	var wave = stage.get("wave")
	var bee = stage.get("bee")
	bee.get_node("HealthComponent").damage_blocked = true
	var robot_seen := false
	while float(wave.get("_clock")) < MAX_GAME_SECONDS:
		await physics_frame
		if not is_instance_valid(stage) or not is_instance_valid(wave):
			check(false, "Level stayed loaded")
			break
		var time: float = wave.get("_clock")
		bee.global_position = Vector3(stage.camera.global_position.x + START_X + BEE_SWAY_X * sin(time * 0.27), 3.4 + BEE_SWAY_Y * sin(time * 0.41), 0.0)
		bee.get_node("HealthComponent").damage_blocked = true
		var robot = wave.get("miniboss")
		if is_instance_valid(robot) and robot.get_script() != null and robot.get_script().resource_path == ROBOT_SCRIPT:
			robot_seen = true
			print("DEAD_AIR robot_seen x=%.1f t=%.1f" % [float(stage.distance), time])
			break
		for unit in wave.get("active_units") + wave.get("swarm_units"):
			if not is_instance_valid(unit) or not wave.call("_visible_enemy", unit):
				continue
			var id: int = unit.get_instance_id()
			if not first_seen.has(id):
				first_seen[id] = time
			var life := BOT_MIN_LIFE + BOT_LIFE_STEP * float(id % BOT_LIFE_VARIANTS)
			if time - float(first_seen[id]) >= life:
				var health: Node = unit.get_node_or_null("HealthComponent")
				if health != null:
					health.damage_blocked = false
					health.invulnerable = false
					health.take_damage(99999)
		var eligible: bool = not bool(wave.get("_hard_gate")) and not wave.call("in_arena") and time >= float(wave.get("_breather_until")) and float(wave.get("_tarantula_breather_left")) < 0.0 and not wave.call("intro_active")
		if eligible:
			max_dead_air = maxf(max_dead_air, float(wave.get("_no_visible_seconds")))
		var second := int(time)
		if second != previous_second and second % 20 == 0:
			previous_second = second
			print("DEAD_AIR t=%d x=%.1f event=%d visible_gap=%.1f active=%d pending=%d" % [second, float(stage.distance), int(wave.get("event_index")), float(wave.get("_no_visible_seconds")), wave.get("active_units").size(), wave.get("_pending").size()])
	check(robot_seen, "Slow bot reaches the robot")
	check(float(stage.distance) <= 300.0, "Robot enters near X=294 (actual %.1f)" % float(stage.distance))
	check(max_dead_air < MAX_ALLOWED_DEAD_AIR, "Longest route gap %.1f s < %.1f s" % [max_dead_air, MAX_ALLOWED_DEAD_AIR])
	var anthills := stage.get_node_or_null("Anthills")
	if anthills != null:
		var served := 0
		for hill in anthills.get("hills"):
			print("DEAD_AIR hill=%.1f sent=%d" % [float(hill["x"]), int(hill["sent"])])
			if int(hill["sent"]) >= 1: served += 1
		check(served == anthills.get("hills").size(), "Every anthill spawned ants: %d/%d" % [served, anthills.get("hills").size()])
		print("DEAD_AIR anthills=%d/%d" % [served, anthills.get("hills").size()])
	finish()


func finish() -> void:
	Engine.time_scale = 1.0
	print("BEE_DEAD_AIR_OK max=%.1f" % max_dead_air if failures == 0 else "BEE_DEAD_AIR_FAILED %d max=%.1f" % [failures, max_dead_air])
	quit(0 if failures == 0 else 1)
