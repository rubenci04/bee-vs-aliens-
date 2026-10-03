class_name BeeAlienBomb
extends DamageHitbox3D

# One instantaneous query. The expanding ring is feedback, not ongoing damage.
var radius := 3.0
var discharge_done := false
var damaged_entities := 0

func activate(source: BeePlayer, area_radius: float, amount: int) -> void:
	attacker = source
	team_id = &"bee"
	damage = amount
	radius = area_radius
	enabled = true
	call_deferred("_discharge")
	BeeAudio.play(get_parent(), &"bomb")
	$Pulse.hide() # Replaced by the reusable composite; damage remains here.
	BeeCombatVFX.spawn(get_parent(), global_position, &"bomb", Vector3.RIGHT, radius)
	BeeCameraShake.kick(self, 0.07, 0.24) # ARCADE REBUILD 02: the one weapon that may shake the screen.
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(queue_free)

func can_damage(hurtbox: DamageHurtbox3D) -> bool:
	if not super.can_damage(hurtbox):
		return false
	var entity := hurtbox.owner_entity
	if not is_instance_valid(entity):
		return false
	if entity is BreakableRock:
		return not entity.is_destroyed
	if entity is DestructibleObstacle3D:
		return not entity.is_destroyed
	return entity.is_in_group("bee_auto_aim_targets") and (not entity.has_method("is_active") or entity.call("is_active")) and (not entity.has_method("is_defeated") or not entity.call("is_defeated"))

func _discharge() -> void:
	if discharge_done:
		return
	discharge_done = true
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in get_world_3d().direct_space_state.intersect_shape(query, 128):
		var hurtbox := result["collider"] as DamageHurtbox3D
		if hurtbox == null or not can_damage(hurtbox) or hurtbox.health_component == null:
			continue
		# Shared Health is also deduplicated if an entity has several hurtboxes.
		var id := hurtbox.health_component.get_instance_id()
		if _hit_targets.has(id):
			continue
		_hit_targets[id] = true
		var applied := hurtbox.receive_hit(self)
		if applied > 0:
			damaged_entities += 1
			hit_confirmed.emit(hurtbox, applied)

# No Area3D monitoring is enabled: base per-area callbacks cannot repeat damage.
