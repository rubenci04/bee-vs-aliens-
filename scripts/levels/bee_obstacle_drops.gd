class_name BeeObstacleDrops
extends RefCounted
const POLLEN := preload("res://scenes/items/toon/pollen.tscn")
const HEALING := preload("res://scenes/items/toon/healing.tscn")
const DROP_EVERY := 3
const HEAL_EVERY := 9

static func spawn(parent: Node, at: Vector3, seed_value: int) -> void:
	# Authored deterministic rewards; checkpoint restoration never calls this.
	if seed_value % DROP_EVERY != 0:
		return
	var stage := parent
	while stage != null and not stage is BeeShmupStage:
		stage = stage.get_parent()
	if stage != null:
		parent = stage.get_node("Powerups" if seed_value % HEAL_EVERY == 0 else "Pollen")
	var item := (HEALING if seed_value % HEAL_EVERY == 0 else POLLEN).instantiate() as Node3D
	parent.add_child(item)
	if stage != null and item is BeePollenPickup:
		item.collected.connect(stage._on_pollen_collected)
	item.global_position = Vector3(at.x, maxf(at.y, 1.0), 0.0)
