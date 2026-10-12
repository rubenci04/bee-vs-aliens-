class_name AlienEnemyProjectile
extends Node3D

@export var speed := 6.0
@export var damage := 8
@export var lifetime := 2.5
## LOTE 13: downward acceleration (m/s²) of a LOBBED shot (ant pebble, snail bubble, beetle stone, ...). 0 = the usual straight path.
@export var gravity := 0.0
const LOB_GROUND_Y := -0.35

@onready var hitbox: DamageHitbox3D = $Hitbox3D
var travel_direction := Vector3.LEFT
## LOTE 11: a plain enemy shot is destroyed when it touches Bee during the roll; UFO shots (group ufo_boss_projectiles) are not.
var is_common: bool:
	get:
		return not is_in_group(&"ufo_boss_projectiles")
var _time_left := 0.0
var _velocity := Vector3.ZERO # Only used by lobbed shots (gravity > 0).


func _ready() -> void:
	_time_left = lifetime
	add_to_group("alien_projectiles")
	hitbox.damage = damage
	hitbox.hit_confirmed.connect(_on_hit_confirmed)


func launch(direction: Vector3, attacker: Node) -> void:
	travel_direction = Vector3(direction.x, direction.y, 0.0).normalized()
	if travel_direction == Vector3.ZERO:
		travel_direction = Vector3.LEFT
	_velocity = travel_direction * speed
	hitbox.attacker = attacker
	hitbox.team_id = &"alien"
	hitbox.damage = damage
	hitbox.set_enabled(true)


func _physics_process(delta: float) -> void:
	if gravity != 0.0:
		_velocity.y -= gravity * delta
		position += _velocity * delta
		travel_direction = _velocity.normalized()
		rotation.z = atan2(travel_direction.y, travel_direction.x) # Styled shots point along their arc.
		if position.y < LOB_GROUND_Y:
			hitbox.set_enabled(false)
			queue_free() # A lobbed shot that lands is gone.
			return
	else:
		position += travel_direction * speed * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


func _on_hit_confirmed(_hurtbox: DamageHurtbox3D, _applied_damage: int) -> void:
	hitbox.set_enabled(false)
	queue_free()


## Current velocity (m/s): straight shots keep their launch velocity, lobbed ones change it every frame (bots and tests read this).
func current_velocity() -> Vector3:
	return _velocity if gravity != 0.0 else travel_direction * speed


## Where the shot will be `seconds` from now (a lob keeps falling; a straight shot keeps its line).
func predicted_position(seconds: float) -> Vector3:
	var v := current_velocity()
	return global_position + v * seconds + Vector3(0.0, -0.5 * gravity * seconds * seconds, 0.0)
