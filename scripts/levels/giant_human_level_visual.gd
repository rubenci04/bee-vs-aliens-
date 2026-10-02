extends GiantHumanCrossingHazard

## GIANT HUMAN CORRIDOR FIX 01. Each damage shape is the convex hull of the skinned vertices of
## one body part, projected from the camera onto Bee's plane (Z=0): what the player sees there is
## what hurts. The hull is shrunk by PLAYER_MARGIN (contact is slightly forgiving) and legs never
## reach into the central column (SAFE_HALF_WIDTH), independent of the Run stride.
## Only the Torso hull (pelvis and up) and the legs/feet damage; arms and head stay harmless.
const SAFE_HALF_WIDTH := 1.2
const PLAYER_MARGIN := 0.12
const SLAB_HALF_DEPTH := 0.5 # Bee lives at Z=0; the projected silhouette is a thin slab around it.
const MIN_AREA := 0.04
const PARTS := {
	"LeftThigh": {"bones": ["thigh_L"], "corridor": true},
	"LeftLeg": {"bones": ["calf_L", "foot_L"], "corridor": true},
	"RightThigh": {"bones": ["thigh_R"], "corridor": true},
	"RightLeg": {"bones": ["calf_R", "foot_R"], "corridor": true},
	"Torso": {"bones": ["pelvis", "spine", "chest", "neck", "head"], "corridor": false},
}
@onready var skeleton: Skeleton3D = $VisualRoot/Hipster/Rig/Skeleton3D

var _skins: Array[Skin] = []
var _samples: Dictionary = {} # part -> Array of [skin index, bind-space vertex, bind indices, weights]

# The reused Hipster model has bright white SoleL/SoleR slabs. At 6x scale
# they read as rectangular plates beneath the boots. Boots already reach Y=0,
# so hide only these level-instance slabs; keep GLB, rig, Run and hitboxes intact.
func _ready() -> void:
	super._ready()
	for name in ["SoleL", "SoleR"]:
		var sole := get_node_or_null("VisualRoot/Hipster/Rig/Skeleton3D/" + name) as MeshInstance3D
		if sole == null:
			push_error("Level 01 human sole missing: " + name)
			continue
		sole.hide()
	# Shapes are rebuilt every physics frame from the animated body.
	for part in PARTS:
		var collider := $ContactHitbox.get_node_or_null(part) as CollisionShape3D
		if collider == null:
			collider = CollisionShape3D.new()
			collider.name = part
			$ContactHitbox.add_child(collider)
		var placeholder := ConvexPolygonShape3D.new()
		placeholder.points = PackedVector3Array([Vector3(-0.1, -0.1, -0.1), Vector3(0.1, -0.1, -0.1), Vector3(0.1, 0.1, -0.1), Vector3(-0.1, 0.1, -0.1),
				Vector3(-0.1, -0.1, 0.1), Vector3(0.1, -0.1, 0.1), Vector3(0.1, 0.1, 0.1), Vector3(-0.1, 0.1, 0.1)]) # Valid hull; real points arrive per frame.
		collider.shape = placeholder
		collider.disabled = true
	_collect_samples()

func _collect_samples() -> void:
	var bone_part := {}
	for part in PARTS:
		_samples[part] = []
		for bone in PARTS[part]["bones"]:
			bone_part[bone] = part
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", false, false):
		if not mesh.visible or mesh.skin == null:
			continue
		var skin_index := _skins.size()
		_skins.append(mesh.skin)
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var stride := bones.size() / vertices.size()
			for i in vertices.size():
				var dominant := 0
				for k in stride:
					if weights[i * stride + k] > weights[i * stride + dominant]:
						dominant = k
				var name := skeleton.get_bone_name(_bind_bone(mesh.skin, bones[i * stride + dominant]))
				if not bone_part.has(name):
					continue
				var indices := PackedInt32Array()
				var used := PackedFloat32Array()
				for k in stride:
					if weights[i * stride + k] > 0.0:
						indices.append(bones[i * stride + k])
						used.append(weights[i * stride + k])
				_samples[bone_part[name]].append([skin_index, vertices[i], indices, used])

func _bind_bone(skin: Skin, bind: int) -> int:
	var bone := skin.get_bind_bone(bind)
	return bone if bone >= 0 else skeleton.find_bone(skin.get_bind_name(bind))

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_phase != Phase.CROSSING:
		return
	var palettes: Array = []
	for skin in _skins:
		var palette: Array[Transform3D] = []
		for bind in skin.get_bind_count():
			palette.append(skeleton.global_transform * skeleton.get_bone_global_pose(_bind_bone(skin, bind)) * skin.get_bind_pose(bind))
		palettes.append(palette)
	var camera_position := _camera.global_position
	for part in PARTS:
		_apply(part, _envelope(part, palettes, camera_position))

func _envelope(part: String, palettes: Array, camera_position: Vector3) -> PackedVector2Array:
	var points := PackedVector2Array()
	for sample: Array in _samples[part]:
		var palette: Array = palettes[sample[0]]
		var indices: PackedInt32Array = sample[2]
		var weights: PackedFloat32Array = sample[3]
		var skinned := Vector3.ZERO
		for k in indices.size():
			skinned += (palette[indices[k]] * (sample[1] as Vector3)) * weights[k]
		# Central projection through the camera onto Z=0 (independent of camera pitch).
		var scale := camera_position.z / maxf(camera_position.z - skinned.z, 0.5)
		points.append(Vector2(camera_position.x + (skinned.x - camera_position.x) * scale - global_position.x,
				camera_position.y + (skinned.y - camera_position.y) * scale))
	var hull := Geometry2D.convex_hull(points)
	if hull.size() < 4:
		return PackedVector2Array()
	hull.remove_at(hull.size() - 1) # convex_hull repeats the first point.
	var best := _largest(Geometry2D.offset_polygon(hull, -PLAYER_MARGIN, Geometry2D.JOIN_MITER))
	if not bool(PARTS[part]["corridor"]) or best.is_empty():
		return best
	var outside_left := PackedVector2Array([Vector2(-100, -10), Vector2(-SAFE_HALF_WIDTH, -10), Vector2(-SAFE_HALF_WIDTH, 20), Vector2(-100, 20)])
	var outside_right := PackedVector2Array([Vector2(SAFE_HALF_WIDTH, -10), Vector2(100, -10), Vector2(100, 20), Vector2(SAFE_HALF_WIDTH, 20)])
	var pieces: Array = Geometry2D.intersect_polygons(best, outside_left) + Geometry2D.intersect_polygons(best, outside_right)
	return _largest(pieces)

func _apply(part: String, polygon: PackedVector2Array) -> void:
	var collider: CollisionShape3D = $ContactHitbox.get_node(part)
	if polygon.size() < 3 or _area(polygon) < MIN_AREA:
		collider.set_deferred("disabled", true)
		return
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	center /= float(polygon.size())
	var shape_points := PackedVector3Array()
	for point in polygon:
		shape_points.append(Vector3(point.x - center.x, point.y - center.y, -SLAB_HALF_DEPTH))
		shape_points.append(Vector3(point.x - center.x, point.y - center.y, SLAB_HALF_DEPTH))
	(collider.shape as ConvexPolygonShape3D).points = shape_points
	collider.position = Vector3(center.x, center.y, 0.0)
	collider.set_deferred("disabled", false)

static func _area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return absf(total) * 0.5

static func _largest(polygons: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_area := 0.0
	for polygon: PackedVector2Array in polygons:
		var area := _area(polygon)
		if area > best_area:
			best = polygon
			best_area = area
	return best
