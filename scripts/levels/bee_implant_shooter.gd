class_name BeeImplantShooter
extends Node
## Level-only removable implant weapon. Body attacks retain their original timing.
## LOTE 13 · ETAPA 2: every family has its own pattern and shot look (BeeShotStyles): the ant LOBS an orange pebble in an arc, the
## stag beetle lobs stones, the spider throws a white web fan, the ladybird fans red seeds. The first volley starts FIRST_DELAY s
## after the unit is active (rule: every enemy attacks within ~1 s of entering the screen); every warning lasts WARNING_SECONDS.
const SHOT := preload("res://scenes/projectiles/toon/alien_bolt.tscn")
const WARNING_SECONDS := 0.6
const FIRST_DELAY := 0.25
const COOLDOWN_SECONDS := 3.0
const SHOT_SPEED := 3.8 # LOTE 13: slower shots (dodgeable and longer on screen) for the dense roster
const SHOT_DAMAGE := 7
const MIN_RANGE := 3.2
## Per-family volley cooldown (s) when it differs from COOLDOWN_SECONDS.
## LOTE 14: the ladybird fires ONE slow seed with a long pause (it was a fan of 3: too much).
const COOLDOWN_BY_FAMILY := {"Ladybird": 5.5}
const SPEED_BY_FAMILY := {"Ladybird": 2.6}
const FAN_FAMILIES := ["StagBeetle", "Dragonfly", "WaveDragonfly", "Spider"]
## Families that fan on EVERY volley (the rest alternate fan / single).
const ALWAYS_FAN := ["Spider"]
## Families that LOB their shot (arc): flight time (s) to the spot Bee had when the warning ended, and gravity (m/s²).
const LOB_FAMILIES := ["Ant", "StagBeetle"]
const LOB_FLIGHT := 1.15
const LOB_GRAVITY := 8.0
const SHOT_STYLES := {"Ant": &"pebble", "StagBeetle": &"stone", "Spider": &"web", "Ladybird": &"seed"}
var family := ""
var target: BeePlayer
var clock := FIRST_DELAY
var warning: Node3D
var locked_aim := Vector3.LEFT
var locked_point := Vector3.ZERO
var volleys := 0
var warnings_started := 0 ## Warnings shown so far (tests: a unit warns within ~1 s of entering).

func _physics_process(delta: float) -> void:
	var unit := get_parent() as Node3D
	if not is_instance_valid(target) or not unit.is_visible_in_tree() or not unit.call("is_active") or bool(unit.get_meta("level_retreat", false)):
		_cancel()
		return
	if is_instance_valid(warning):
		warning.global_position = _origin(unit)
		if unit.has_method("set_pincers"):
			unit.call("set_pincers", 1.0 - clampf(clock / WARNING_SECONDS, 0.0, 1.0)) # The pincers open while the stone is charged.
	clock -= delta
	if clock > 0.0:
		return
	if warning == null:
		if not BeeShmupFairness.can_fire(unit) or unit.global_position.distance_to(target.global_position) < MIN_RANGE:
			clock = 0.2
			return
		locked_aim = target.global_position - unit.global_position
		locked_point = target.global_position
		warning = BeeAttackVisuals.ring(unit, _origin(unit), 0.45, 0.07, Color(0.2, 0.9, 1.0, 0.9))
		warnings_started += 1
		clock = WARNING_SECONDS
		return
	_cancel()
	if BeeShmupFairness.can_fire(unit):
		var origin := _origin(unit)
		var style: StringName = SHOT_STYLES.get(family, &"")
		if family in LOB_FAMILIES:
			# An arc to the spot Bee was at when the warning ended: it never homes, so moving away dodges it.
			BeeEnemyPatterns.spawn_lob(unit.get_parent(), SHOT, origin, locked_point, SHOT_DAMAGE, LOB_FLIGHT, LOB_GRAVITY, unit, style)
		else:
			var count := 3 if family in FAN_FAMILIES and (family in ALWAYS_FAN or volleys % 2 == 0) else 1
			for direction in BeeEnemyPatterns.fan_directions(locked_aim, count, BeeEnemyPatterns.fan_step_degrees(locked_aim.length())):
				if style != &"":
					BeeEnemyPatterns.spawn_styled(unit.get_parent(), SHOT, origin, direction, SHOT_DAMAGE, float(SPEED_BY_FAMILY.get(family, SHOT_SPEED)), unit, style)
				else:
					BeeEnemyPatterns.spawn_shot(unit.get_parent(), SHOT, origin, direction, SHOT_DAMAGE, float(SPEED_BY_FAMILY.get(family, SHOT_SPEED)), unit)
		volleys += 1
	clock = float(COOLDOWN_BY_FAMILY.get(family, COOLDOWN_SECONDS))

func _cancel() -> void:
	var owner_unit := get_parent()
	if is_instance_valid(owner_unit) and owner_unit.has_method("set_pincers"):
		owner_unit.call("set_pincers", 0.0)
	if is_instance_valid(warning):
		warning.queue_free()
	warning = null

func _exit_tree() -> void:
	_cancel()


## Where the volley leaves from: the stag beetle throws from between its pincers, the rest from their back (the implant).
func _origin(unit: Node3D) -> Vector3:
	if family == "StagBeetle" and unit.has_method("pincer_point"):
		return unit.call("pincer_point")
	return unit.global_position + Vector3(0, 0.4, 0)
