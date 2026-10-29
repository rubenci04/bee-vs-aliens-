class_name BeeAlienBomb
extends DamageHitbox3D

## One flying bomb; warning precedes one deduplicated area query.
const FLIGHT_SECONDS := 1.2
const MAX_RANGE := 14.0
const UNTARGETED_RANGE := 5.0
const TARGET_RANGE := 18.0
const TARGET_FORWARD_DOT := 0.15
const TURN_SPEED_RADIANS := 2.8
const WARNING_SECONDS := 0.24
const CONTACT_RADIUS := 0.24
const MODEL := preload("res://scenes/art_labs/pickups_toon_v01/pickup_bomb.tscn")
const MODEL_SCALE := 0.35
const HONEY_BURST := preload("res://scripts/vfx/bee_honey_bomb_burst.gd")
var radius := 3.0
var discharge_done := false
var damaged_entities := 0
var direction := Vector3.RIGHT
var travelled := 0.0
var flight_left := FLIGHT_SECONDS
var warning_left := -1.0
var source_player: BeePlayer
var homing_target: Node3D

func activate(source: BeePlayer, area_radius: float, amount: int) -> void:
	attacker = source
	source_player = source
	team_id = &"bee"
	damage = amount
	radius = area_radius
	direction = source.aim_direction().normalized()
	homing_target = _choose_target()
	ignores_weak_points = true
	enabled = true
	$Pulse.show()
	$Pulse.scale = Vector3.ONE * CONTACT_RADIUS
	var core := MODEL.instantiate() as Node3D
	core.name = "FlightModel"
	core.scale = Vector3.ONE * MODEL_SCALE
	add_child(core)

func detonate() -> void:
	if warning_left >= 0.0 or discharge_done:
		return
	warning_left = WARNING_SECONDS
	$Pulse.scale = Vector3.ONE * radius

func _physics_process(delta: float) -> void:
	if discharge_done:
		return
	if warning_left >= 0.0:
		warning_left -= delta
		if warning_left <= 0.0:
			_discharge()
			BeeAudio.play(get_parent(), &"bomb")
			HONEY_BURST.spawn(get_parent(), global_position, radius)
			BeeCameraShake.kick(self, 0.07, 0.24)
			hide()
			if is_instance_valid(source_player):
				source_player.active_bomb = null
				source_player.weapon_state_changed.emit()
			get_tree().create_timer(0.4).timeout.connect(queue_free)
		return
	if not is_instance_valid(homing_target) or not homing_target.is_inside_tree():
		homing_target = _choose_target()
	if is_instance_valid(homing_target):
		var wanted := (homing_target.global_position - global_position).normalized()
		wanted.z = 0.0
		if wanted.length_squared() > 0.01:
			direction = direction.rotated(Vector3.BACK, clampf(direction.signed_angle_to(wanted.normalized(), Vector3.BACK), -TURN_SPEED_RADIANS * delta, TURN_SPEED_RADIANS * delta)).normalized()
	var flight_range := MAX_RANGE if is_instance_valid(homing_target) else UNTARGETED_RANGE
	var step := minf(flight_range - travelled, MAX_RANGE / FLIGHT_SECONDS * delta)
	var next := global_position + direction * step
	var ray := PhysicsRayQueryParameters3D.create(global_position, next, 3)
	ray.collide_with_areas = true
	ray.exclude = [source_player.get_rid(), source_player.hurtbox.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	for ignored in 16:
		if hit.is_empty():
			break
		var hurt := hit.collider as DamageHurtbox3D
		if hurt == null or can_damage(hurt):
			break
		ray.exclude = ray.exclude + [hurt.get_rid()]
		hit = get_world_3d().direct_space_state.intersect_ray(ray)
	global_position = hit.position if not hit.is_empty() else next
	travelled += step
	flight_left -= delta
	var shape := SphereShape3D.new()
	shape.radius = CONTACT_RADIUS
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 3
	query.collide_with_areas = true
	query.exclude = ray.exclude
	var contact := not hit.is_empty()
	for result in get_world_3d().direct_space_state.intersect_shape(query, 32):
		var hurt := result.collider as DamageHurtbox3D
		if hurt == null or can_damage(hurt):
			contact = true
	if contact or travelled >= flight_range or flight_left <= 0.0:
		detonate()


func _choose_target() -> Node3D:
	if source_player == null or not source_player.is_inside_tree():
		return null
	var best: Node3D
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("bee_auto_aim_targets"):
		var candidate := node as Node3D
		if candidate == null or not is_instance_valid(candidate) or not candidate.is_inside_tree():
			continue
		if candidate.has_method("is_active") and not candidate.call("is_active"):
			continue
		if candidate.has_method("is_defeated") and candidate.call("is_defeated"):
			continue
		var toward := candidate.global_position - global_position
		toward.z = 0.0
		var distance := toward.length()
		if distance < 0.1 or distance > TARGET_RANGE or direction.dot(toward.normalized()) < TARGET_FORWARD_DOT:
			continue
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best

func can_damage(hurtbox: DamageHurtbox3D) -> bool:
	if not super.can_damage(hurtbox):
		return false
	var entity := hurtbox.owner_entity
	if not is_instance_valid(entity):
		return false
	if entity.is_in_group("bee_destructibles"):
		return not entity.is_destroyed
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
		# LOTE 9: an entity may scale the bomb on its main health (the NODO ALIEN takes BOMB_FRACTION of its life).
		var base_damage := damage
		var entity := hurtbox.owner_entity
		if entity.has_method("bomb_damage_for") and entity.get("health") == hurtbox.health_component:
			damage = int(entity.call("bomb_damage_for", base_damage))
		var applied := hurtbox.receive_hit(self)
		damage = base_damage
		if applied > 0:
			damaged_entities += 1
			hit_confirmed.emit(hurtbox, applied)

# No Area3D monitoring is enabled: base per-area callbacks cannot repeat damage.
