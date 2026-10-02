extends "res://scripts/bee_prototype/bee_shmup_world_scale_scenery.gd"

func _ready() -> void:
	super._ready()
	for entry in [[7.0, -4.6, 5.4, 0.2], [18.0, -4.4, 6.1, -0.3], [23.0, -4.7, 5.7, 0.4], [35.0, -4.5, 6.0, 0.0], [45.0, -4.8, 5.3, -0.2], [57.0, -4.5, 6.2, 0.3], [66.0, -4.7, 5.6, -0.4]]:
		place(FLOWER, "PolishFlower%d" % get_child_count(), Vector3(entry[0], 0, entry[1]), entry[2], entry[3])
	for entry in [[29.0, -4.9], [53.0, -4.8]]:
		place(FERN, "PolishFern%d" % get_child_count(), Vector3(entry[0], 0, entry[1]), 1.5, -0.2)
