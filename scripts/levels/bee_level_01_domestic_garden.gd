class_name BeeLevel01DomesticGarden
extends Node3D
## GARDEN IDENTITY 04 — "a domestic giant garden seen by a bee". A small curated set of CC0 household / garden props
## (Tiny Treats House Plants, KayKit Forest Nature, Kenney Food Kit; see assets/external/ASSET_PROVENANCE.md) staged
## as SCALE COMPOSITIONS along the five acts, instead of an asset dump:
##   ACT 1 natural garden, one isolated human object      (KayKit bushes/grass/rocks, the fallen terracotta pot)
##   ACT 2 lusher plants and props                         (the monstera leaf tunnel, the giant watering can pouring)
##   ACT 3 human territory, household objects everywhere   (the trowel stuck in the soil, stacked pots, picnic leftovers)
##   ACT 4 strong colour + alien contamination             (succulents and cacti, a pot taken over by alien nodes)
##   ACT 5 alien escalation + UFO                          (toppled pots, a knocked-over can)
## Presentation only: no collision, no gameplay nodes. Readability rules of the Visual Target apply and are tested:
## every prop's whole mesh stays behind the flight plane (z <= -3) except foreground accents, which project below
## the playfield (BeeLevel01VisualTarget.foreground_height_limit); nothing taller than 0.35 m in |z| < 2.5.
## Style C per profile (BeeToonStyle.apply_profile): closed props get toon + thin prop outline, thin foliage gets
## toon without outline (an inverted hull would paint its back faces black).

