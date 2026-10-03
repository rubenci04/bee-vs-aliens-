class_name BeeEnemyPatterns
extends RefCounted
## ARCADE COMBAT PATTERN & DENSITY PASS 02. Shared helpers for the legible enemy fire patterns:
##   AIMED  one shot (or a short burst) that re-aims at Bee at the moment of firing, then flies straight;
##   FAN    N shots centred on Bee, spaced so there is always a passable lane between neighbours.
## Nothing here homes, randomises or aims at where Bee will be: every shot has a fixed straight path.
## Callers still run BeeShmupFairness.can_fire once per volley (no fire from outside the readable area).

## Clearance needed between two neighbouring fan lanes at Bee's distance: Bee's hurtbox radius (0.20) + the
## shot collider (0.14) on each side of a lane, plus a small margin.
const MIN_LANE_GAP := 1.0
const FAN_STEP_MIN := 12.0
const FAN_STEP_MAX := 18.0


## Angular step for a fan at `distance` metres: wide enough for MIN_LANE_GAP between lanes, inside 12-18 degrees.
static func fan_step_degrees(distance: float) -> float:
	return clampf(rad_to_deg(atan2(MIN_LANE_GAP, maxf(distance, 0.5))), FAN_STEP_MIN, FAN_STEP_MAX)


## Lateral gap (m) between two neighbouring fan lanes at `distance`.
static func lane_gap(distance: float, step_degrees: float) -> float:
	return 2.0 * distance * tan(deg_to_rad(step_degrees) * 0.5)


## `count` directions in the XY plane, centred on `aim`, `step_degrees` apart.
static func fan_directions(aim: Vector3, count: int, step_degrees: float) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var flat := Vector3(aim.x, aim.y, 0.0).normalized()
	if flat == Vector3.ZERO:
		flat = Vector3.LEFT
	for i in count:
		var offset := (float(i) - float(count - 1) * 0.5) * step_degrees
		result.append(flat.rotated(Vector3.BACK, deg_to_rad(offset)))
	return result


static func spawn_shot(parent: Node, scene: PackedScene, origin: Vector3, direction: Vector3, damage: int, speed: float, attacker: Node) -> AlienEnemyProjectile:
	var projectile := scene.instantiate() as AlienEnemyProjectile
	projectile.damage = damage
	if speed > 0.0:
		projectile.speed = speed
	parent.add_child(projectile)
	projectile.global_position = origin
	projectile.launch(direction, attacker)
	return projectile
