class_name BeeEnergyProjectile
extends Node3D
const SHOOTING := preload("res://scripts/game/bee_shooting_settings.gd")
const HERO := preload("res://scripts/game/bee_hero_look_settings.gd")

@export var speed := 14.0
@export var damage := 10
@export var lifetime := 1.4

@onready var hitbox: DamageHitbox3D = $Hitbox3D
var travel_direction := Vector3.RIGHT
var is_spread_shot := false
var configured_weapon_damage := false # Explicit primary profile takes precedence over the legacy small-enemy floor.
var _time_left := 0.0
var _travelled := 0.0 # Tanda S: metros recorridos mientras la aguja sigue oculta.
var _hidden_plasma: Node3D
var trail: CPUParticles3D
static var _shared_trail_mesh: SphereMesh


func _ready() -> void:
	add_to_group("bee_projectiles")
	_time_left = lifetime
	# Own shape copies: +25% damage reach, without scaling visuals or shared resources.
	for collider in hitbox.get_children():
		if collider is CollisionShape3D and collider.shape != null:
			collider.shape = collider.shape.duplicate()
			if collider.shape is SphereShape3D:
				collider.shape.radius *= SHOOTING.PLAYER_SHOT_HITBOX_SCALE
			elif collider.shape is BoxShape3D:
				collider.shape.size *= SHOOTING.PLAYER_SHOT_HITBOX_SCALE
	hitbox.damage = damage
	hitbox.hit_confirmed.connect(_on_hit_confirmed)
	trail = CPUParticles3D.new()
	trail.name = "ShortTrail"
	trail.amount = SHOOTING.SHOT_TRAIL_AMOUNT
	trail.lifetime = SHOOTING.SHOT_TRAIL_SECONDS
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
		material.emission_enabled = true
		material.emission = Color(1.0, 0.62, 0.12)
		material.emission_energy_multiplier = SHOOTING.SHOT_EMISSION
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
	is_spread_shot = true
	trail.amount = 14
	trail.scale_amount_min = 0.75
	trail.scale_amount_max = 0.9


func launch(direction: Vector3, attacker: Node) -> void:
	travel_direction = Vector3(direction.x, direction.y, 0.0).normalized()
	if travel_direction == Vector3.ZERO:
		travel_direction = Vector3.RIGHT
	# Stretch only the visible plasma along the firing direction, never its hitbox.
	var plasma := get_node_or_null("PlasmaBall") as Node3D
	if plasma != null:
		_elongate_visual(plasma)
		if HERO.HERO_LOOK_ENABLED: # Tanda S: la aguja aparece recién fuera de la silueta de Bee.
			plasma.visible = false
			trail.emitting = false
			_hidden_plasma = plasma
	else:
		for name in ["Visual", "Core"]:
			var visual := get_node_or_null(name) as Node3D
			if visual != null:
				_elongate_visual(visual)
	hitbox.attacker = attacker
	hitbox.team_id = &"bee"
	hitbox.damage = damage
	hitbox.set_enabled(true)


func _elongate_visual(visual: Node3D) -> void:
	if not visual.has_meta("shot_original_visual_scale"):
		visual.set_meta("shot_original_visual_scale", visual.scale)
	var length := HERO.SHOT_LENGTH if HERO.HERO_LOOK_ENABLED and visual.name == "PlasmaBall" else SHOOTING.SHOT_VISUAL_LENGTH
	visual.scale = visual.get_meta("shot_original_visual_scale") * Vector3(length, 1.0, 1.0)
	visual.rotation.z = atan2(travel_direction.y, travel_direction.x)


func _physics_process(delta: float) -> void:
	position += travel_direction * speed * delta
	_time_left -= delta
	if _hidden_plasma != null:
		_travelled += speed * delta
		if _travelled >= HERO.SHOT_REVEAL_DISTANCE:
			_hidden_plasma.visible = true
			trail.emitting = true
			_hidden_plasma = null
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
	BeeCombatVFX.spawn(get_parent(), global_position, &"bee_spark", travel_direction, SHOOTING.IMPACT_SPARK_SCALE)
	hitbox.set_enabled(false)
	queue_free()
