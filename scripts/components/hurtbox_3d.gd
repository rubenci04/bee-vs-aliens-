class_name DamageHurtbox3D
extends Area3D

@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export var owner_entity_path: NodePath = NodePath("..")
@export var team_id: StringName
## LOTE 9 — damage multiplier of this area: a controlled animal's implant / weak point takes 2x, its body 1x
## (see BeeLiberation.IMPLANT_MULTIPLIER / BODY_MULTIPLIER).
@export var damage_multiplier := 1.0

var health_component: HealthComponent
var owner_entity: Node
## LOTE 9 — optional weak point inside a single area (Wasp, Spider): a shot whose LINE OF FLIGHT passes within
## `weak_point_radius` of `weak_point` (X/Y plane) is a direct implant hit and uses `weak_point_multiplier` instead of
## `damage_multiplier`. Without a travel direction (melee) the hit position is used.
var weak_point: Node3D
var weak_point_radius := 0.0
var weak_point_multiplier := 2.0
var last_hit_weak := false # The last applied hit used a multiplier above 1x (feedback / tests).
var hits_taken := 0 # LOTE 9: hits this area applied damage for (tests / feedback).


func _ready() -> void:
	health_component = get_node_or_null(health_component_path) as HealthComponent
	owner_entity = get_node_or_null(owner_entity_path)
	if health_component == null:
		push_error("Hurtbox3D requires a valid HealthComponent")


func multiplier_for(hitbox: Node3D) -> float:
	if weak_point == null or not is_instance_valid(weak_point) or not weak_point.is_inside_tree():
		return damage_multiplier
	var to_point := Vector2(weak_point.global_position.x - hitbox.global_position.x, weak_point.global_position.y - hitbox.global_position.y)
	var mover := hitbox.get_parent()
	var direction := Vector2.ZERO
	if mover != null and "travel_direction" in mover:
		var travel: Vector3 = mover.get("travel_direction")
		direction = Vector2(travel.x, travel.y).normalized()
	var miss := to_point.length() if direction == Vector2.ZERO else absf(direction.cross(to_point))
	return weak_point_multiplier if miss <= weak_point_radius else damage_multiplier


func receive_hit(hitbox: DamageHitbox3D) -> int:
	if health_component == null or not hitbox.can_damage(self):
		return 0
	# LOTE 11: during the roll, common enemy shots that touch Bee are destroyed (everything else is just ignored by `invulnerable`).
	if owner_entity is BeePlayer and (owner_entity as BeePlayer).is_rolling:
		var shot := hitbox.get_parent() as AlienEnemyProjectile
		if shot != null and shot.is_common:
			hitbox.set_enabled(false)
			shot.queue_free()
			(owner_entity as BeePlayer).absorb_shot()
		return 0
	# One hitbox damages one HealthComponent once per enable: a bomb overlapping the body and the implant of the same
	# animal (two areas, one health) counts once.
	var health_id := health_component.get_instance_id()
	if hitbox.hit_healths.has(health_id):
		return 0
	hitbox.hit_healths[health_id] = true
	var multiplier := multiplier_for(hitbox)
	if hitbox.ignores_weak_points:
		multiplier = minf(multiplier, 1.0)
	last_hit_weak = multiplier > 1.0
	var amount := hitbox.damage
	if multiplier != 1.0 and amount > 0:
		amount = maxi(1, roundi(float(amount) * multiplier))
	# Level-only pressure budget belongs to the firing implant, including its delayed hazards.
	if owner_entity is BeePlayer:
		var pressure := hitbox.bee_damage_scale
		amount = maxi(1, roundi(float(amount) * pressure)) if amount > 0 else 0
	if owner_entity != null and owner_entity.has_method("limit_hull_damage") and health_component == owner_entity.get("health"):
		amount = int(owner_entity.call("limit_hull_damage", amount, hitbox))
	var applied := health_component.take_damage(amount)
	if applied > 0:
		hits_taken += 1
	return applied
