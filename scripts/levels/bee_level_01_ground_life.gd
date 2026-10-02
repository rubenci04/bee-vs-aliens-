class_name BeeLevel01GroundLife
extends Node3D
## POLISH-02 "life on the ground": candy wrappers, lollipops stuck in the soil, bottle caps, straws,
## little cans, big dry leaves, a few static snails and beetles. Decoration only: no collision, no
## gameplay nodes. One MultiMeshInstance3D per (type, 64 m chunk), per-instance colours, no textures.
## Readability rules (same as the Visual Target): everything sits behind the flight plane (z <= -3.4)
## except low flat litter in front; nothing taller than 0.35 m inside |z| < 2.5; no cyan (alien tech only).

const X_MIN := -10.0
const X_MAX := 385.0
const CHUNK := 64.0
const BASE_Y := -0.18 # Top of the mulch.
const MIDGROUND_Z := 2.5
const BACK_Z := Vector2(-8.8, -4.2)
const FRONT_Z := Vector2(1.7, 3.6)

## Few, vivid, never cyan: the alien tech keeps the only cool accent.
const VIVID: Array[Color] = [Color(0.9, 0.16, 0.2), Color(0.95, 0.38, 0.62), Color(0.98, 0.56, 0.12), Color(0.98, 0.84, 0.16), Color(0.62, 0.84, 0.2), Color(0.64, 0.34, 0.82)]
const LEAF_COLORS: Array[Color] = [Color(0.66, 0.46, 0.18), Color(0.55, 0.36, 0.14), Color(0.74, 0.55, 0.24)]
const SHELL_COLORS: Array[Color] = [Color(0.86, 0.52, 0.22), Color(0.8, 0.36, 0.3), Color(0.76, 0.62, 0.28)]
const STICK_COLOR: Array[Color] = [Color(0.93, 0.9, 0.82)]
const SNAIL_BODY: Array[Color] = [Color(0.72, 0.66, 0.52)]
const BEETLE_COLOR: Array[Color] = [Color(0.1, 0.2, 0.13)]
const LAY_X := Vector3(0.0, 0.0, PI * 0.5) # Elongated meshes are built along +Y; this lays them along X.

var batches: Array[MultiMeshInstance3D] = []
## Placements kept on the CPU side (the headless renderer cannot read MultiMesh data back): node, mesh, transforms, colours.
var records: Array[Dictionary] = []
var instance_total := 0
var _rng := RandomNumberGenerator.new()
var _material: StandardMaterial3D


func _ready() -> void:
	_rng.seed = 5150
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.roughness = 1.0
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var litter_wrapper := GardenLitterMeshes.wrapper()
	# [name, meshes, palettes, count, z ranges, scale range, mode, rest height per scale]
	_scatter("wrapper", [litter_wrapper], [VIVID], 78, [BACK_Z, FRONT_Z], Vector2(0.9, 1.35), "lay", 0.14)
	_scatter("cap", [GardenLitterMeshes.bottle_cap()], [VIVID], 56, [BACK_Z, FRONT_Z], Vector2(1.0, 1.7), "flat", 0.0)
	_scatter("straw", [GardenLitterMeshes.straw()], [VIVID], 42, [BACK_Z, FRONT_Z], Vector2(0.8, 1.3), "lay", 0.035)
	_scatter("can", [GardenLitterMeshes.small_can()], [VIVID], 30, [BACK_Z], Vector2(1.0, 1.4), "lay", 0.24)
	_scatter("lollipop", [GardenLitterMeshes.lollipop_stick(), GardenLitterMeshes.lollipop_head()], [STICK_COLOR, VIVID], 16, [Vector2(-11.0, -6.0)], Vector2(1.0, 1.6), "stand", 0.0)
	_scatter("leaf", [GardenLitterMeshes.dry_leaf()], [LEAF_COLORS], 64, [BACK_Z, FRONT_Z], Vector2(0.6, 1.0), "flat", 0.0)
	_scatter("snail", [GardenLitterMeshes.snail_body(), GardenLitterMeshes.snail_shell()], [SNAIL_BODY, SHELL_COLORS], 22, [BACK_Z], Vector2(1.0, 1.5), "flat", 0.0)
	_scatter("beetle", [GardenLitterMeshes.beetle()], [BEETLE_COLOR], 22, [BACK_Z, FRONT_Z], Vector2(0.9, 1.5), "flat", 0.0)


func _scatter(label: String, meshes: Array, palettes: Array, count: int, z_ranges: Array, scale_range: Vector2, mode: String, rest: float) -> void:
	# chunk -> {transforms: [], colors: [[per palette]]}
	var chunks: Dictionary = {}
	for i in count:
		var x := _rng.randf_range(X_MIN, X_MAX)
		var range_index := 0 if z_ranges.size() == 1 or _rng.randf() > 0.3 else 1
		var z_range: Vector2 = z_ranges[range_index]
		var z := _rng.randf_range(z_range.x, z_range.y)
		var s := _rng.randf_range(scale_range.x, scale_range.y)
		var yaw := _rng.randf() * TAU
		var transform := Transform3D.IDENTITY
		match mode:
			"lay":
				transform = Transform3D(Basis.from_euler(Vector3(0.0, yaw, PI * 0.5 + _rng.randf_range(-0.08, 0.08))) * Basis.from_scale(Vector3.ONE * s), Vector3(x, BASE_Y + rest * s, z))
			"stand":
				transform = Transform3D(Basis.from_euler(Vector3(0.0, _rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.22, 0.22))) * Basis.from_scale(Vector3.ONE * s), Vector3(x, BASE_Y - 0.05, z))
			_:
				transform = Transform3D(Basis.from_euler(Vector3(_rng.randf_range(-0.06, 0.06), yaw, _rng.randf_range(-0.06, 0.06))) * Basis.from_scale(Vector3.ONE * s), Vector3(x, BASE_Y + 0.02, z))
		var chunk := floori(x / CHUNK)
		if not chunks.has(chunk):
			chunks[chunk] = {"transforms": [], "colors": []}
		chunks[chunk]["transforms"].append(transform)
		var picks := []
		var palette_choice := _rng.randi()
		for palette: Array in palettes:
			picks.append(palette[palette_choice % palette.size()]) # Same index: stick/head and body/shell share the draw.
		chunks[chunk]["colors"].append(picks)
	for chunk in chunks:
		var data: Dictionary = chunks[chunk]
		for part in meshes.size():
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.use_colors = true
			multimesh.mesh = meshes[part]
			multimesh.instance_count = data["transforms"].size()
			for k in multimesh.instance_count:
				multimesh.set_instance_transform(k, data["transforms"][k])
				multimesh.set_instance_color(k, data["colors"][k][part])
			var node := MultiMeshInstance3D.new()
			node.name = "Life_%s%d_c%d" % [label, part, chunk]
			node.multimesh = multimesh
			node.material_override = _material
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(node)
			batches.append(node)
			records.append({"node": node, "mesh": meshes[part], "transforms": data["transforms"], "colors": data["colors"].map(func(c: Array): return c[part])})
		instance_total += data["transforms"].size()
