class_name BeeAttackTokens
extends RefCounted
## THREAT, CAMERA & BOSS REBUILD 03 — "no unfair stacks". Only one HEAVY pattern may run at a time in Level 01:
## Wasp overload dash, Walker sweep, EyeDrone fan, OrganicAlien lunge. A unit that cannot claim the token falls back
## to its basic attack (or waits a beat), so attack windows overlap but never all land in the same instant.
## Off by default (POCs and the boss are untouched); the Level 01 director switches it on.
## Time is game time (physics frames), so time-scaled tests behave like real play.

static var enabled := false
static var _owner_id := 0
static var _until := 0.0


static func now() -> float:
	return float(Engine.get_physics_frames()) / float(Engine.physics_ticks_per_second)


## True if `unit` may start a heavy pattern lasting about `seconds` (and it now holds the token).
static func try_claim(unit: Object, seconds: float) -> bool:
	if not enabled:
		return true
	var t := now()
	if _owner_id != 0 and _owner_id != unit.get_instance_id() and t < _until:
		var holder := instance_from_id(_owner_id)
		var alive := holder != null and is_instance_valid(holder) and not (holder.has_method("is_defeated") and bool(holder.call("is_defeated")))
		if alive:
			return false
	_owner_id = unit.get_instance_id()
	_until = t + seconds
	return true


static func release(unit: Object) -> void:
	if _owner_id == unit.get_instance_id():
		_owner_id = 0
		_until = 0.0


static func held_by(unit: Object) -> bool:
	return enabled and _owner_id == unit.get_instance_id() and now() < _until


static func reset() -> void:
	_owner_id = 0
	_until = 0.0
