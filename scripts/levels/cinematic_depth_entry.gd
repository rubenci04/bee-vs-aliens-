class_name CinematicDepthEntry
extends RefCounted
## ARCADE CONTENT & SPECTACLE REBUILD 02 — cinematic 2.5D entry. A threat appears small in the background (deep -Z),
## grows as it flies towards the camera and only becomes a real enemy when it reaches the flight plane (Z = 0).
## While it is in depth it is pure presentation:
##   - no AI (physics stays off until `activate`), so it can never fire from Z
##   - every Area3D off (hurtbox not monitorable, contact hitboxes disabled): no collision, no damage either way
##   - out of `bee_auto_aim_targets`: Bee never locks onto it
## Reusable by any enemy with `activate(bee)`; the Level 01 director uses it for a few entries only.
## Formations: units start packed together in the background and open up into their own slots as they arrive.

const DEPTH_Z := -22.0 ## start depth (camera sits at z = +8.5: the unit looks ~1/4 of its size)
const RISE := 1.6 ## starts a little higher, so it reads as descending from the sky behind the garden
const SECONDS := 2.0
const PACK := 0.3 ## formations start at 30 % of their final spread


## `slot` is the final camera-relative point on the flight plane (x relative to the camera, absolute y);
## `anchor` is the formation's shared camera-relative start. Calls `on_arrive` exactly once, on the plane.
static func begin(unit: Node3D, slot: Vector2, anchor: Vector2, on_arrive: Callable, seconds := SECONDS) -> Tween:
	var camera := unit.get_viewport().get_camera_3d()
	var start := Vector3(anchor.x + (slot.x - anchor.x) * PACK, anchor.y + RISE + (slot.y - anchor.y) * PACK, DEPTH_Z)
	unit.set_meta("depth_entry", true)
	unit.set_meta("depth_was_target", unit.is_in_group("bee_auto_aim_targets"))
	unit.remove_from_group("bee_auto_aim_targets")
	unit.set_physics_process(false)
	for area: Area3D in unit.find_children("*", "Area3D", true, false):
		if area is DamageHitbox3D:
			(area as DamageHitbox3D).set_enabled(false)
		area.set_deferred("monitorable", false)
	unit.show()
	_place(0.0, unit, camera, start, Vector3(slot.x, slot.y, 0.0))
	var tween := unit.create_tween() # Owned by the unit: a level reload frees both, nothing dangles.
	tween.tween_method(_place.bind(unit, camera, start, Vector3(slot.x, slot.y, 0.0)), 0.0, 1.0, seconds) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_arrive.bind(unit, on_arrive))
	return tween


static func is_in_depth(unit: Node) -> bool:
	return bool(unit.get_meta("depth_entry", false))


## progress 0..1: camera-relative path from `start` (deep) to `end` (flight plane), with a gentle arc.
static func _place(progress: float, unit: Node3D, camera: Camera3D, start: Vector3, end: Vector3) -> void:
	if not is_instance_valid(unit) or not is_instance_valid(camera):
		return
	var p := start.lerp(end, progress)
	p.y += sin(progress * PI) * 0.6
	unit.global_position = Vector3(camera.global_position.x + p.x, p.y, p.z)
	unit.scale = Vector3.ONE * lerpf(0.75, 1.0, progress) # A touch of extra growth sells the approach.


static func _arrive(unit: Node3D, on_arrive: Callable) -> void:
	if not is_instance_valid(unit):
		return
	unit.scale = Vector3.ONE
	unit.global_position.z = 0.0
	unit.set_meta("depth_entry", false)
	if unit.has_method("is_defeated") and bool(unit.call("is_defeated")):
		return # Killed by other means (bomb, test harness) while still in depth.
	if bool(unit.get_meta("depth_was_target", false)):
		unit.add_to_group("bee_auto_aim_targets")
	on_arrive.call()
