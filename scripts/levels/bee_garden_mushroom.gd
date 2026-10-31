class_name BeeGardenMushroom
extends BreakableRock
## LOTE 12 · ETAPA 2 — garden mushroom: a FIXED, destructible, harmless object that drops POLLEN when it breaks (the cannon
## mushroom is the only one that shoots; it is an enemy family). It is a BreakableRock (checkpoint restore, hit flash, break
## VFX) that is NOT solid: Bee flies through it and only her shots break it. Models: the three Codex garden mushrooms.

## LOTE 14 · ETAPA 3.2: small screens - mushrooms and flowers are SIZE_SCALE of what they were (visual and collider).
const SIZE_SCALE := 0.8
const KINDS := {
	&"button": {"scene": "res://scenes/art_labs/garden_floor_v01/mushroom_button.tscn", "hp": 20, "scale": 1.6, "radius": 0.8},
	&"spotted": {"scene": "res://scenes/art_labs/garden_floor_v01/mushroom_spotted.tscn", "hp": 30, "scale": 1.4, "radius": 1.0},
	&"umbrella": {"scene": "res://scenes/art_labs/garden_floor_v01/mushroom_umbrella.tscn", "hp": 40, "scale": 1.2, "radius": 1.3},
	# LOTE 13 · ETAPA 1: destructible garden flowers (same rules as the mushrooms: fixed, not solid, they drop pollen).
	&"bellflower": {"scene": "res://scenes/art_labs/forest_floor_v01/garden_bellflower.tscn", "hp": 20, "scale": 1.9, "radius": 0.7},
	# Tanda T: two more pollen flowers, garden daisies built in code (same faceted face as the tall background daisies).
	&"flower_purple": {"daisy": Color(0.58, 0.42, 0.8), "hp": 20, "scale": 1.0, "radius": 0.7},
	&"flower_red": {"daisy": Color(0.88, 0.3, 0.36), "hp": 20, "scale": 1.0, "radius": 0.7},
}
const GROUND_Y := -0.1
const POLLEN_DROPS := 2 ## Flowers only.
const POLLEN_KINDS := [&"bellflower", &"flower_purple", &"flower_red"] # Tanda T: tres flores de polen.

var kind: StringName = &"button"


## Builds the body, collider and model at `x` (flight plane) and arms it. `hp_scale` follows the difficulty.
static func place(parent: Node3D, label: String, mushroom_kind: StringName, x: float) -> BeeGardenMushroom:
	var spec: Dictionary = KINDS[mushroom_kind]
	var node := BeeGardenMushroom.new()
	node.name = label
	node.kind = mushroom_kind
	node.collision_layer = 0 # Not solid.
	node.collision_mask = 0
	parent.add_child(node)
	node.global_position = Vector3(x, GROUND_Y, 0.0)
	var model := _build_daisy(spec["daisy"]) if spec.has("daisy") else (load(str(spec["scene"])) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * float(spec["scale"]) * SIZE_SCALE
	node.add_child(model)
	var radius := float(spec["radius"]) * SIZE_SCALE
	var shape := SphereShape3D.new()
	shape.radius = radius
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	collider.shape = shape
	# Tanda T: en las margaritas el blanco es la corola, arriba del tallo.
	collider.position = Vector3(0.0, preload("res://scripts/game/bee_flow_fix_settings.gd").DAISY_HEIGHT * SIZE_SCALE if spec.has("daisy") else radius * 0.9, 0.0)
	node.add_child(collider)
	node.arm(int(spec["hp"]), false)
	node.remove_from_group("breakable_rocks") # Own group: the rock tests and counts stay about rocks; the checkpoint restores both.
	node.add_to_group("garden_mushrooms")
	node.health.max_health = BeeGameSettings.scaled_hp(int(spec["hp"]))
	node.health.current_health = node.health.max_health
	return node


## Tanda T: a garden daisy built in code (stem + leaf + faceted petal face + core), toon with the prop outline.
## Sizes come from bee_flow_fix_settings (DAISY_*); the face looks at the camera (+Z) like the background daisies.
static func _build_daisy(petal: Color) -> Node3D:
	var fix := preload("res://scripts/game/bee_flow_fix_settings.gd")
	var root := Node3D.new()
	var stem := CylinderMesh.new()
	stem.radial_segments = 5
	stem.rings = 1
	stem.height = fix.DAISY_HEIGHT
	stem.bottom_radius = fix.DAISY_STEM_RADIUS
	stem.top_radius = fix.DAISY_STEM_RADIUS * 0.7
	_daisy_part(root, stem, fix.FLOWER_STEM_COLOR, Vector3(0, fix.DAISY_HEIGHT * 0.5, 0), Vector3.ZERO)
	var leaf := BeeLevel01VisualTarget._blade(fix.DAISY_HEIGHT * 0.35, 0.4, 0.6)
	_daisy_part(root, leaf, fix.FLOWER_STEM_COLOR, Vector3(0, fix.DAISY_HEIGHT * 0.25, 0), Vector3(0, 0, -0.4), true)
	var head := Vector3(0, fix.DAISY_HEIGHT, 0)
	_daisy_part(root, BeeLevel01VisualTarget._flower_face(fix.DAISY_RADIUS), petal, head, Vector3(-0.15, 0, 0))
	var core := SphereMesh.new()
	core.radial_segments = 6
	core.rings = 3
	core.radius = fix.DAISY_RADIUS * 0.3
	core.height = fix.DAISY_RADIUS * 0.3
	_daisy_part(root, core, fix.DAISY_CORE_COLOR, head + Vector3(0, 0, fix.DAISY_RADIUS * 0.1), Vector3.ZERO)
	return root


static func _daisy_part(root: Node3D, mesh: Mesh, color: Color, at: Vector3, rotation: Vector3, double_sided := false) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = BeeToonStyle.TOON_DOUBLE if double_sided else BeeToonStyle.TOON
	material.set_shader_parameter("albedo", color)
	if not double_sided:
		material.next_pass = BeeToonStyle.shared_outline(BeeToonStyle.OUTLINE_PROP)
	part.material_override = material
	part.position = at
	part.rotation = rotation
	root.add_child(part)


func _on_died() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	if kind in POLLEN_KINDS:
		BeeAudio.play(get_parent(), &"pollen", _centre())
		BeeCombatVFX.spawn(get_parent(), _centre(), &"pollen", Vector3.UP, 1.4)
		BeeObstacleDrops.spawn_pollen(get_parent(), _centre(), POLLEN_DROPS)
	else:
		BeeAudio.play(get_parent(), &"crate", _centre())
		BeeCombatVFX.spawn(get_parent(), _centre(), &"rock_break", Vector3.UP, 1.0)
	_remove()
	destroyed.emit(self)
