extends BeeEnergyProjectile
const STYLE := preload("res://scripts/vfx/toon_shot_style.gd")
const IMPACT := preload("res://scenes/vfx/toon/bee_impact.tscn")
func _ready() -> void:
	super._ready()
	trail.mesh = STYLE.trail_mesh(false)
	$Visual.rotation.z = PI
func launch(direction: Vector3, attacker: Node) -> void:
	super.launch(direction,attacker)
	$Visual.rotation.z = atan2(travel_direction.y,travel_direction.x)+PI
func _on_hit_confirmed(hurtbox: DamageHurtbox3D, _applied_damage: int) -> void:
	# Preserve the original neutral-body rule: no damaging explosion or alien tint on fauna.
	if not hurtbox.has_meta("neutral_hit"):
		var feedback := hurtbox.owner_entity.get_node_or_null("CombatFeedback")
		var organic := feedback!=null and bool(feedback.get("organic"))
		BeeAudio.play(get_parent(),&"organic_hit" if organic else &"tech_hit",global_position)
	STYLE.impact(get_parent(),global_position,IMPACT)
	hitbox.set_enabled(false)
	queue_free()
