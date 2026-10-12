class_name AlienEnemyProjectile
extends Node3D

@export var speed := 6.0
@export var damage := 8
@export var lifetime := 2.5

@onready var hitbox: DamageHitbox3D = $Hitbox3D
var travel_direction := Vector3.LEFT
## LOTE 11: a plain enemy shot is destroyed when it touches Bee during the roll; UFO shots (group ufo_boss_projectiles) are not.
var is_common: bool:
	get:
		return not is_in_group(&"ufo_boss_projectiles")
var _time_left := 0.0


func _ready() -> void:
	_time_left = lifetime
	add_to_group("alien_projectiles")
	hitbox.damage = damage
	hitbox.hit_confirmed.connect(_on_hit_confirmed)


func launch(direction: Vector3, attacker: Node) -> void:
	travel_direction = Vector3(direction.x, direction.y, 0.0).normalized()
	if travel_direction == Vector3.ZERO:
		travel_direction = Vector3.LEFT
	hitbox.attacker = attacker
	hitbox.team_id = &"alien"
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