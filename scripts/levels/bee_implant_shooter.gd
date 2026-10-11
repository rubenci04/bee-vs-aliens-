class_name BeeImplantShooter
extends Node
## Level-only removable implant weapon. Body attacks retain their original timing.
const SHOT := preload("res://scenes/projectiles/toon/alien_bolt.tscn")
const WARNING_SECONDS := 0.6
const COOLDOWN_SECONDS := 3.2
const SHOT_SPEED := 5.2
const SHOT_DAMAGE := 7
const MIN_RANGE := 3.2
const FAN_FAMILIES := ["Ladybird", "StagBeetle", "Dragonfly", "WaveDragonfly"]
var family := ""
var target: BeePlayer
var clock := 1.0
var warning: Node3D
var locked_aim := Vector3.LEFT
var volleys := 0

func _physics_process(delta: float) -> void:
	var unit := get_parent() as Node3D
	if not is_instance_valid(target) or not unit.is_visible_in_tree() or not unit.call("is_active") or bool(unit.get_meta("level_retreat", false)):
		_cancel()
		return
	if is_instance_valid(warning):
		warning.global_position = unit.global_position + Vector3(0, 0.4, 0)
	clock -= delta
	if clock > 0.0:
		return
	if warning == null:
		if not BeeShmupFairness.can_fire(unit) or unit.global_position.distance_to(target.global_position) < MIN_RANGE:
			clock = 0.2
			return
		locked_aim = target.global_position - unit.global_position
		warning = BeeAttackVisuals.ring(unit, unit.global_position + Vector3(0, 0.4, 0), 0.45, 0.07, Color(0.2, 0.9, 1.0, 0.9))
		clock = WARNING_SECONDS
		return
	_cancel()
	if BeeShmupFairness.can_fire(unit):
		var count := 3 if family in FAN_FAMILIES and volleys % 2 == 0 else 1
		for direction in BeeEnemyPatterns.fan_directions(locked_aim, count, BeeEnemyPatterns.fan_step_degrees(locked_aim.length())):
			BeeEnemyPatterns.spawn_shot(unit.get_parent(), SHOT, unit.global_position + Vector3(0, 0.4, 0), direction, SHOT_DAMAGE, SHOT_SPEED, unit)
		volleys += 1
	clock = COOLDOWN_SECONDS

func _cancel() -> void:
	if is_instance_valid(warning):
		warning.queue_free()
	warning = null

func _exit_tree() -> void:
	_cancel()