const GROUND_Y := -0.2
const BEHIND_Z := -3.0
const TT := "res://assets/external/approved/garden/tiny_treats/House Plants 1.0/gltf/"
const KF := "res://assets/external/approved/nature/kaykit/Forest Nature Pack 1.0/gltf/"
const KFD := "res://assets/external/approved/props/kenney/kenney_food-kit/Models/GLB format/"
const MODELS := {
	"pot_A": TT + "pot_A_large.gltf", "pot_C": TT + "pot_C_large.gltf", "pots_stacked": TT + "pots_stacked.gltf", "saucer": TT + "saucer_A_large.gltf",
	"can_yellow": TT + "watering_can_B.gltf", "can_grey": TT + "watering_can_A.gltf", "shovel": TT + "shovel.gltf",
	"leaf_A": TT + "monstera_leaf_large_A.gltf", "leaf_B": TT + "monstera_leaf_large_B.gltf", "leaf_C": TT + "monstera_leaf_large_C.gltf", "leaf_D": TT + "monstera_leaf_large_D.gltf",
	"monstera": TT + "monstera_plant_large_potted.gltf", "yucca": TT + "yucca_plant_large.gltf", "sansevieria": TT + "sansevieria_plant_large.gltf",
	"vine": TT + "pothos_vine_large_A.gltf", "succulents": TT + "succulent_plant_pot_large.gltf", "cacti": TT + "cacti_plant_pot_large.gltf",
	"bush_1": KF + "Bush_1_A_Color1.gltf", "bush_2": KF + "Bush_2_A_Color1.gltf", "bush_4": KF + "Bush_4_A_Color1.gltf",
	"grass_1": KF + "Grass_1_A_Color1.gltf", "grass_2": KF + "Grass_2_A_Color1.gltf", "rock_1": KF + "Rock_1_A_Color1.gltf", "rock_3": KF + "Rock_3_A_Color1.gltf",
	"apple": KFD + "apple-half.glb", "cup": KFD + "cup-coffee.glb", "wrapper": KFD + "candy-bar-wrapper.glb", "stick": KFD + "popsicle-stick.glb",
}
const FOLIAGE := ["leaf_A", "leaf_B", "leaf_C", "leaf_D", "vine", "grass_1", "grass_2"]
## [model, x, z, size factor, rotation degrees (x, y, z), bury (m), composition id]. Acts follow BeeLevel01Controller.ACT_STARTS.
const PLACEMENTS := [
	# ACT 1 — natural garden (KayKit greens, muted), one isolated human object.
	["bush_2", 7.0, -4.4, 3.4, Vector3(0, 20, 0), 0.1, ""], ["grass_2", 11.5, -3.8, 2.6, Vector3(0, -10, 0), 0.0, ""],
	["bush_4", 16.0, -5.8, 4.2, Vector3(0, 40, 0), 0.1, ""], ["rock_3", 19.5, -4.0, 1.5, Vector3(0, 30, 0), 0.25, ""],
	["pot_A", 27.0, -8.4, 3.5, Vector3(0, 55, 90), 0.0, "A1_fallen_pot"], ["vine", 24.6, -6.0, 3.0, Vector3(0, 70, -20), 0.0, "A1_fallen_pot"],
	["grass_1", 30.5, -3.6, 3.0, Vector3(0, 15, 0), 0.0, ""], ["bush_1", 45.0, -4.6, 7.0, Vector3(0, -30, 0), 0.1, ""],
	["grass_2", 50.0, -4.2, 2.8, Vector3(0, 60, 0), 0.0, ""], ["bush_2", 61.0, -5.4, 3.8, Vector3(0, -50, 0), 0.1, ""],
	["rock_1", 64.5, -3.8, 1.8, Vector3(0, 10, 0), 0.2, ""],
	# ACT 2 — lusher: the monstera leaf tunnel (98-110) and the giant watering can pouring (126).
	["yucca", 80.0, -9.5, 3.6, Vector3(0, 30, 0), 0.0, ""], ["grass_1", 89.0, -3.7, 3.2, Vector3(0, -40, 0), 0.0, ""],
	["leaf_C", 97.5, -4.4, 3.1, Vector3(-14, 20, -22), 0.2, "A2_leaf_tunnel"], ["leaf_D", 101.5, -5.6, 2.9, Vector3(-10, -15, -12), 0.2, "A2_leaf_tunnel"],
	["leaf_B", 106.0, -4.8, 3.4, Vector3(-12, 160, 16), 0.2, "A2_leaf_tunnel"], ["leaf_C", 110.5, -5.4, 3.0, Vector3(-16, 200, 24), 0.2, "A2_leaf_tunnel"],
	["sansevieria", 116.5, -8.2, 3.0, Vector3(0, 10, 0), 0.0, ""], ["bush_4", 120.0, -4.4, 4.4, Vector3(0, 0, 0), 0.1, ""],
	["can_yellow", 127.0, -13.5, 9.0, Vector3(0, -150, -18), 0.0, "A2_watering_can"],
	["bush_2", 134.0, -4.6, 4.0, Vector3(0, 35, 0), 0.1, ""],
	# ACT 3 — human territory: the trowel by the giant's footprints, stacked pots, picnic leftovers.
	["shovel", 152.0, -4.8, 9.0, Vector3(6, 20, 14), 1.4, "A3_trowel"], ["pots_stacked", 161.0, -8.2, 7.0, Vector3(0, 30, 0), 0.0, "A3_pots"],
	["saucer", 165.5, -5.6, 3.6, Vector3(0, 0, 0), 0.05, "A3_pots"], ["wrapper", 171.0, -3.8, 12.0, Vector3(0, 25, 0), 0.0, "A3_picnic"],
	["apple", 174.5, -4.4, 14.0, Vector3(0, -70, 0), 0.0, "A3_picnic"], ["cup", 179.0, -6.8, 13.0, Vector3(0, 25, 90), 0.0, "A3_picnic"],
	["stick", 182.5, -4.0, 13.0, Vector3(90, 30, 0), 0.0, "A3_picnic"],
	# ACT 4 — after the checkpoint: strong colour, then the alien contamination.
	["monstera", 201.0, -15.5, 3.4, Vector3(0, -20, 0), 0.0, ""], ["succulents", 214.0, -6.4, 3.0, Vector3(0, 40, 0), 0.1, ""],
	["pot_C", 233.0, -6.6, 3.6, Vector3(0, 15, 0), 0.0, "A4_alien_pot"], ["sansevieria", 233.0, -6.6, 2.0, Vector3(0, 0, 0), -2.9, "A4_alien_pot"],
	["bush_4", 244.0, -4.6, 4.0, Vector3(0, 20, 0), 0.1, ""], ["cacti", 284.0, -8.0, 3.2, Vector3(0, -30, 0), 0.1, ""],
	["can_grey", 312.0, -9.5, 7.0, Vector3(0, 30, 80), 0.0, "A4_knocked_can"], ["rock_3", 322.0, -4.2, 1.6, Vector3(0, 70, 0), 0.25, ""],
	# ACT 5 — the arena before the UFO: toppled pots, on the LEFT of the frame (the boss flies in the right half).
	["pots_stacked", 341.0, -14.0, 5.0, Vector3(0, 10, 82), 0.0, "A5_toppled_pots"], ["saucer", 343.0, -7.0, 3.2, Vector3(14, 0, 0), 0.4, "A5_toppled_pots"],
]
## Colour progression natural -> domestic -> human -> alien: the props of the early acts are a little quieter, so the
## approved colour jump after the checkpoint stays the strongest moment (multiplies the albedo; by act 1..5).
const ACT_TINT := [Color(0.84, 0.87, 0.82), Color(0.93, 0.95, 0.91), Color(1.0, 1.0, 1.0), Color(1.04, 1.0, 0.98), Color(0.96, 0.94, 0.98)]
## KayKit greens are a saturated lime: pulled towards the olive of the procedural grass so they never read as neon.
const MODEL_TINT := {"bush_1": Color(0.84, 0.86, 0.7), "bush_2": Color(0.84, 0.86, 0.7), "bush_4": Color(0.84, 0.86, 0.7), "grass_1": Color(0.86, 0.88, 0.72), "grass_2": Color(0.86, 0.88, 0.72)}
## Foreground accents (projected under the playfield): [model, x, z, size factor, yaw].
const FOREGROUND := [["grass_2", 18.0, 4.9, 1.0, 20.0], ["leaf_A", 100.0, 5.4, 1.0, 160.0], ["leaf_A", 108.5, 5.6, 1.0, 30.0],
		["grass_1", 147.0, 5.0, 1.0, -30.0], ["grass_2", 238.0, 5.2, 1.0, 50.0]]

