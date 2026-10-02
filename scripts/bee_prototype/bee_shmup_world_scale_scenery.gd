extends "res://scripts/bee_prototype/bee_garden_approved_scenery.gd"

func _ready() -> void:
	for entry in [[-4.0, 17.0, -3.2], [5.0, 22.0, -4.0], [25.0, 18.0, -3.4], [39.0, 20.0, -4.1], [62.0, 19.0, -3.6]]:
		place(FLOWER, "Flower%d" % get_child_count(), Vector3(entry[0], 0.0, entry[2]), entry[1], 0.2)
	place(BOTTLE, "GiantBottle", Vector3(12.0, 0.0, -4.5), 10.337, 0.15)
	for entry in [[-2.0, -9.0], [20.0, -10.0], [49.0, -9.0], [72.0, -10.0]]:
		place(TREE, "Tree%d" % get_child_count(), Vector3(entry[0], 0.0, entry[1]), 0.9, 0.2)
	for entry in [[-1.0, -3.8], [16.0, -4.0], [31.0, -3.7], [52.0, -4.1], [70.0, -3.8]]:
		place(FERN, "Fern%d" % get_child_count(), Vector3(entry[0], 0.0, entry[1]), 2.1, 0.3)
