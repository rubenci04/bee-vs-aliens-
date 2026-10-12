class_name BeeLevel01GardenMushrooms
extends Node3D
## LOTE 12 · ETAPA 2 — the garden mushrooms of Level 1 (flower bed and vegetable patch): fixed, destructible, they drop pollen
## (BeeGardenMushroom). They are decoration with a reward, not enemies; the cannon mushroom is the only one that shoots.
## [kind, X]; none sits on a combat rock (X=72/96/155/205/241) nor inside the breathing valley (X=180-208).
const PLACEMENTS := [
	[&"button", 76.0], [&"spotted", 88.0], [&"umbrella", 101.0], [&"button", 118.0], [&"spotted", 133.0], [&"umbrella", 146.0],
	[&"button", 160.0], [&"spotted", 171.0],
	[&"umbrella", 213.0], [&"button", 226.0], [&"spotted", 236.0], [&"umbrella", 250.0], [&"button", 262.0],
	# LOTE 13: destructible bellflowers (pollen too), spread over the whole level.
	[&"bellflower", 34.0], [&"bellflower", 54.0], [&"bellflower", 66.0], [&"bellflower", 110.0], [&"bellflower", 126.0], [&"bellflower", 140.0],
	[&"bellflower", 166.0], [&"bellflower", 196.0], [&"bellflower", 210.0], [&"bellflower", 220.0], [&"bellflower", 232.0], [&"bellflower", 246.0],
	[&"bellflower", 256.0], [&"bellflower", 270.0], [&"bellflower", 284.0],
]
var mushrooms: Array[BeeGardenMushroom] = []


func _ready() -> void:
	for i in PLACEMENTS.size():
		mushrooms.append(BeeGardenMushroom.place(self, "Mushroom%d" % i, PLACEMENTS[i][0], float(PLACEMENTS[i][1])))
