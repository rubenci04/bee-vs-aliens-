class_name BeeLevel02LakeScenery
extends Node3D
## NOCHE 01 · ETAPA 4 — "Laguna" prototype scenery (presentation only, no collision except nothing: the water is not solid).
##   water   one large plane with Codex's stylised lake shader (future_lake_water.gdshader), the flight plane sits above it
##   banks   soft far shore mounds + bellflowers / ferns / pines on the far bank (fogged)
##   lake    lily pads (some with Quaternius frogs resting), cattail clumps, the hollow log, submerged roots — all behind
##           the flight plane (z <= -2.5) or flat on the water, so the corridor stays clean
## Layout is hand-placed for the ~120 m prototype.

const WATER_Y := -0.15
const LENGTH := 140.0
const WATER_SHADER := preload("res://assets/style/future_lake_water.gdshader")
const LILY := preload("res://scenes/art_labs/assets/lotus_lily_pad.tscn")
const CATTAILS := preload("res://scenes/art_labs/assets/cattails_cluster.tscn")
const LOG := preload("res://scenes/art_labs/forest_floor_v01/hollow_fallen_log.tscn")
const ROOTS := preload("res://scenes/art_labs/lake_fauna_v01/submerged_root_module.tscn")
const BELLFLOWER := preload("res://scenes/art_labs/forest_floor_v01/garden_bellflower.tscn")
const FERN := preload("res://scenes/art_labs/forest_floor_v01/forest_fern.tscn")
const PINE := preload("res://scenes/art_labs/pine_woods_v01/tall_pine.tscn")
const FROG := preload("res://assets/external/approved/fauna/quaternius/Easy Animated Enemy Pack - Jan 2019/FBX/Frog.fbx")

## [scene, x, z, scale, yaw]
const PROPS := [
	[LILY, 4.0, -3.0, 1.6, 0.2], [LILY, 13.0, -4.2, 2.0, 1.1], [LILY, 21.0, -2.8, 1.5, 2.0], [LILY, 34.0, -3.6, 2.2, 0.6],
	[LILY, 47.0, -2.9, 1.7, 2.6], [LILY, 58.0, -4.4, 2.1, 1.4], [LILY, 71.0, -3.1, 1.6, 0.3], [LILY, 86.0, -3.8, 2.3, 2.2],
	[LILY, 99.0, -2.8, 1.8, 1.0], [LILY, 110.0, -3.4, 3.2, 0.0], [LILY, 116.0, -3.0, 2.6, 0.7],
	[CATTAILS, 9.0, -6.0, 2.4, 0.3], [CATTAILS, 26.0, -7.0, 2.8, 1.4], [CATTAILS, 44.0, -6.4, 2.6, 0.8], [CATTAILS, 63.0, -7.2, 3.0, 2.1],
	[CATTAILS, 79.0, -6.2, 2.5, 0.5], [CATTAILS, 95.0, -7.0, 2.9, 1.7], [CATTAILS, 120.0, -6.6, 2.7, 0.9],
	[LOG, 54.0, -5.6, 2.6, 0.2], [ROOTS, 30.0, -3.2, 2.0, 0.4], [ROOTS, 89.0, -3.0, 2.2, 2.4],
	[BELLFLOWER, 17.0, -9.0, 2.0, 0.4], [BELLFLOWER, 67.0, -9.5, 2.2, 1.2], [FERN, 40.0, -10.0, 2.6, 0.6], [FERN, 104.0, -9.6, 2.8, 1.8],
	[PINE, 22.0, -26.0, 7.0, 0.4], [PINE, 60.0, -28.0, 8.0, 1.6], [PINE, 98.0, -27.0, 7.5, 0.8], [PINE, 128.0, -26.0, 7.0, 2.3],
]
const FROGS := [[13.0, -4.2], [58.0, -4.4], [99.0, -2.8]]

var water: MeshInstance3D
var props: Array[Node3D] = []


func _ready() -> void:
	_build_water()
	_build_banks()
	for entry in PROPS:
		var item := (entry[0] as PackedScene).instantiate() as Node3D
		item.name = "LakeProp%d" % props.size()
		add_child(item)
		item.position = Vector3(float(entry[1]), WATER_Y - 0.02, float(entry[2]))
		item.scale = Vector3.ONE * float(entry[3])
		item.rotation.y = float(entry[4])
		props.append(item)
	for spot in FROGS:
		var frog := FROG.instantiate() as Node3D
		frog.name = "PadFrog"
		frog.scale = Vector3.ONE * 0.35
		frog.rotation.y = -PI * 0.5
		add_child(frog)
		frog.position = Vector3(float(spot[0]), WATER_Y + 0.25, float(spot[1]))
		BeeToonStyle.apply(frog, true, BeeToonStyle.OUTLINE_PROP)
		props.append(frog)


func _build_water() -> void:
	water = MeshInstance3D.new()
	water.name = "Water"
	var plane := PlaneMesh.new()
	plane.size = Vector2(LENGTH + 60.0, 90.0)
	plane.subdivide_width = 1
	plane.subdivide_depth = 1
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	plane.material = material
	water.mesh = plane
	water.position = Vector3(LENGTH * 0.5, WATER_Y, -38.0)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


func _build_banks() -> void:
	var colours := [Color(0.38, 0.47, 0.27), Color(0.32, 0.41, 0.24), Color(0.45, 0.5, 0.3)]
	var x := -10.0
	var i := 0
	while x < LENGTH + 20.0:
		var mound := MeshInstance3D.new()
		mound.name = "Bank%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 1.0
		sphere.is_hemisphere = true
		sphere.radial_segments = 12
		sphere.rings = 5
		sphere.material = GardenProps.flat(colours[i % colours.size()])
		mound.mesh = sphere
		mound.scale = Vector3(14.0 + 4.0 * float(i % 3), 5.0 + 2.0 * float((i + 1) % 3), 6.0)
		mound.position = Vector3(x, WATER_Y - 0.1, -34.0 - 3.0 * float(i % 2))
		add_child(mound)
		x += 16.0
		i += 1
	BeeToonStyle.apply(self, false)
