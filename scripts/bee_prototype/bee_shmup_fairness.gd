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


## False while the enemy has not entered the readable area yet (right) or has been left behind (left).
static func can_fire(enemy: Node3D) -> bool:
	return is_readable(enemy)
