class_name BeeShmupFairness
extends RefCounted
## SHMUP fairness rules shared by the ranged enemies (BEE SHMUP FAIRNESS PASS 01).
## Off-screen fire / rear ceasefire: a ranged enemy may only fire while it is legibly inside the
## visible width of the current camera, measured at the enemy's own depth. Evaluated only at the
## moment of firing (no per-frame polling). Enemies keep their normal AI and may still escape;
## only the offensive action is skipped while they are outside the readable area.

## How far inside the screen edge the enemy centre must be before it counts as having entered.
const ENTRY_MARGIN := 0.4


## Half of the visible width, in metres, at the depth of `point` for `camera`.
static func visible_half_width(camera: Camera3D, point: Vector3, aspect: float) -> float:
	var depth := (point - camera.global_position).dot(-camera.global_transform.basis.z)
	return tan(deg_to_rad(camera.fov) * 0.5) * aspect * maxf(depth, 0.01)


static func is_readable(enemy: Node3D) -> bool:
	var viewport := enemy.get_viewport()
	var camera := viewport.get_camera_3d() if viewport != null else null
	if camera == null:
		return true # No camera (isolated tests / tools): nothing to judge against.
	var lateral := (enemy.global_position - camera.global_position).dot(camera.global_transform.basis.x)
	return absf(lateral) <= visible_half_width(camera, enemy.global_position, BeeLevel01Framing.view_aspect(viewport)) - ENTRY_MARGIN


## ARCADE REBUILD 02: ceiling of live hostile shots (0 = off). Set by the Level 01 director only, and only units it
## spawned (meta "level_born") respect it: the UFO boss and every POC keep their patterns untouched. With the ceiling
## at 10 and the largest volley at 5 shots (Eye fan), the screen never holds more than 14 hostile shots.
static var live_shot_ceiling := 0
## ARCADE REBUILD 02: screen-bound combat (Level 01 only, off by default). Bee's shots vanish when they leave the
## visible screen and auto-aim ignores enemies that have not entered it yet. BEFORE: a 19.6 m shot range and a 12 m
## auto-aim reached ~3 m past the right edge, so enemies died before they could even appear.
static var screen_bound_combat := false


## True when `node` is past a screen edge (plus `margin`) and still moving outwards (a shot flying in still lives).
static func is_leaving_screen(node: Node3D, direction: Vector3, margin := 0.0) -> bool:
	var viewport := node.get_viewport()
	var camera := viewport.get_camera_3d() if viewport != null else null
	if camera == null:
		return false
	var lateral := (node.global_position - camera.global_position).dot(camera.global_transform.basis.x)
	var outside := absf(lateral) > visible_half_width(camera, node.global_position, BeeLevel01Framing.view_aspect(viewport)) + margin
	return outside and signf(lateral) == signf(direction.dot(camera.global_transform.basis.x))


## True while `node` is at least `inset` metres inside both visible edges (at its own depth).
static func is_inside_screen(node: Node3D, inset: float) -> bool:
	return is_on_screen(node, -inset)


## True while `node` is inside the visible width at its own depth (`margin` metres past the edge still counts).
static func is_on_screen(node: Node3D, margin := 0.0) -> bool:
	var viewport := node.get_viewport()
	var camera := viewport.get_camera_3d() if viewport != null else null
	if camera == null:
		return true
	var lateral := (node.global_position - camera.global_position).dot(camera.global_transform.basis.x)
	return absf(lateral) <= visible_half_width(camera, node.global_position, BeeLevel01Framing.view_aspect(viewport)) + margin


## False while the enemy has not entered the readable area yet (right) or has been left behind (left).
static func can_fire(enemy: Node3D) -> bool:
	if not is_readable(enemy):
		return false
	if live_shot_ceiling > 0 and enemy.has_meta("level_born") \
			and enemy.get_tree().get_nodes_in_group("alien_projectiles").size() >= live_shot_ceiling:
		return false
	return true
