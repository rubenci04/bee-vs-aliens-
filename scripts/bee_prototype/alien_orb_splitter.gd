class_name AlienOrbSplitter
extends Node
## COMBAT VARIETY 01: child of a slow Probe orb (AlienEnemyProjectile). After `split_distance` metres the orb splits
## into two shots `split_angle` degrees either side of its path. Telegraph: during the last `warn_seconds` before the
## split the orb swells and flashes, so the two new lanes never appear by surprise.

var projectile_scene: PackedScene
var split_distance := 4.0
var split_angle := 24.0
var split_speed := 5.6
var split_damage := 6
var warn_seconds := 0.45
var attacker: Node
var split_done := false
var _travelled := 0.0
var _base_scale := Vector3.ONE


func _ready() -> void:
	_base_scale = (get_parent() as Node3D).scale


func _physics_process(delta: float) -> void:
	var orb := get_parent() as AlienEnemyProjectile
	if orb == null or split_done:
		return
	_travelled += orb.speed * delta
	var left := (split_distance - _travelled) / maxf(orb.speed, 0.01)
	if left <= warn_seconds:
		var pulse := 1.0 + 0.35 * (1.0 - left / warn_seconds) + 0.12 * sin(left * 40.0)
		orb.scale = _base_scale * pulse
	if _travelled >= split_distance:
		_split(orb)


func _split(orb: AlienEnemyProjectile) -> void:
	split_done = true
	var parent := orb.get_parent()
	for side in [-1.0, 1.0]:
		var direction := orb.travel_direction.rotated(Vector3.BACK, deg_to_rad(split_angle * side))
		BeeEnemyPatterns.spawn_shot(parent, projectile_scene, orb.global_position, direction, split_damage, split_speed, attacker if is_instance_valid(attacker) else null) # The Probe may be dead by now.
	BeeCombatVFX.spawn(parent, orb.global_position, &"tech_hit", Vector3.LEFT, 0.6)
	orb.hitbox.set_enabled(false)
	orb.queue_free()
