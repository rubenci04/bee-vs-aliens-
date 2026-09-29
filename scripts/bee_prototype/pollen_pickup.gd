class_name BeePollenPickup
extends Area3D

signal collected(pickup: BeePollenPickup, restored_health: int)

@export var heal_amount := 20
var was_collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func collect(body: Node) -> bool:
	if was_collected or not body.is_in_group("bee_player"):
		return false
	was_collected = true
	var restored := 0
	var health := body.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		restored = health.restore_health(heal_amount)
	collected.emit(self, restored)
	queue_free()
	return true


func _on_body_entered(body: Node) -> void:
	collect(body)