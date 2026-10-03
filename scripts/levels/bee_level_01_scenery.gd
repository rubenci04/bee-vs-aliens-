extends "res://scripts/bee_prototype/bee_garden_approved_scenery.gd"

const PURPLE_B = preload("res://assets/external/approved/nature/kenney/kenney_nature-kit/Models/GLTF format/flower_purpleB.glb")
const RED_A = preload("res://assets/external/approved/nature/kenney/kenney_nature-kit/Models/GLTF format/flower_redA.glb")
const YELLOW_A = preload("res://assets/external/approved/nature/kenney/kenney_nature-kit/Models/GLTF format/flower_yellowA.glb")
const YELLOW_B = preload("res://assets/external/approved/nature/kenney/kenney_nature-kit/Models/GLTF format/flower_yellowB.glb")
const GARDEN_ROSE = preload("res://scenes/decoration/recovered_garden_rose.tscn")
const FLOWER_VARIANTS = [FLOWER, PURPLE_B, RED_A, YELLOW_A, YELLOW_B, GARDEN_ROSE]
var flower_counts: Dictionary = {}
var _flower_index := 0

## Breakable flight rocks (ARCADE PRESSURE PASS 01). HP from Base DPS (10 per hit, 3.3 Hz): small = 4 shots (~0.9 s),
## medium = 7 shots (~1.8 s); both die to one Bomb (32) or two on the medium. The tall rock at X=205 stays structural.
const SMALL_ROCK_HP := 32
const MEDIUM_ROCK_HP := 64
const STRUCTURAL_ROCK := -1
const STRUCTURAL_ROCK_X := 205

## Approved garden props only. Z layers remain decorative outside the flight plane.
func _ready() -> void:
	var trees := [-8.0, 24.0, 72.0, 108.0, 158.0, 204.0, 247.0, 302.0, 346.0, 365.0]
	for i in trees.size():
		place(TREE, "Tree%d" % i, Vector3(trees[i], 0, -9.0 - float(i % 2)), 0.9 + 0.1 * float(i % 3), 0.25 * float(i))
	var flowers := [6.0, 18.0, 39.0, 63.0, 88.0, 116.0, 150.0, 178.0, 204.0, 233.0, 267.0, 306.0, 341.0, 360.0]
	for i in flowers.size():
		place(FLOWER, "Flower%d" % i, Vector3(flowers[i], 0, -4.5 - float(i % 2)), 15.0 + 2.0 * float(i % 4), 0.2 * float(i))
	var ferns := [2.0, 31.0, 47.0, 68.0, 98.0, 130.0, 164.0, 190.0, 220.0, 256.0, 288.0, 325.0, 352.0, 359.0]
	for i in ferns.size():
		place(FERN, "MidFern%d" % i, Vector3(ferns[i], 0, -3.8), 1.9 + 0.15 * float(i % 3), 0.3 * float(i))
	for i in 5:
		place(FERN, "FrontFern%d" % i, Vector3([14.0, 101.0, 170.0, 272.0, 334.0][i], 0, 2.8), 0.95, 0.2 * float(i))
	place(BOTTLE, "GiantBottle", Vector3(41, 0, 0), 10.337, 0.15)
	place(BOTTLE, "DistantBottle", Vector3(188, 0, -5), 9.5, -0.22)
	place(LOG, "FallenLog", Vector3(55, 0, 0), 4.799, 0)
	# Deterministic clusters add depth without moving decoration into Bee's plane.
	# Flowers dominate the garden, then become sparser around alien defenses.
	for x in range(4, 360, 7):
		if x > 235 and x % 3 == 0:
			continue
		place(FLOWER, "ClusterFlower%d" % x, Vector3(float(x) + float(x % 4) * 0.45, 0, -5.1 - float(x % 3) * 0.7), 11.5 + float(x % 5) * 1.6, float(x % 7) * 0.37)
	for x in range(3, 360, 5):
		place(FERN, "ClusterFern%d" % x, Vector3(float(x) + float(x % 3) * 0.35, 0, -3.2 - float(x % 4) * 0.22), 1.25 + float(x % 5) * 0.17, float(x % 9) * 0.28)
	for x in range(36, 360, 21):
		place(TREE, "ClusterTree%d" % x, Vector3(float(x), 0, -10.5 - float(x % 3)), 0.72 + float(x % 4) * 0.09, float(x % 5) * 0.5)
	for x in [26, 59, 91, 132, 174, 211, 258, 300, 339]:
		place(FERN, "NearFern%d" % x, Vector3(float(x), 0, 3.4), 0.65 + float(x % 3) * 0.13, float(x % 4) * 0.33)
	for x in [38, 70, 116, 146, 181, 221, 260, 296, 326, 352]:
		_place_rock("BackdropRock%d" % x, float(x), -4.0, Vector3(0.75 + float(x % 3) * 0.25, 0.55, 0.65), false)
	for x in [72, 96, 155, 205, 241, 283, 307, 345]:
		var tall: bool = x in [96, 205, 307]
		var radius: float = 1.15 if tall else 0.72
		_place_rock("FlightRock%d" % x, float(x), 0.0, Vector3(radius, radius, 0.65), true, STRUCTURAL_ROCK if x == STRUCTURAL_ROCK_X else (MEDIUM_ROCK_HP if tall else SMALL_ROCK_HP))
	# Uneven pockets rather than another evenly spaced row: 144 placements.
	# All foliage stays behind the flight plane; no new imported assets.
	var pockets := [9.0, 29.0, 46.0, 59.0, 87.0, 119.0, 150.0, 176.0, 203.0, 228.0, 250.0, 278.0, 302.0, 319.0, 338.0, 354.0]
	for p in pockets.size():
		for j in 5:
			var dx: float = [-2.8, -1.1, 0.4, 1.5, 3.7][j] + float(p % 3) * 0.23
			place(FLOWER, "PocketFlower%d_%d" % [p, j], Vector3(pockets[p] + dx, 0, -3.0 - float((p + j) % 4) * 0.65), 12.0 + float((p * 3 + j) % 6) * 1.3, float(j + p) * 0.51)
		for j in 3:
			place(FERN, "PocketFern%d_%d" % [p, j], Vector3(pockets[p] + float(j) * 1.7 - 1.6, 0, -5.2 - float(j) * 0.6), 1.6 + float((p + j) % 4) * 0.22, float(p + j) * 0.63)
		place(TREE, "PocketTree%d" % p, Vector3(pockets[p] + 2.0, 0, -13.0 - float(p % 3)), 0.8 + float(p % 4) * 0.11, float(p) * 0.71)