var props: Array[Node3D] = []
var foreground_nodes: Array[Node3D] = []
var compositions: Dictionary = {} # id -> Array[Node3D]
var drips: CPUParticles3D
var _leaves: Array[Node3D] = []
var _t := 0.0
var _scenes: Dictionary = {}
var _tints: Dictionary = {}


func _ready() -> void:
	for entry in PLACEMENTS:
		var node := _place(entry[0], float(entry[1]), float(entry[2]), float(entry[3]), entry[4], float(entry[5]))
		_keep_behind(node)
		if entry[0] == "can_yellow":
			preload("res://scripts/game/bee_hero_look_settings.gd").tone_down_yellow(node) # Tanda S: el amarillo fuerte queda para Bee.
		props.append(node)
		if str(entry[6]) != "":
			if not compositions.has(entry[6]):
				compositions[entry[6]] = []
			compositions[entry[6]].append(node)
		if str(entry[6]) == "A2_leaf_tunnel":
			_leaves.append(node)
	for entry in FOREGROUND:
		var node := _place(entry[0], float(entry[1]), float(entry[2]), float(entry[3]), Vector3(0, float(entry[4]), 0), 0.0)
		_fit_under_playfield(node)
		foreground_nodes.append(node)
	_build_watering_can_drips()
	if not (BeeLevel01AlienEscalation.GARDEN_ONLY and BeeLevel01Controller.roster_only):
		_build_alien_pot() # LOTE 13 · ETAPA 1: no alien-contaminated pot in the house garden.


func _scene(key: String) -> PackedScene:
	if not _scenes.has(key):
		_scenes[key] = load(MODELS[key]) as PackedScene
	return _scenes[key]


func _place(key: String, x: float, z: float, factor: float, rotation_degrees_xyz: Vector3, bury: float) -> Node3D:
	var node := _scene(key).instantiate() as Node3D
	node.name = "%s_%d" % [key, props.size() + foreground_nodes.size()]
	add_child(node)
	node.scale = Vector3.ONE * factor
	node.rotation_degrees = rotation_degrees_xyz
	node.position = Vector3(x, 0.0, z)
	# Rest the prop on the mulch: its lowest point at GROUND_Y - bury.
	var box := bounds(node)
	node.position.y += GROUND_Y - bury - box.position.y
	BeeToonStyle.apply_profile(node, &"foliage" if key in FOLIAGE else &"prop")
	var tint: Color = ACT_TINT[act_at(x) - 1] * MODEL_TINT.get(key, Color.WHITE)
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if key in FOLIAGE else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if tint != Color.WHITE:
			for surface in mesh.mesh.get_surface_count():
				mesh.set_surface_override_material(surface, _tinted(mesh.get_surface_override_material(surface), tint))
	return node


## Act (1..5) of a level X, from the director's act starts.
static func act_at(x: float) -> int:
	var act := 1
	for i in BeeLevel01Controller.ACT_STARTS.size():
		if x >= float(BeeLevel01Controller.ACT_STARTS[i]):
			act = i + 1
	return act


## Shared per (material, tint): the toon albedo is multiplied, outline/next pass kept.
func _tinted(material: Material, tint: Color) -> Material:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return material
	var key := "%d|%s" % [material.get_instance_id(), tint.to_html()]
	if not _tints.has(key):
		var copy := shader_material.duplicate() as ShaderMaterial
		var albedo: Color = shader_material.get_shader_parameter("albedo")
		copy.set_shader_parameter("albedo", Color(albedo.r * tint.r, albedo.g * tint.g, albedo.b * tint.b, albedo.a))
		_tints[key] = copy
	return _tints[key]


