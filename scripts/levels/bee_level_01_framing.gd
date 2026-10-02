class_name BeeLevel01Framing
extends RefCounted
## Level 01 camera framing: the single place for camera values and what derives from them.
## Preset D chosen from dev/camera_review/camera_review.tscn.
## To go back to the previous framing: CAMERA_DISTANCE = 13.0, CAMERA_HEIGHT = 4.0, CAMERA_PITCH_DEGREES = 0.0.

const CAMERA_DISTANCE := 8.5
const CAMERA_HEIGHT := 2.0
const CAMERA_PITCH_DEGREES := 5.0
const CAMERA_FOV := 40.0

const FLIGHT_MARGIN := 0.4 # Bee never gets closer than this to any visible edge.
const ENTITY_TOP_MARGIN := 0.5 # Enemies, pickups and pollen stay this far below the top edge.
const SPAWN_OUTSIDE_MARGIN := 1.0 # Moving enemies are born this far past the right edge.
const ONSCREEN_SPAWN_X := 4.0 # Static enemies (turret) are born on screen so a hard gate can always be cleared.
const DESIGN_ASPECT := 16.0 / 9.0


static func view_aspect(viewport: Viewport) -> float:
	if DisplayServer.get_name() == "headless":
		return DESIGN_ASPECT # Headless windows are tiny and square; tests assume the design aspect.
	var size := viewport.get_visible_rect().size
	return size.x / maxf(size.y, 1.0)


static func _tan_half_fov() -> float:
	return tan(deg_to_rad(CAMERA_FOV * 0.5))


# Distance along the view ray to the Z=0 flight plane for the bottom (-1) / top (+1) screen edge.
static func _plane_distance(edge: float) -> float:
	var pitch := deg_to_rad(CAMERA_PITCH_DEGREES)
	return CAMERA_DISTANCE / (cos(pitch) - edge * _tan_half_fov() * sin(pitch))


static func _plane_y(edge: float) -> float:
	var pitch := deg_to_rad(CAMERA_PITCH_DEGREES)
	return CAMERA_HEIGHT + (edge * _tan_half_fov() * cos(pitch) + sin(pitch)) * _plane_distance(edge)


static func bottom_y() -> float:
	return _plane_y(-1.0)


static func top_y() -> float:
	return _plane_y(1.0)


# Visible half width at the Z=0 plane. The pitched view is a trapezoid: narrower at the bottom edge.
static func half_width_min(aspect: float) -> float:
	return _tan_half_fov() * aspect * _plane_distance(-1.0)


static func half_width_max(aspect: float) -> float:
	return _tan_half_fov() * aspect * _plane_distance(1.0)


static func max_entity_y() -> float:
	return top_y() - ENTITY_TOP_MARGIN


static func spawn_offset_x(aspect: float) -> float:
	return half_width_max(aspect) + SPAWN_OUTSIDE_MARGIN
