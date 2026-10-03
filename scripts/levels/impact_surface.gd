class_name ImpactSurface
extends Node3D
## A large visible solid (bottle, log shell...) that stops Bee's shots instead of letting them pass through; the projectile adds
## its own spark and the approved hit sound. It never breaks (huge HP) and enemy fire ignores it (team "alien").
## Reuses HealthComponent + Hurtbox3D: no new combat system.

const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const SURFACE_HP := 1000000

var health: HealthComponent
var hurtbox: DamageHurtbox3D
var hits := 0


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
	surface.health.health_changed.connect(surface._on_hit)
	return surface


func _on_hit(_current: int, _maximum: int, change: int) -> void:
	if change >= 0:
		return
	hits += 1
	health.current_health = health.max_health # Never wears out.
	# The projectile spawns its spark at the real contact point and plays the approved hit sound.
