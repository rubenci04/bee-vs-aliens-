class_name BeeLevel01Readability
extends Node
## NOCHE 01 · ETAPA 3 — readability pass (presentation only), run once the decoration is built:
##   corridor  decoration that rises into the flight band (CORRIDOR_LOW_Y..CORRIDOR_TOP_Y) closer than CORRIDOR_Z to the flight
##             plane is pushed back behind CORRIDOR_Z (same X, same size): Codex props and the domestic-garden props. The
##             procedural tall grass does the same in BeeLevel01VisualTarget (CORRIDOR_CLEAR_Z). Low ground litter stays.
##   contrast  actors keep near-black outlines in every light (BeeToonStyle ACTOR_OUTLINE_TINT), so Bee and the enemies read
##             against the warm day, the golden hour and the violet sunset; implant glow is raised (AssetFauna IMPLANT_GLOW).
## `intruders()` lists what still invades the corridor (tests, report).

const CORRIDOR_Z := -5.0
const CORRIDOR_LOW_Y := 1.6
const CORRIDOR_TOP_Y := 6.4
const MARGIN := 0.2

var stage: Node3D
var moved: Array[Node3D] = []


func _ready() -> void:
	stage = get_parent() as Node3D
	call_deferred("_clear_corridor")


func candidates() -> Array[Node3D]:
	var list: Array[Node3D] = []
	var dressing := stage.get_node_or_null("AssetDressing") as BeeLevel01AssetDressing
	if dressing != null:
		list.append_array(dressing.litter)
	for node in stage.get_children():
		if node is BeeLevel01DomesticGarden:
			for prop in (node as BeeLevel01DomesticGarden).props:
				if is_instance_valid(prop):
					list.append(prop)
	return list


static func world_bounds(node: Node3D) -> AABB:
	var first := true
	var box := AABB()
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


static func invades(box: AABB) -> bool:
	return box.size != Vector3.ZERO and box.end.z > CORRIDOR_Z and box.end.y > CORRIDOR_LOW_Y and box.position.y < CORRIDOR_TOP_Y


func intruders() -> Array[Node3D]:
	var list: Array[Node3D] = []
	for node in candidates():
		if node.is_visible_in_tree() and invades(world_bounds(node)):
			list.append(node)
	return list


func _clear_corridor() -> void:
	for node in candidates():
		if not node.is_visible_in_tree():
			continue
		var box := world_bounds(node)
		if invades(box):
			node.global_position.z -= box.end.z - CORRIDOR_Z + MARGIN
			moved.append(node)
