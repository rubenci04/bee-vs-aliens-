extends Node3D
## Presentation only. The actor owns facing, squash, telegraph and combat.
@export var wing_frequency := 19.0
@export var wing_amplitude := 0.62
@onready var actor: WaspEnemy = get_parent().get_parent() as WaspEnemy
var wings: Array[Node3D] = []
var rest_angles: Array[Vector3] = []
var elapsed := 0.0

func _ready() -> void:
	for wing_name in ["Wing_L", "Wing_R"]:
		var wing := find_child(wing_name, true, false) as Node3D
		assert(wing != null, "Wasp visual requires independent wings")
		wings.append(wing)
		rest_angles.append(wing.rotation)
	if actor != null:
		get_parent().rotation.y = -actor.facing_x * PI * 0.5

func _process(delta: float) -> void:
	if actor != null and (actor.is_defeated() or not actor.is_active()):
		return
	elapsed += delta
	for i in wings.size():
		wings[i].rotation = rest_angles[i] + Vector3(0, 0, sin(elapsed * TAU * wing_frequency) * wing_amplitude * (-1.0 if i == 0 else 1.0))
