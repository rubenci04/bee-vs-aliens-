class_name BeeLevel01Framing
extends RefCounted
## Level 01 camera framing: the single place for camera values and what derives from them.
## THREAT, CAMERA & BOSS REBUILD 03: preset E "ARCADE WIDE" is the default (more room to read and dodge).
## Preset D (Visual Target pass) stays available for comparisons: BeeLevel01Framing.use_preset(&"D").
##   D: distance 8.5, height 2.0, pitch +5°, FOV 40 -> visible 10.7-11.4 m x 6.2 m on the flight plane.
##   E: distance 10.0, height 2.45, pitch +5°, FOV 40 -> visible 12.6-13.4 m x 7.3 m (+18 % each way, +39 % area).
## The camera follows the scroll at the same X. Bee can use almost all of the visible width while keeping equal side margins.

const PRESETS := {
	&"D": {"distance": 8.5, "height": 2.0, "pitch": 5.0, "fov": 40.0},
	&"E": {"distance": 10.0, "height": 2.45, "pitch": 5.0, "fov": 40.0},
	## LOTE 14 · ETAPA 3.2: small screens - preset E pulled back CAMERA_BACK_SCALE (+12 %: distance and height, same pitch and FOV, so the ground line keeps its place).
	&"F": {"distance": 11.2, "height": BeeGameSettings.CAMERA_PRESET_F_HEIGHT, "pitch": 5.0, "fov": 40.0},
}
const CAMERA_BACK_SCALE := 1.12 ## Preset F = preset E x this (documentation; the table above holds the numbers).
const DEFAULT_PRESET := &"F"

static var preset_name: StringName = DEFAULT_PRESET
static var CAMERA_DISTANCE: float = PRESETS[DEFAULT_PRESET]["distance"]
static var CAMERA_HEIGHT: float = PRESETS[DEFAULT_PRESET]["height"]
static var CAMERA_PITCH_DEGREES: float = PRESETS[DEFAULT_PRESET]["pitch"]
static var CAMERA_FOV: float = PRESETS[DEFAULT_PRESET]["fov"]

const FLIGHT_MARGIN := 0.4 # Vertical clearance from the visible top/bottom edges.
const PLAYABLE_WIDTH_FRACTION := 0.95 # Equal 2.5 % screen margins on each side.
const LAKE_RIGHT_FRACTION := 0.66 # Preserve the existing Level 02 prototype window.
const ENTITY_TOP_MARGIN := 0.5 # Enemies, pickups and pollen stay this far below the top edge.
const SPAWN_OUTSIDE_MARGIN := 1.0 # Moving enemies are born this far past the right edge.
const ONSCREEN_SPAWN_X := 4.0 # Static enemies (turret) are born on screen so a hard gate can always be cleared.
const DESIGN_ASPECT := 16.0 / 9.0
## Bee's resting / spawn point, measured from the left edge of the visible width.
const PLAYER_ANCHOR_FRACTION := 0.32


## Switches every camera value (dev comparisons, tests). The next level load / camera update uses it.
static func use_preset(name: StringName) -> void:
	var preset: Dictionary = PRESETS[name]
	preset_name = name
	CAMERA_DISTANCE = preset["distance"]
	CAMERA_HEIGHT = preset["height"]
	CAMERA_PITCH_DEGREES = preset["pitch"]
	CAMERA_FOV = preset["fov"]


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


## Camera-relative X of Bee's anchor (spawn, respawn, harness position).
static func player_anchor_offset(aspect: float) -> float:
	return half_width_min(aspect) * (2.0 * PLAYER_ANCHOR_FRACTION - 1.0)


## Camera-relative X of the right end of Bee's flight window.
static func flight_right_offset(aspect: float) -> float:
	return half_width_min(aspect) * PLAYABLE_WIDTH_FRACTION


static func flight_left_offset(aspect: float) -> float:
	return -half_width_min(aspect) * PLAYABLE_WIDTH_FRACTION


static func lake_flight_right_offset(aspect: float) -> float:
	return half_width_min(aspect) * (2.0 * LAKE_RIGHT_FRACTION - 1.0)
