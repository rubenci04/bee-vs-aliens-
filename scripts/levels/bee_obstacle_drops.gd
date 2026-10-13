class_name BeeObstacleDrops
extends RefCounted
const POLLEN := preload("res://scenes/items/toon/pollen.tscn")
const HEALING := preload("res://scenes/items/toon/pollen_cluster.tscn") # LOTE 13: the honey jar became a pollen cluster.
const DROP_EVERY := 6 # LOTE 14: pollen is scarce (was 3)
const HEAL_EVERY := 18

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
	if item is BeePollenPickup and not item is BeePollenCluster:
		item.heal_amount = BeeLevel01Juice.POLLEN_INSTANT_HEAL
	item.global_position = Vector3(at.x, maxf(at.y, 1.0), 0.0)


## LOTE 12: a guaranteed pollen drop (garden mushrooms): `count` pickups spread around `at`, wired to the stage like the rock drops.
static func spawn_pollen(parent: Node, at: Vector3, count: int) -> void:
	var stage := parent
	while stage != null and not stage is BeeShmupStage:
		stage = stage.get_parent()
	var holder: Node = stage.get_node("Pollen") if stage != null else parent
	for i in count:
		var item := POLLEN.instantiate() as Node3D
		holder.add_child(item)
		if stage != null and item is BeePollenPickup:
			item.collected.connect(stage._on_pollen_collected)
		item.heal_amount = BeeLevel01Juice.POLLEN_INSTANT_HEAL
		item.global_position = Vector3(at.x + 0.6 * (float(i) - float(count - 1) * 0.5), maxf(at.y, 1.0), 0.0)
