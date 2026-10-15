class_name BeePollenPickup
extends Area3D

signal collected(pickup: BeePollenPickup, restored_health: int)

@export var heal_amount := 20
## LOTE 13: pollen this pickup adds to the pollen bar of Level 1 (see BeeLevel01Juice).
@export var pollen_value := 1
var was_collected := false


func _ready() -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		BeeToonStyle.apply(visual, true, BeeToonStyle.OUTLINE_PROP) # VISUAL POLISH 02: same look as everything else (emission kept).
		if not preload("res://scripts/game/bee_pollen_settings.gd").legacy_review:
			var bounds := AssetFauna._bounds(visual,self)
			var grains := preload("res://scripts/items/bee_pollen_hexagon.gd").new()
			grains.name = "PollenGrains"
			grains.radius = maxf(bounds.size.x,bounds.size.y)*.5
			visual.hide() # Keep the original model and hover as a backup.
			visual.set_process(false)
			add_child(grains)
	body_entered.connect(_on_body_entered)


func collect(body: Node) -> bool:
	if was_collected or not body.is_in_group("bee_player"):
		return false
	if "is_defeated" in body and bool(body.get("is_defeated")):
		return false # A defeated Bee neither heals nor consumes pollen.
	was_collected = true
	BeeAudio.play(get_parent(), &"pollen", global_position)
	BeeCombatVFX.spawn(get_parent(), global_position, &"pollen")
	var restored := 0
	var health := body.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		restored = health.restore_health(heal_amount)
	collected.emit(self, restored)
	queue_free()
	return true


func _on_body_entered(body: Node) -> void:
	collect(body)
