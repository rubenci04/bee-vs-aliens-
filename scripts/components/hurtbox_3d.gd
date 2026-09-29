class_name DamageHurtbox3D
extends Area3D

@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export var owner_entity_path: NodePath = NodePath("..")
@export var team_id: StringName

var health_component: HealthComponent
var owner_entity: Node


func _ready() -> void:
	health_component = get_node_or_null(health_component_path) as HealthComponent
	owner_entity = get_node_or_null(owner_entity_path)
	if health_component == null:
		push_error("Hurtbox3D requires a valid HealthComponent")


func receive_hit(hitbox: DamageHitbox3D) -> int:
	if health_component == null or not hitbox.can_damage(self):
		return 0
	return health_component.take_damage(hitbox.damage)
