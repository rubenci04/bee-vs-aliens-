class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int, change: int)
signal died

@export_range(1, 100000, 1) var max_health: int = 100
var current_health: int
var _death_emitted := false
var damage_blocked := false # Temporary protection, off by default.
## LOTE 11: set by the Bee roll (Shift) - same effect as damage_blocked but owned by the roll, so it never cancels respawn or victory protection.
var invulnerable := false


func _ready() -> void:
	current_health = max_health


## NOCHE 01: incoming damage multiplier (Bee on EASY); 1.0 = unchanged. Never turns a hit into 0.
var damage_scale := 1.0

func take_damage(amount: int) -> int:
	if damage_scale != 1.0 and amount > 0:
		amount = maxi(1, roundi(float(amount) * damage_scale))
	if damage_blocked or invulnerable or amount <= 0 or current_health <= 0:
		return 0
	var previous := current_health
	current_health = maxi(0, current_health - amount)
	var applied := previous - current_health
	health_changed.emit(current_health, max_health, -applied)
	if current_health == 0 and not _death_emitted:
		_death_emitted = true
		died.emit()
	return applied


func restore_health(amount: int) -> int:
	if amount <= 0 or current_health >= max_health:
		return 0
	var previous := current_health
	current_health = mini(max_health, current_health + amount)
	var restored := current_health - previous
	if current_health > 0:
		_death_emitted = false
	health_changed.emit(current_health, max_health, restored)
	return restored
