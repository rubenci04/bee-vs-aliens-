extends "res://scripts/bee_prototype/bee_garden_approved_scenery.gd"
## Mission-specific composition; reuses the Garden's five approved scene resources and pivots.
func _ready() -> void:
	super._ready()
	# Clear the Wasp's centre backdrop and keep the Probe's cyan away from foliage.
	var tree_b: Node3D = get_node("TreeB")
	tree_b.position += Vector3(2.0, 0.0, -2.0)
	var tree_c: Node3D = get_node("TreeC")
	tree_c.position += Vector3(-2.0, 0.0, -1.0)
	for fern: Node3D in get_children():
		if fern.name.begins_with("Fern"):
			fern.position.z -= 1.4 if fern.position.x > -9.0 else 0.4
	# Bottle remains visible from the last pollen to the Probe encounter.
	var bottle: Node3D = get_node("GiantBottle")
	bottle.position += Vector3(1.3, 0.0, -0.6)
	# Match the pollen route: first flower at -11, second at -3, last at 6.
	var flowers: Array[Node3D] = []
	for child: Node3D in get_children():
		if child.name.begins_with("Flower"):
			flowers.append(child)
	flowers[0].position.x += 1.0
	flowers[1].position.x += 2.0
	flowers[1].position.z -= 1.5
	flowers[2].position.x -= 1.0


