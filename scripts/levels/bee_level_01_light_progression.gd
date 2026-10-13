class_name BeeLevel01LightProgression
extends Node
## VISUAL LEVEL 01: time of day along the level, driven by the stage scroll position (camera X).
##   x   0-140 warm morning  ->  140-250 golden midday  ->  250-360 orange/violet sunset.
## Presentation only: it only writes Sun, Environment and sky colours. The change is a smoothstep
## blend centred on x=140 and x=250, so there are no jumps.

const MORNING := {
	"sun_color": Color(1.0, 0.9, 0.72), "sun_energy": 1.25, "sun_rotation": Vector3(-40, -25, 0),
	"ambient_color": Color(1.0, 0.91, 0.76), "ambient_energy": 0.7,
	"fog_color": Color(0.86, 0.87, 0.78),
	"sky_top": Color(0.24, 0.55, 0.82), "sky_horizon": Color(0.86, 0.88, 0.8),
	"ground_horizon": Color(0.63, 0.72, 0.53), "ground_bottom": Color(0.24, 0.31, 0.22),
	"glow_intensity": 0.6, "ground_tint": 0.0, "bee_rim": 0.0, "outline_tint": Color(0.3, 0.14, 0.04),
}
const MIDDAY := {
	"sun_color": Color(1.0, 0.82, 0.5), "sun_energy": 1.4, "sun_rotation": Vector3(-58, -18, 0),
	"ambient_color": Color(1.0, 0.88, 0.62), "ambient_energy": 0.75,
	"fog_color": Color(0.9, 0.84, 0.66),
	"sky_top": Color(0.3, 0.55, 0.8), "sky_horizon": Color(0.95, 0.88, 0.68),
	"ground_horizon": Color(0.72, 0.7, 0.45), "ground_bottom": Color(0.3, 0.3, 0.2),
	"glow_intensity": 0.6, "ground_tint": 0.0, "bee_rim": 0.0, "outline_tint": Color(0.34, 0.16, 0.03),
}
# Violet ambient and fog against an orange sun: warm decoration, cool shadows, cyan tech pops.
const SUNSET := {
	"sun_color": Color(1.0, 0.62, 0.4), "sun_energy": 1.05, "sun_rotation": Vector3(-22, -62, 0),
	"ambient_color": Color(0.7, 0.58, 0.86), "ambient_energy": 0.66,
	"fog_color": Color(0.64, 0.45, 0.55),
	"sky_top": Color(0.34, 0.27, 0.56), "sky_horizon": Color(0.98, 0.66, 0.5),
	"ground_horizon": Color(0.7, 0.45, 0.4), "ground_bottom": Color(0.25, 0.2, 0.28),
	"glow_intensity": 0.95, "ground_tint": 1.0, "bee_rim": 1.0, "outline_tint": Color(0.26, 0.1, 0.42),
}
const MORNING_TO_MIDDAY := Vector2(100.0, 180.0)
const MIDDAY_TO_SUNSET := Vector2(210.0, 290.0)

var _last_x := -9999.0
@onready var _stage: Node = get_parent()
@onready var _sun: DirectionalLight3D = _stage.get_node("Sun")
@onready var _environment: Environment = (_stage.get_node("WorldEnvironment") as WorldEnvironment).environment


## Blended parameters at scroll position x (also used by the test).
static func settings_at(x: float) -> Dictionary:
	var to_midday := smoothstep(MORNING_TO_MIDDAY.x, MORNING_TO_MIDDAY.y, x)
	var to_sunset := smoothstep(MIDDAY_TO_SUNSET.x, MIDDAY_TO_SUNSET.y, x)
	var result := {}
	for key: String in MORNING:
		result[key] = _mix(_mix(MORNING[key], MIDDAY[key], to_midday), SUNSET[key], to_sunset)
	return result


static func _mix(a: Variant, b: Variant, t: float) -> Variant:
	return a.lerp(b, t) if a is Color or a is Vector3 else lerpf(a, b, t)


func _ready() -> void:
	_apply(_stage.get("distance"))


func _process(_delta: float) -> void:
	var x: float = _stage.get("distance")
	if absf(x - _last_x) > 0.01:
		_apply(x)

func apply_distance(progress: float) -> void:
	_apply(progress)


func _apply(x: float) -> void:
	_last_x = x
	var s := settings_at(x)
	_sun.light_color = s["sun_color"]
	_sun.light_energy = s["sun_energy"]
	_sun.rotation_degrees = s["sun_rotation"]
	_environment.ambient_light_color = s["ambient_color"]
	_environment.ambient_light_energy = s["ambient_energy"]
	_environment.fog_light_color = s["fog_color"]
	_environment.glow_intensity = s["glow_intensity"]
	BeeToonStyle.bee_rim_boost = s["bee_rim"]
	BeeToonStyle.set_outline_tint(s["outline_tint"])
	var decoration := _stage.get_node_or_null("VisualTarget01") as BeeLevel01VisualTarget
	if decoration != null:
		decoration.apply_ground_tint(s["ground_tint"])
	var sky := _environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = s["sky_top"]
	sky.sky_horizon_color = s["sky_horizon"]
	sky.ground_horizon_color = s["ground_horizon"]
	sky.ground_bottom_color = s["ground_bottom"]
