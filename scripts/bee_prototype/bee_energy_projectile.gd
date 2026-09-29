class_name BeeEnergyProjectile
extends Node3D

@export var speed := 14.0
@export var damage := 10
@export var lifetime := 1.4

@onready var hitbox: DamageHitbox3D = $Hitbox3D
var travel_direction := Vector3.RIGHT
var _time_left := 0.0


func _ready() -> void:
	_time_left = lifetime
	hitbox.damage = damage
	hitbox.hit_confirmed.connect(_on_hit_confirmed)


func launch(direction: Vector3, attacker: Node) -> void:
	travel_direction = Vector3(direction.x, direction.y, 0.0).normalized()
	if travel_direction == Vector3.ZERO:
		travel_direction = Vector3.RIGHT
	hitbox.attacker = attacker
	hitbox.team_id = &"bee"
	hitbox.damage = damage
	hitbox.set_enabled(true)


func _physics_process(delta: float) -> void:
	position += travel_direction * speed * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


func _on_hit_confirmed(_hurtbox: DamageHurtbox3D, _applied_damage: int) -> void:
	hitbox.set_enabled(false)
	queue_free()