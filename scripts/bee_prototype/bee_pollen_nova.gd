extends DamageHitbox3D
## Expanding sphere: one hit per HealthComponent, regardless of body/implant overlap.
const S := preload("res://scripts/game/bee_pollen_nova_settings.gd")
var elapsed := 0.0
var wave: MeshInstance3D
var wave_material: StandardMaterial3D
var query := PhysicsShapeQueryParameters3D.new()
var sphere := SphereShape3D.new()

func _ready() -> void:
	super._ready()
	collision_layer = 0
	collision_mask = 0
	team_id = &"bee"
	ignores_weak_points = true
	enabled = true # Uses explicit queries, no monitoring callback or collision node.
	query.shape = sphere
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	wave = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 1.0 - S.WAVE_THICKNESS
	ring.outer_radius = 1.0
	ring.rings = S.WAVE_RINGS
	ring.ring_segments = S.WAVE_SEGMENTS
	wave.mesh = ring
	wave.rotation.x = PI * 0.5
	wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wave_material = StandardMaterial3D.new()
	wave_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wave_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wave_material.albedo_color = Color(1, 0.78, 0.16, S.WAVE_ALPHA)
	wave_material.emission_enabled = true
	wave_material.emission = Color(1, 0.78, 0.16)
	wave.material_override = wave_material
	add_child(wave)
	wave.scale = Vector3.ONE * 0.01

func _physics_process(delta: float) -> void:
	elapsed = minf(elapsed + delta, S.WAVE_SECONDS)
	var fraction := elapsed / S.WAVE_SECONDS
	var radius := maxf(0.01, S.RADIUS * fraction)
	wave.scale = Vector3.ONE * radius
	wave_material.albedo_color.a = S.WAVE_ALPHA * (1.0 - fraction)
	sphere.radius = radius
	query.transform = global_transform
	for result in get_world_3d().direct_space_state.intersect_shape(query, 256):
		var hurt := result.collider as DamageHurtbox3D
		if hurt == null or not can_damage(hurt):
			continue
		damage = S.BOSS_DAMAGE if _is_boss(hurt.owner_entity) else S.COMMON_DAMAGE
		var applied := hurt.receive_hit(self)
		if applied > 0:
			hit_confirmed.emit(hurt, applied)
	for shot in get_tree().get_nodes_in_group("alien_projectiles"):
		if shot is Node3D and not shot.is_queued_for_deletion() and global_position.distance_to(shot.global_position) <= radius:
			# Disable immediately, so a cleared shot cannot hit Bee in this physics step.
			for child in shot.find_children("*", "Area3D", true, false):
				if child is DamageHitbox3D: child.set_enabled(false)
			shot.queue_free()
	if elapsed >= S.WAVE_SECONDS:
		queue_free()

func can_damage(hurt: DamageHurtbox3D) -> bool:
	if not super.can_damage(hurt) or hurt.health_component == null:
		return false
	var entity := hurt.owner_entity
	return is_instance_valid(entity) and entity.is_in_group("bee_auto_aim_targets") and (not entity.has_method("is_active") or entity.call("is_active"))

func _is_boss(entity: Node) -> bool:
	while entity != null:
		if entity is WalkerMiniboss or entity is TarantulaBoss01 or entity is UfoBoss01 or entity is BeeLakeToadBoss:
			return true
		entity = entity.get_parent()
	return false
