class_name AlienMortarShell
extends Node3D
## COMBAT VARIETY 01: the ground turret's mortar. A cyan shell flies a fixed parabola to a point on the ground that was
## marked when the turret started charging (the marker stays until impact), then leaves a short cyan energy puddle.
## Shell: one hit while flying. Puddle: low (ground to PUDDLE_HEIGHT), one hit, gone after PUDDLE_SECONDS.

const SHELL_RADIUS := 0.22
const PUDDLE_HEIGHT := 1.2
const COLOR := BeeGameSettings.DANGER_CYAN

var flight_time := 0.9
var apex := 2.6
var damage := 9
var puddle_damage := 6
var puddle_radius := 1.0
var puddle_seconds := 1.4
var ground_y := -0.2
var landed := false
var attacker: Node

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _shell: MeshInstance3D
var _shell_box: DamageHitbox3D
var _marker: MeshInstance3D
var _puddle_left := 0.0


## `marker` (optional) is the ground warning created by the turret at the start of its charge; the shell owns it now.
func launch(from: Vector3, to: Vector3, marker: MeshInstance3D) -> void:
	add_to_group("alien_projectiles")
	add_to_group("alien_mortar")
	_from = Vector3(from.x, from.y, 0.0)
	_to = Vector3(to.x, ground_y, 0.0)
	_marker = marker
	_shell = BeeAttackVisuals.sphere(self, _from, SHELL_RADIUS, COLOR)
	var sphere := SphereShape3D.new()
	sphere.radius = SHELL_RADIUS * 0.8
	_shell_box = BeeAttackVisuals.hazard_area(self, attacker, damage, sphere)
	_shell_box.top_level = true
	_shell_box.global_position = _from
	_shell_box.set_enabled(true)
	_shell_box.hit_confirmed.connect(func(_h: DamageHurtbox3D, _d: int): _shell_box.set_enabled(false))


func shell_position() -> Vector3:
	var t := clampf(_t / flight_time, 0.0, 1.0)
	var p := _from.lerp(_to, t)
	p.y += 4.0 * apex * t * (1.0 - t) # Parabola peaking `apex` m above the straight line.
	return p


func _physics_process(delta: float) -> void:
	if not landed:
		_t += delta
		var p := shell_position()
		_shell.global_position = p
		_shell_box.global_position = p
		if _t >= flight_time:
			_land()
		return
	_puddle_left -= delta
	if _puddle_left <= 0.0:
		queue_free()


func _land() -> void:
	landed = true
	_shell_box.set_enabled(false)
	_shell.hide()
	if _marker != null and is_instance_valid(_marker):
		_marker.queue_free()
	BeeCombatVFX.spawn(get_parent(), _to + Vector3(0, 0.2, 0), &"tech_death", Vector3.UP, 0.7)
	var pool := BeeAttackVisuals.ground_disc(self, _to + Vector3(0, 0.04, 0), puddle_radius, Color(COLOR, 0.55))
	pool.name = "EnergyPuddle"
	var box := BoxShape3D.new()
	box.size = Vector3(puddle_radius * 1.8, PUDDLE_HEIGHT, 1.0)
	var area := BeeAttackVisuals.hazard_area(self, attacker if is_instance_valid(attacker) else null, puddle_damage, box) # The turret may be dead by now.
	area.name = "PuddleHitbox"
	area.top_level = true
	area.global_position = _to + Vector3(0, PUDDLE_HEIGHT * 0.5, 0)
	area.set_enabled(true)
	_puddle_left = puddle_seconds
	var fade := create_tween()
	fade.tween_interval(puddle_seconds * 0.6)
	fade.tween_property(pool, "scale", Vector3(0.2, 1.0, 0.12), puddle_seconds * 0.4)


func _exit_tree() -> void:
	if _marker != null and is_instance_valid(_marker):
		_marker.queue_free()
