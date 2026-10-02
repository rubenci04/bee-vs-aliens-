extends Node

@export var organic := false
@export var heavy := false
var death_emitted := false

func _ready() -> void:
	get_parent().get_node("HealthComponent").died.connect(_on_death)

func _on_death() -> void:
	if death_emitted:
		return
	death_emitted = true
	var enemy := get_parent() as Node3D
	var hurtbox := enemy.get_node("Hurtbox3D") as Node3D
	BeeAudio.play(enemy.get_parent(), &"organic_death" if organic else &"tech_death", hurtbox.global_position, 0.82 if heavy else 1.0)
	BeeCombatVFX.spawn(enemy.get_parent(), hurtbox.global_position, &"organic_death" if organic else &"tech_death")
