extends SceneTree
## Tanda C (T6e): no common enemy exceeds the T6b time-to-kill cap (1.5 s common / 2.0 s large at the 36 DPS of the base weapon), and
## the units the level really spawns carry exactly those HP (the new personalities change behaviour, never health).
const H := preload("res://scripts/game/bee_enemy_health_settings.gd")
const DPS := 36.0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.distance = 200
	stage._update_camera_and_bounds()
	var report := []
	var slot := 0
	for family in ["Ant", "Ladybird", "Wasp", "WormA", "WormB", "StagBeetle", "Snail", "Spider"]:
		stage.wave._spawn({"family": family, "slot": slot, "event": 0, "hard": false})
		slot += 1
		var unit: Node = stage.wave.active_units.back()
		var hp: int = unit.health.max_health
		check(hp == BeeGameSettings.scaled_hp(BeeLevel01Controller.level_hp(family)), "%s spawns with the configured HP" % family)
		var base_hp := int(H.COMMON_HP[family])
		var cap: float = H.target_time(family).y
		var ttk := float(base_hp) / DPS
		check(ttk <= cap + 0.0001, "%s TTK %.3f s within the %.1f s cap" % [family, ttk, cap])
		report.append("%s hp=%d ttk=%.3f cap=%.1f" % [family, base_hp, ttk, cap])
	print("TANDA_C_TTK failures=", failures, " ", report)
	quit(1 if failures else 0)
