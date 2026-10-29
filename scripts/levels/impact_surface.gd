class_name ImpactSurface
extends Node3D
## A large visible solid (bottle, log shell...) that stops Bee's shots instead of letting them pass through; the projectile adds
## its own spark and the approved hit sound. LOTE 10: finite HP, breaking releases its shell; alien fire ignores it.
## Reuses HealthComponent + Hurtbox3D: no new combat system.

const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const SURFACE_HP := 64

signal broken

var health: HealthComponent
var hurtbox: DamageHurtbox3D
var hits := 0
var is_destroyed := false
var solid_shape: CollisionShape3D


static func attach(parent: Node, label: String, shape: BoxShape3D, size: Vector3, world_center: Vector3) -> ImpactSurface:
	var surface := ImpactSurface.new()
	surface.name = label
	parent.add_child(surface)
	surface.global_position = world_center
	surface.health = HEALTH_SCENE.instantiate() as HealthComponent
	surface.health.name = "HealthComponent"
	surface.health.max_health = SURFACE_HP
	surface.add_child(surface.health)
	surface.hurtbox = HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	surface.hurtbox.name = "Hurtbox3D"
	surface.hurtbox.team_id = &"alien"
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	surface.hurtbox.add_child(collision)
	surface.add_child(surface.hurtbox)
	surface.add_to_group("bee_destructibles")
	surface.health.health_changed.connect(surface._on_hit)
	surface.health.died.connect(surface._break)
	return surface


func _on_hit(_current: int, _maximum: int, change: int) -> void:
	if change >= 0:
		return
	hits += 1
	BeeCombatVFX.spawn(get_parent(), global_position, &"rock_hit")
	# The projectile spawns its spark at the real contact point and plays the approved hit sound.

func _break() -> void:
	is_destroyed = true
	hurtbox.set_deferred("collision_layer", 0)
	hurtbox.set_deferred("monitorable", false)
	if is_instance_valid(solid_shape):
		solid_shape.set_deferred("disabled", true)
	BeeCombatVFX.spawn(get_parent(), global_position, &"crate")
	broken.emit()

func restore_broken() -> void:
	is_destroyed = true
	health.current_health = 0
	hurtbox.set_deferred("collision_layer", 0)
	hurtbox.set_deferred("monitorable", false)
	if is_instance_valid(solid_shape):
		solid_shape.set_deferred("disabled", true)
	broken.emit()