## The whole mesh envelope stays behind the flight plane (not only the pivot): leaning leaves are pushed back.
func _keep_behind(node: Node3D) -> void:
	var box := bounds(node)
	if box.end.z > BEHIND_Z:
		node.position.z -= box.end.z - BEHIND_Z


## Foreground accents: lowered until every vertex projects at/below the bottom of the playfield.
func _fit_under_playfield(node: Node3D) -> void:
	var excess := 0.0
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var xf := mesh.global_transform
		for v: Vector3 in mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var p := xf * v
			excess = maxf(excess, p.y - BeeLevel01VisualTarget.foreground_height_limit(p.z))
	node.position.y -= excess + 0.02


static func bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## Animated moment: slow drops falling from the giant watering can's spout.
func _build_watering_can_drips() -> void:
	var can: Node3D = compositions["A2_watering_can"][0]
	var box := bounds(can)
	drips = CPUParticles3D.new()
	drips.name = "WateringCanDrips"
	drips.amount = 14
	drips.lifetime = 1.6
	drips.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	drips.emission_box_extents = Vector3(0.35, 0.05, 0.25)
	drips.direction = Vector3.DOWN
	drips.spread = 4.0
	drips.gravity = Vector3(0, -6.0, 0)
	drips.initial_velocity_min = 0.2
	drips.initial_velocity_max = 0.6
	var drop := SphereMesh.new()
	drop.radius = 0.09
	drop.height = 0.24
	drop.radial_segments = 6
	drop.rings = 3
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.72, 0.88, 0.98, 0.8)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = water
	drips.mesh = drop
	add_child(drips)
	# The can lies spout-down towards -X (yaw -150): drops fall from the low end of its bounds.
	drips.position = Vector3(box.position.x + 0.8, box.position.y + box.size.y * 0.35, box.get_center().z)


## ACT 4: the alien invasion reaches the household objects: dark plates and pulsing cyan nodes on a pot rim.
func _build_alien_pot() -> void:
	var pot: Node3D = compositions["A4_alien_pot"][0]
	var box := bounds(pot)
	var shell := StandardMaterial3D.new()
	shell.albedo_color = BeeAlienPalette.SHELL
	var glow := StandardMaterial3D.new()
	glow.albedo_color = BeeAlienPalette.CYAN
	glow.emission_enabled = true
	glow.emission = BeeAlienPalette.CYAN
	glow.emission_energy_multiplier = 1.2
	var violet := StandardMaterial3D.new()
	violet.albedo_color = BeeAlienPalette.VIOLET.darkened(0.4) # A rim stain, not a neon ring.
	var root := Node3D.new()
	root.name = "AlienGrowth"
	add_child(root)
	var centre := box.get_center()
	var top := box.end.y
	var radius := box.size.x * 0.48
	for i in 5:
		var a := -0.4 + i * 0.6
		var plate := MeshInstance3D.new()
		var plate_mesh := BoxMesh.new()
		plate_mesh.size = Vector3(0.9, 0.42, 0.18)
		plate_mesh.material = shell
		plate.mesh = plate_mesh
		plate.position = Vector3(centre.x + cos(a) * radius, top - 0.15 - 0.4 * (i % 2), centre.z + sin(a) * radius * 0.6 + radius * 0.4)
		plate.rotation = Vector3(0.2, -a, 0.15 * (i - 2))
		root.add_child(plate)
		if i % 2 == 0:
			var node := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.22
			sphere.height = 0.44
			sphere.radial_segments = 10
			sphere.rings = 5
			sphere.material = glow
			node.mesh = sphere
			node.position = plate.position + Vector3(0, 0.35, 0.2)
			root.add_child(node)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.92
	torus.outer_radius = radius * 1.02
	torus.rings = 24
	torus.ring_segments = 6
	torus.material = violet
	ring.mesh = torus
	ring.position = Vector3(centre.x, top - 0.05, centre.z)
	root.add_child(ring)
	BeeToonStyle.apply(root, true, BeeToonStyle.OUTLINE_PROP)
	compositions["A4_alien_pot"].append(root)


func _process(delta: float) -> void:
	_t += delta
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	# Giant leaves breathe a little while on screen (nothing processes far from the camera).
	for i in _leaves.size():
		var leaf := _leaves[i]
		if absf(leaf.global_position.x - camera.global_position.x) < 16.0:
			leaf.rotation.z = deg_to_rad(PLACEMENTS_LEAF_ROLL[i]) + sin(_t * 0.7 + i * 1.3) * 0.025
	drips.emitting = absf(drips.global_position.x - camera.global_position.x) < 18.0


const PLACEMENTS_LEAF_ROLL := [-22.0, -12.0, 16.0, 24.0]
