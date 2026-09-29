extends Node3D
## Read-only observer of the actor. Only this subtree receives transforms.
@export var preview_facing := 1.0
@export var bob_amplitude := 0.015
@export var bob_frequency := 1.4
@onready var model: Node3D = $Model
@onready var actor: AlienProbeRanged = get_parent().get_parent() as AlienProbeRanged
var elapsed := 0.0
var facing := 1.0
var ring: Node3D

func _ready() -> void:
	facing = preview_facing
	ring = find_child("CoreRing", true, false) as Node3D
	rotation.y = -facing * PI * 0.5

func _process(delta: float) -> void:
	if actor != null and (actor.is_defeated() or not actor.is_active()):
		return
	elapsed += delta
	var pitch := 0.0
	if actor != null and is_instance_valid(actor.target):
		var direction := actor.target.global_position - actor.global_position
		if absf(direction.x) > 0.08:
			facing = signf(direction.x)
		pitch = atan2(direction.y, maxf(absf(direction.x), 0.08))
	rotation = Vector3(pitch, -facing * PI * 0.5, 0.0)
	model.position.y = sin(elapsed * TAU * bob_frequency) * bob_amplitude
	if ring != null:
		ring.rotation.y += delta * 0.8
