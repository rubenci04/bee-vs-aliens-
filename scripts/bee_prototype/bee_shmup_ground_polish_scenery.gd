extends "res://scripts/bee_prototype/bee_shmup_scenery.gd"

func _ready() -> void:
	super._ready()
	for entry in [[5.0, -4.1, 5.7, 0.1], [17.0, -4.3, 6.4, -0.3], [21.0, -4.0, 5.2, 0.4], [35.0, -4.3, 6.0, -0.2], [42.0, -4.1, 5.5, 0.3], [57.0, -4.2, 6.2, -0.4]]:
		place(FLOWER, "PolishFlower%d" % get_child_count(), Vector3(entry[0], 0, entry[1]), entry[2], entry[3])
	for entry in [[14.0, -4.7], [51.0, -4.5]]:
		place(FERN, "PolishFern%d" % get_child_count(), Vector3(entry[0], 0, entry[1]), 1.5, 0.2)
