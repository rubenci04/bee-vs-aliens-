class_name BeetleShard
extends Node3D
## Tanda E: one of the three aimed shots a fan grenade of the stag beetle sheds. Burnt orange rim, dark core (never Bee's gold,
## never cyan). Flies straight, one hit, in `alien_projectiles` (the Nova / pollen shield clear it).
const RIM := Color(0.86, 0.36, 0.07)
const CORE := Color(0.1, 0.06, 0.04)
const RADIUS := 0.16
const LIFETIME := 2.6
var attacker: Node
var velocity := Vector3.ZERO
var damage := 4
var age := 0.0
var hitbox: DamageHitbox3D

func _ready() -> void:
	name = "BeetleShard"
	add_to_group("alien_projectiles")
	var glow := MeshInstance3D.new()
	var outer := SphereMesh.new()
	outer.radius = RADIUS * 1.25
	outer.height = RADIUS * 2.5
	outer.radial_segments = 10
	outer.rings = 5
	var glow_material := StandardMaterial3D.new()
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.albedo_color = Color(RIM, 0.85)
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outer.material = glow_material
	glow.mesh = outer
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glow)
	var core := MeshInstance3D.new()
	var inner := SphereMesh.new()
	inner.radius = RADIUS * 0.62
	inner.height = RADIUS * 1.24
	inner.radial_segments = 8
	inner.rings = 4
	var core_material := StandardMaterial3D.new()
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.albedo_color = CORE
	core_material.render_priority = 2
	inner.material = core_material
	core.mesh = inner
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	var shape := SphereShape3D.new()
	shape.radius = RADIUS
	hitbox = BeeAttackVisuals.hazard_area(self, attacker, damage, shape)
	hitbox.set_enabled(true)
	hitbox.hit_confirmed.connect(func(_h: DamageHurtbox3D, _d: int): queue_free())

func _physics_process(delta: float) -> void:
	age += delta
	global_position += velocity * delta
	if age >= LIFETIME:
		queue_free()
