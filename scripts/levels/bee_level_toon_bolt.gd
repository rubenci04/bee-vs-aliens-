extends "res://scripts/vfx/toon_bee_projectile.gd"
## NOCHE 01 · ETAPA 2 — Level 01 Bee bolt: Codex's toon bolt (look, trail, toon impact) plus the game's combat feedback
## rules it skipped: a neutral puff on an animal's body (no damage, no hit sound) and the regular impact VFX/sound.

func _on_hit_confirmed(hurtbox: DamageHurtbox3D, _applied_damage: int) -> void:
	if hurtbox.has_meta("neutral_hit"):
		BeeCombatVFX.spawn(get_parent(), global_position, &"neutral_hit", travel_direction)
		hitbox.set_enabled(false)
		queue_free()
		return
	var feedback := hurtbox.owner_entity.get_node_or_null("CombatFeedback")
	var organic := feedback != null and bool(feedback.get("organic"))
	BeeAudio.play(get_parent(), &"organic_hit" if organic else &"tech_hit", global_position)
	BeeCombatVFX.spawn(get_parent(), global_position, &"impact_organic" if organic else &"impact", travel_direction)
	STYLE.impact(get_parent(), global_position, IMPACT)
	hitbox.set_enabled(false)
	queue_free()


func _ready() -> void:
	super._ready()
	BeeShotPalette.dress_bee(self) # LOTE 9: round gold plasma ball with a white core and a short trail (was a toon bolt).
