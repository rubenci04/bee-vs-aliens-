extends Node3D
## Presentation only: never writes the CharacterBody transform or combat state.
@export var wing_frequency := 16.0
@export var wing_amplitude := 0.55
@onready var actor: BeePlayer = get_parent().get_parent() as BeePlayer
var wings: Array[Node3D] = []
var rest_angles: Array[Vector3] = []
var elapsed := 0.0

func _ready() -> void:
	for wing_name in ["Wing_L", "Wing_R"]:
		var wing := find_child(wing_name, true, false) as Node3D
		assert(wing != null, "Bee visual requires independent wings")
		wings.append(wing)
		rest_angles.append(wing.rotation)
	# Matches the existing Player facing convention, including its initial pose.
	get_parent().rotation.y = -actor.facing_x * PI * 0.5

func _process(delta: float) -> void:
	if actor.is_defeated:
		return
	elapsed += delta
	for i in wings.size():
		wings[i].rotation = rest_angles[i] + Vector3(0, 0, sin(elapsed * TAU * wing_frequency) * wing_amplitude * (-1.0 if i == 0 else 1.0))
