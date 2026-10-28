extends SceneTree
## Reproduce the title -> level -> robot -> tarantula load order in a fresh Godot process.
## Keep game class names out of this script: resolving them changes the load order.
class ErrorCounter extends Logger:
	var count := 0
	var critical := 0
	var samples: Array[String] = []
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _backtraces: Array) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING:
			return
		count += 1
		var detail := "%s %s" % [code, rationale]
		if "Parse Error" in detail or "non-existent resource" in detail or "SCRIPT ERROR" in detail or "Invalid call" in detail or "Invalid assignment" in detail:
			critical += 1
		if samples.size() < 12:
			samples.append("%s:%d %s %s" % [file, line, code, rationale])

const ROBOT_SCRIPT := "res://scripts/levels/walker_miniboss.gd"
const TARANTULA_SCRIPT := "res://scripts/levels/tarantula_boss_01.gd"
const MAX_ROBOT_FRAMES := 60 * 15
const ROBOT_FIGHT_FRAMES := 60 * 20
const MAX_TARANTULA_FRAMES := 60 * 45
const TARANTULA_FIGHT_FRAMES := 60 * 12
var failures := 0
var errors := ErrorCounter.new()

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func is_script(node: Node, path: String) -> bool:
	return is_instance_valid(node) and node.get_script() != null and node.get_script().resource_path == path

func run() -> void:
	OS.add_logger(errors)
	create_timer(180.0, true, false, true).timeout.connect(func(): quit(1))
	Engine.max_physics_steps_per_frame = 16
	var title := load("res://scenes/game/bee_title_screen.tscn") as PackedScene
	check(title != null, "Title scene loads")
	if title == null:
		finish()
		return
	var title_instance := title.instantiate()
	root.add_child(title_instance)
	current_scene = title_instance
	for i in 6: await physics_frame
	check(change_scene_to_file(BeeGameSettings.LEVEL_01) == OK, "Level change succeeds")
	for i in 8: await physics_frame
	var stage := current_scene
	check(stage != null and stage.has_node("CheckpointQoL"), "Level is current scene")
	if stage == null or not stage.has_node("CheckpointQoL"):
		finish()
		return
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 293.0
	stage._update_camera_and_bounds()
	var wave = stage.wave
	wave.resume_after_checkpoint(293.0)
	var bee = stage.bee
	bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 3.0, 0.0)
	bee.health.damage_blocked = true
	var robot: Node
	for i in MAX_ROBOT_FRAMES:
		await physics_frame
		if is_script(wave.miniboss, ROBOT_SCRIPT):
			robot = wave.miniboss
			break
	check(robot != null, "Robot enters")
	if robot == null:
		finish()
		return
	for i in ROBOT_FIGHT_FRAMES: await physics_frame
	print("BOOT_ORDER robot_step=%s attacks=%s errors=%d" % [str(robot.get("_step")), str(robot.get("hazards")), errors.count])
	check(robot.get("_beam_box") != null, "Robot laser hitbox exists after laser attack")
	check(robot.get("_land_box") != null, "Robot landing hitbox exists after jump attack")
	robot.get_node("HealthComponent").take_damage(99999)
	var spider: Node
	var previous_second := -1
	for i in MAX_TARANTULA_FRAMES:
		await physics_frame
		bee.global_position.x = minf(stage.camera.global_position.x + 1.0, bee.global_position.x + 0.05)
		bee.global_position.y = clampf(bee.global_position.y, 1.5, 5.0)
		if is_script(wave.tarantula, TARANTULA_SCRIPT): spider = wave.tarantula
		var second := i / 60
		if second != previous_second:
			previous_second = second
			print("BOOT_ORDER post_robot=%ds state=%s pos=%s fan=%s nets=%s spits=%s errors=%d" % [second, str(spider.get("state")) if spider else "absent", str(spider.global_position) if spider else "-", str(spider.get("fired_fan")) if spider else "-", str(spider.get("nets")) if spider else "-", str(spider.get("spits")) if spider else "-", errors.count])
		if spider != null and spider.state == 1: break # PHASE_1, without naming the class.
	check(spider != null and spider.state == 1, "Tarantula reaches PHASE_1")
	if spider != null:
		# A failed preload may report a parse error before the Logger can observe it.
		var projectile_constant: Dictionary = spider.get_script().get_script_constant_map()
		if projectile_constant.has("PROJECTILE"):
			check(projectile_constant["PROJECTILE"] != null, "Boss projectile preload is valid")
		var hp_before = spider.get_node("HealthComponent").current_health
		spider.get_node("HealthComponent").take_damage(1)
		check(spider.get_node("HealthComponent").current_health < hp_before, "Tarantula receives damage")
		for i in TARANTULA_FIGHT_FRAMES:
			await physics_frame
			if i % 60 == 0:
				print("BOOT_ORDER fight=%ds state=%s pos=%s fan=%s nets=%s spits=%s errors=%d" % [i / 60, str(spider.get("state")), str(spider.global_position), str(spider.get("fired_fan")), str(spider.get("nets")), str(spider.get("spits")), errors.count])
		check(int(spider.get("fired_fan")) + int(spider.get("nets")) + int(spider.get("spits")) > 0, "Tarantula fires webs")
	finish()

func finish() -> void:
	check(errors.critical == 0, "No parse/resource/script errors (critical=%d, engine=%d): %s" % [errors.critical, errors.count, str(errors.samples)])
	print("BEE_BOOT_ORDER_OK" if failures == 0 else "BEE_BOOT_ORDER_FAILED %d" % failures)
	quit(0 if failures == 0 else 1)
