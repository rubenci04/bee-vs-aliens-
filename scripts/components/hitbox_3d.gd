class_name DamageHitbox3D
extends Area3D

signal hit_confirmed(hurtbox: DamageHurtbox3D, applied_damage: int)

@export_range(0, 100000, 1) var damage: int = 10
@export var starts_enabled: bool = false
@export var attacker_path: NodePath = NodePath("..")
@export var team_id: StringName

var attacker: Node
var enabled := false
var _hit_targets: Dictionary = {}


func _ready() -> void:
	attacker = get_node_or_null(attacker_path)
	area_entered.connect(_on_area_entered)
	set_enabled(starts_enabled)


func set_enabled(value: bool) -> void:
	enabled = value
	set_deferred("monitoring", value)
	if value:
		_hit_targets.clear()


func can_damage(hurtbox: DamageHurtbox3D) -> bool:
	if not enabled:
		return false
	if attacker != null and hurtbox.owner_entity == attacker:
		return false
	if not team_id.is_empty() and team_id == hurtbox.team_id:
		return false
	return true


func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as DamageHurtbox3D
	if hurtbox == null or not can_damage(hurtbox):
		return
	var target_id := hurtbox.get_instance_id()
	if _hit_targets.has(target_id):
		return
	_hit_targets[target_id] = true
	var applied := hurtbox.receive_hit(self)
	if applied > 0:
		hit_confirmed.emit(hurtbox, applied)
