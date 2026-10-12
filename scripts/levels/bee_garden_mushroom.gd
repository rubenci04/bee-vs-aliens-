class_name BeeGardenMushroom
extends BreakableRock
## LOTE 12 · ETAPA 2 — garden mushroom: a FIXED, destructible, harmless object that drops POLLEN when it breaks (the cannon
## mushroom is the only one that shoots; it is an enemy family). It is a BreakableRock (checkpoint restore, hit flash, break
## VFX) that is NOT solid: Bee flies through it and only her shots break it. Models: the three Codex garden mushrooms.

const KINDS := {
	&"button": {"scene": "res://scenes/art_labs/garden_floor_v01/mushroom_button.tscn", "hp": 20, "scale": 1.6, "radius": 0.8},
	&"spotted": {"scene": "res://scenes/art_labs/garden_floor_v01/mushroom_spotted.tscn", "hp": 30, "scale": 1.4, "radius": 1.0},
	&"umbrella": {"scene": "res://scenes/art_labs/garden_floor_v01/mushroom_umbrella.tscn", "hp": 40, "scale": 1.2, "radius": 1.3},
}
const GROUND_Y := -0.1
const POLLEN_DROPS := 1

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
	var model := (load(str(spec["scene"])) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * float(spec["scale"])
	node.add_child(model)
	var radius := float(spec["radius"])
	var shape := SphereShape3D.new()
	shape.radius = radius
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	collider.shape = shape
	collider.position = Vector3(0.0, radius * 0.9, 0.0)
	node.add_child(collider)
	node.arm(int(spec["hp"]), false)
	node.remove_from_group("breakable_rocks") # Own group: the rock tests and counts stay about rocks; the checkpoint restores both.
	node.add_to_group("garden_mushrooms")
	node.health.max_health = BeeGameSettings.scaled_hp(int(spec["hp"]))
	node.health.current_health = node.health.max_health
	return node


func _on_died() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	BeeAudio.play(get_parent(), &"pollen", _centre())
	BeeCombatVFX.spawn(get_parent(), _centre(), &"pollen", Vector3.UP, 1.4)
	BeeObstacleDrops.spawn_pollen(get_parent(), _centre(), POLLEN_DROPS)
	_remove()
	destroyed.emit(self)
