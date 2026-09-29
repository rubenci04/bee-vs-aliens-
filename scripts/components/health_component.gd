class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int, change: int)
signal died

@export_range(1, 100000, 1) var max_health: int = 100
var current_health: int
var _death_emitted := false


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> int:
	if amount <= 0 or current_health <= 0:
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
