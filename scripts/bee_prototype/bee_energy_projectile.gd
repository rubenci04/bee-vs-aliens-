class_name BeeEnergyProjectile
extends Node3D

@export var speed := 14.0
@export var damage := 10
@export var lifetime := 1.4

@onready var hitbox: DamageHitbox3D = $Hitbox3D
var travel_direction := Vector3.RIGHT
var _time_left := 0.0
var trail: CPUParticles3D
static var _shared_trail_mesh: SphereMesh


func _ready() -> void:
	_time_left = lifetime
	hitbox.damage = damage
	hitbox.hit_confirmed.connect(_on_hit_confirmed)
	trail = CPUParticles3D.new()
	trail.name = "ShortTrail"
	trail.amount = 10
	trail.lifetime = 0.18
	trail.local_coords = false
	trail.gravity = Vector3.ZERO
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 0.0
	if _shared_trail_mesh == null:
		_shared_trail_mesh = SphereMesh.new()
		_shared_trail_mesh.radius = 0.035
		_shared_trail_mesh.height = 0.07
		_shared_trail_mesh.radial_segments = 6
		_shared_trail_mesh.rings = 3
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(1.0, 0.62, 0.12, 0.72)
		material.vertex_color_use_as_albedo = true
		_shared_trail_mesh.material = material
	trail.mesh = _shared_trail_mesh
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	trail.color_ramp = gradient
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trail)
	trail.emitting = true


func set_spread_visual() -> void:
	trail.amount = 14
	trail.scale_amount_min = 0.75
	trail.scale_amount_max = 0.9


func launch(direction: Vector3, attacker: Node) -> void:
	travel_direction = Vector3(direction.x, direction.y, 0.0).normalized()
	if travel_direction == Vector3.ZERO:
		travel_direction = Vector3.RIGHT
	hitbox.attacker = attacker
	hitbox.team_id = &"bee"
	hitbox.damage = damage
	hitbox.set_enabled(true)


func _physics_process(delta: float) -> void:
	position += travel_direction * speed * delta
	_time_left -= delta
	if _time_left <= 0.0 or (BeeShmupFairness.screen_bound_combat and BeeShmupFairness.is_leaving_screen(self, travel_direction, 0.3)):
		queue_free() # REBUILD 02 (Level 01): a shot that leaves the screen is gone; it never kills what is not there yet.


func _on_hit_confirmed(hurtbox: DamageHurtbox3D, _applied_damage: int) -> void:
	if hurtbox.has_meta("neutral_hit"):
		# Controlled fauna: the animal body absorbs the shot with a soft neutral puff (no damage, no hit sound).
		BeeCombatVFX.spawn(get_parent(), global_position, &"neutral_hit", travel_direction)
		hitbox.set_enabled(false)
		queue_free()
		return
	var feedback := hurtbox.owner_entity.get_node_or_null("CombatFeedback")
	var organic := feedback != null and bool(feedback.get("organic"))
	BeeAudio.play(get_parent(), &"organic_hit" if organic else &"tech_hit", global_position)
	BeeCombatVFX.spawn(get_parent(), global_position, &"impact_organic" if organic else &"bee_impact", travel_direction)
	hitbox.set_enabled(false)
	queue_free()
