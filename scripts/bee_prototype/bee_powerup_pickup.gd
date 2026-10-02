class_name BeePowerupPickup
extends Area3D

enum Kind { SPREAD, BOMB }
@export var kind: Kind = Kind.SPREAD
var was_collected := false

func _ready() -> void:
	$SpreadVisual.visible = kind == Kind.SPREAD
	$BombVisual.visible = kind == Kind.BOMB
	$Label.text = "S" if kind == Kind.SPREAD else "B"
	body_entered.connect(collect)

func collect(body: Node3D) -> bool:
	var bee := body as BeePlayer
	if was_collected or bee == null or bee.is_defeated:
		return false
	var accepted := bee.collect_spread() if kind == Kind.SPREAD else bee.collect_bomb()
	if not accepted:
		return false # Bomb at the cap stays available for later.
	was_collected = true
	BeeAudio.play(get_parent(), &"spread_pickup" if kind == Kind.SPREAD else &"bomb_pickup", global_position)
	BeeCombatVFX.spawn(get_parent(), global_position, &"pickup" if kind == Kind.SPREAD else &"pickup_bomb")
	hide()
	set_deferred("monitoring", false)
	queue_free()
	return true
