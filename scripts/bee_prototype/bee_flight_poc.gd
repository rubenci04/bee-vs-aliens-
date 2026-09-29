extends Node3D

@onready var bee: BeePlayer = $BeePlayer
@onready var enemy: AlienProbeEnemy = $AlienProbeEnemy
@onready var hp_label: Label = $CanvasLayer/Panel/VBox/HP
@onready var pollen_label: Label = $CanvasLayer/Panel/VBox/Pollen
@onready var auto_aim_label: Label = $CanvasLayer/Panel/VBox/AutoAim
@onready var completion_label: Label = $CanvasLayer/Completion

var pollen_count := 0
var completion_shown := false


func _ready() -> void:
	for pickup in $Pollen.get_children():
		pickup.collected.connect(_on_pollen_collected)
	bee.health_changed.connect(_on_bee_health_changed)
	bee.auto_aim_changed.connect(_on_auto_aim_changed)
	enemy.defeated.connect(_on_enemy_defeated)
	_on_bee_health_changed(bee.health.current_health, bee.health.max_health)
	_update_pollen_label()
	auto_aim_label.hide()
	completion_label.hide()


func _on_pollen_collected(_pickup: BeePollenPickup, _restored_health: int) -> void:
	pollen_count += 1
	_update_pollen_label()
	_try_complete()


func _on_bee_health_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, maximum]


func _on_auto_aim_changed(target: Node3D) -> void:
	auto_aim_label.visible = target != null


func _on_enemy_defeated(_defeated_enemy: AlienProbeEnemy) -> void:
	_try_complete()


func _update_pollen_label() -> void:
	pollen_label.text = "POLEN: %d/3" % pollen_count


func _try_complete() -> void:
	if completion_shown or pollen_count < 3 or not enemy.is_defeated():
		return
	completion_shown = true
	completion_label.show()