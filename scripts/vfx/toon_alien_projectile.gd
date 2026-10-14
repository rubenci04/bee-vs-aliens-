extends AlienEnemyProjectile
const STYLE := preload("res://scripts/vfx/toon_shot_style.gd")
const IMPACT := preload("res://scenes/vfx/toon/alien_impact.tscn")
func _ready() -> void:
	super._ready()
	add_child(STYLE.make_trail(true))
func launch(direction: Vector3, attacker: Node) -> void:
	super.launch(direction,attacker)
	$Visual.rotation.z = atan2(travel_direction.y,travel_direction.x)+PI
func _on_hit_confirmed(_hurtbox: DamageHurtbox3D, _applied_damage: int) -> void:
	STYLE.impact(get_parent(),global_position,IMPACT)
	hitbox.set_enabled(false)
	queue_free()
