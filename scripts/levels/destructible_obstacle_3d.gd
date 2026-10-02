class_name DestructibleObstacle3D
extends Node3D

signal destroyed(obstacle: DestructibleObstacle3D)

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var body: StaticBody3D = $StaticBody3D
@onready var collider: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var visual_root: Node3D = $VisualRoot

var is_destroyed := false

func _ready() -> void:
	health.died.connect(_on_died)

func _on_died() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	BeeAudio.play(get_parent(), &"crate", global_position + Vector3(0, 1.1, 0))
	BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0, 1.1, 0), &"crate")
	visual_root.hide()
	body.collision_layer = 0
	collider.set_deferred("disabled", true)
	hurtbox.set_deferred("monitorable", false)
	destroyed.emit(self)
