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


## LOTE 13 · ETAPA 2: `style` names the family look (BeeShotStyles: stinger, acid, web, pebble, bubble, spore, ...); the Level 1 stage
## dresses the shot with it when it enters the tree (cyan core always, own rim / shape / trail). The shot also points along its path.
static func spawn_styled(parent: Node, scene: PackedScene, origin: Vector3, direction: Vector3, damage: int, speed: float, attacker: Node, style: StringName) -> AlienEnemyProjectile:
	var projectile := scene.instantiate() as AlienEnemyProjectile
	projectile.damage = damage
	if speed > 0.0:
		projectile.speed = speed
	projectile.set_meta("shot_style", style)
	parent.add_child(projectile)
	projectile.global_position = origin
	projectile.launch(direction, attacker)
	projectile.rotation.z = atan2(projectile.travel_direction.y, projectile.travel_direction.x)
	return projectile


## Launch velocity of a lob from `from` that lands on `to` after `flight_time` seconds under `gravity` (m/s²).
static func lob_velocity(from: Vector3, to: Vector3, flight_time: float, gravity: float) -> Vector3:
	var t := maxf(flight_time, 0.2)
	return Vector3((to.x - from.x) / t, (to.y - from.y) / t + 0.5 * gravity * t, 0.0)


## A lobbed (arc) shot aimed to land on `target_point` after `flight_time` s. Fixed path: it never homes.
static func spawn_lob(parent: Node, scene: PackedScene, origin: Vector3, target_point: Vector3, damage: int, flight_time: float, gravity: float, attacker: Node, style: StringName) -> AlienEnemyProjectile:
	var velocity := lob_velocity(origin, target_point, flight_time, gravity)
	var projectile := scene.instantiate() as AlienEnemyProjectile
	projectile.damage = damage
	projectile.speed = velocity.length()
	projectile.gravity = gravity
	projectile.lifetime = flight_time + 1.2
	projectile.set_meta("shot_style", style)
	parent.add_child(projectile)
	projectile.global_position = origin
	projectile.launch(velocity.normalized(), attacker)
	return projectile
