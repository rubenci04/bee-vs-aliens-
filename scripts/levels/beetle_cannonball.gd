class_name BeetleCannonball
extends Node3D
## Tanda E2: heavy ball flying up in a straight diagonal; it bursts in the air (radius 1.5 m, damage 8) and sheds 4 short fragments (reach 1.8 m).
## It is in `alien_projectiles`, so the Nova / pollen shield clear it before it bursts.
const BURST_RADIUS := 1.5
const BURST_DAMAGE := 8
const FRAGMENTS := 4
const FRAGMENT_REACH := 1.8
const FRAGMENT_SPEED := 4.5
const FRAGMENT_DAMAGE := 3
const PROJECTILE := preload("res://scenes/bee_prototype/alien_enemy_projectile.tscn")
var attacker: Node
var velocity := Vector3.ZERO
var flight_time := 0.85
var age := 0.0
var burst_done := false
var fragments_spawned := 0

func _ready() -> void:
	name = "BeetleCannonball"
	add_to_group("alien_projectiles")
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	mesh.mesh = sphere
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.14, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.55, 0.12)
	mat.emission_energy_multiplier = 0.9
	mesh.material_override = mat
	add_child(mesh)

func _physics_process(delta: float) -> void:
	if burst_done or not is_inside_tree():
		return
	age += delta
	global_position += velocity * delta
	rotation.z += 8.0 * delta
	if age >= flight_time:
		burst()

func burst() -> void:
	if burst_done or not is_inside_tree():
		return
	burst_done = true
	var parent := get_parent()
	var at := global_position
	var shape := SphereShape3D.new()
	shape.radius = BURST_RADIUS
	var hitbox := BeeAttackVisuals.hazard_area(parent, attacker, BURST_DAMAGE, shape)
	hitbox.global_position = at
	hitbox.set_enabled(true)
	# Visible burst: an expanding orange sphere of the real radius.
	var flash := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	flash.mesh = ball
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.albedo_color = Color(1.0, 0.55, 0.12, 0.55)
	flash.material_override = fmat
	parent.add_child(flash)
	flash.global_position = at
	flash.scale = Vector3.ONE * 0.2
	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * BURST_RADIUS, 0.18)
	tween.tween_property(fmat, "albedo_color:a", 0.0, 0.3)
	tween.chain().tween_callback(flash.queue_free)
	var off := hitbox.create_tween()
	off.tween_interval(0.15)
	off.tween_callback(hitbox.queue_free)
	BeeCombatVFX.spawn(parent, at, &"bomb", Vector3.UP, 0.8)
	for i in FRAGMENTS:
		var angle := TAU * (float(i) + 0.5) / float(FRAGMENTS)
		var direction := Vector3(cos(angle), sin(angle), 0.0)
		var shot := BeeEnemyPatterns.spawn_styled(parent, PROJECTILE, at, direction, FRAGMENT_DAMAGE, FRAGMENT_SPEED, attacker, &"pellet")
		shot.lifetime = FRAGMENT_REACH / FRAGMENT_SPEED
		fragments_spawned += 1
	queue_free()