## Boulders rest on the ground: the visible rock fills the (unchanged) collider box and its base
## is buried a few centimetres. Solid rocks keep their original collider.
func _place_rock(label: String, x: float, z: float, radius: Vector3, solid: bool, hp := 0) -> void:
	var half := Vector3(radius.x * 0.85, radius.y * 0.95 + 0.05, radius.z * 0.85)
	var mesh := GardenProps.boulder(half, int(x))
	mesh.surface_set_material(0, GardenProps.flat(Color(0.39 + float(int(x) % 3) * 0.035, 0.41, 0.36)))
	var rock := MeshInstance3D.new()
	rock.name = label + "Mesh"
	rock.mesh = mesh
	BeeToonStyle.apply(rock, true)
	if not solid:
		add_child(rock)
		rock.position = Vector3(x, 0.0, z)
		return
	var body := BreakableRock.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	body.position = Vector3(x, radius.y, z)
	body.add_child(rock)
	rock.position = Vector3(0.0, -radius.y, 0.0)
	var shape := BoxShape3D.new()
	shape.size = radius * 1.7
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.name = "CollisionShape3D"
	body.add_child(collider)
	body.arm(maxi(hp, 1), hp == STRUCTURAL_ROCK)

func place(asset: PackedScene, label: String, floor_position: Vector3, factor: float, yaw: float) -> void:
	if asset == FLOWER:
		asset = _choose_flower(floor_position.x)
		var variation := clampf(factor / 16.0, 0.75, 1.25)
		factor = variation if asset == GARDEN_ROSE else variation * 16.0
		if asset == GARDEN_ROSE:
			yaw = sin(float(_flower_index)) * 0.15
		if asset == FERN:
			factor = variation * 1.5
		var key := asset.resource_path.get_file().get_basename()
		flower_counts[key] = int(flower_counts.get(key, 0)) + 1
	super.place(asset, label, floor_position, factor, yaw)
	var instance := get_node(label) as Node3D
	if floor_position.z > 0.0 and asset == FERN:
		# Retain foreground accents below Bee's lowest flight/hurtbox height.
		instance.scale.y *= 0.2
		instance.position.y *= 0.2
	if floor_position.z >= 0.0 or (asset not in [TREE, FERN] and asset not in FLOWER_VARIANTS):
		return
	var nearest_z := -INF
	for mesh: MeshInstance3D in instance.find_children("*", "MeshInstance3D", true, false):
		var world_bounds: AABB = mesh.global_transform * mesh.get_aabb()
		nearest_z = maxf(nearest_z, world_bounds.end.z)
	# A center behind Z=0 does not guarantee that broad leaves stay behind it.
	# Preserve the full mesh envelope behind the flight plane, including Walker.
	if nearest_z > -3.0:
		instance.position.z -= nearest_z + 3.0

func _choose_flower(x: float) -> PackedScene:
	var index := _flower_index
	_flower_index += 1
	# Coherent micro-zones, not random saturated recolors.
	if index % 3 == 0:
		return FLOWER
	if x < 45.0:
		return [YELLOW_A, YELLOW_B][index % 2]
	if x < 95.0:
		return [PURPLE_B, YELLOW_A][index % 2]
	if x < 165.0:
		return [RED_A, GARDEN_ROSE][index % 2]
	if x < 285.0:
		if index % 5 == 1:
			return FERN
		return [RED_A, YELLOW_B, PURPLE_B][index % 3]
	return [PURPLE_B, RED_A, YELLOW_B][index % 3]
