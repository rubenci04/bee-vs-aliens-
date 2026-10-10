class_name UfoBossMine
extends Node3D
## UFO BOSS v2 (combat variety 01): a floating "mine" thrown by the NODO ALIEN. It flies to its spot (TRAVEL), hangs still
## for `fuse` seconds while a warning ring shrinks from RING_START x the blast radius down to it (the blast radius is drawn as a
## faint disc the whole time), then explodes once in that radius. Harmless until the explosion.

const COLOR := Color(1.0, 0.35, 0.85)
const TRAVEL := 0.45
const BLAST_SECONDS := 0.15
const RING_START := 1.6 # Warning ring starts at 1.6x the blast radius.

var fuse := 2.0
var radius := 1.5
var damage := 12
var attacker: Node
var exploded := false
var hit_bee := false
var spawn_time := 0.0 # Seconds (engine ticks) when it was thrown; the boss test reads it.

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _body: MeshInstance3D
var _ring: MeshInstance3D
var _zone: MeshInstance3D
var _blast: DamageHitbox3D
var _blast_left := 0.0


func throw(from: Vector3, to: Vector3) -> void:
	add_to_group("ufo_boss_mines")
	spawn_time = Time.get_ticks_msec() / 1000.0
	_from = Vector3(from.x, from.y, 0.0)
	_to = Vector3(to.x, to.y, 0.0)
	_body = BeeAttackVisuals.sphere(self, _from, 0.26, COLOR)
	_body.name = "MineBody"


## Seconds until it explodes (travel + fuse) from now.
func time_to_blast() -> float:
	return maxf(0.0, TRAVEL + fuse - _t)


func _physics_process(delta: float) -> void:
	if exploded:
		_blast_left -= delta
		if _blast_left <= 0.0:
			queue_free()
		return
	_t += delta
	if _t < TRAVEL:
		var k := _t / TRAVEL
		_body.global_position = _from.lerp(_to, 1.0 - pow(1.0 - k, 2.0))
		return
	if _ring == null:
		_body.global_position = _to
		_zone = BeeAttackVisuals.ring(self, _to, radius, 0.06, Color(COLOR, 0.35))
		_zone.name = "BlastRadius"
		_ring = BeeAttackVisuals.ring(self, _to, radius * RING_START, 0.05, Color(1.0, 0.9, 0.3, 0.75))
		_ring.name = "WarningRing"
	var left := clampf(1.0 - (_t - TRAVEL) / fuse, 0.0, 1.0)
	var r := radius * (1.0 + (RING_START - 1.0) * left) # Shrinks to the drawn blast radius: it explodes when they meet.
	_ring.scale = Vector3(r, 1.0, r)
	_body.scale = Vector3.ONE * (1.0 + 0.25 * sin(_t * lerpf(8.0, 30.0, 1.0 - left)))
	if _t >= TRAVEL + fuse:
		_explode()


func _explode() -> void:
	exploded = true
	_body.hide()
	if _ring != null:
		_ring.hide()
	if _zone != null:
		_zone.hide()
	var sphere := SphereShape3D.new()
	sphere.radius = radius * 0.9 # A little inside the drawn radius: the margin goes to the player.
	_blast = BeeAttackVisuals.hazard_area(self, attacker, damage, sphere)
	_blast.top_level = true
	_blast.global_position = _to
	_blast.hit_confirmed.connect(func(_h: DamageHurtbox3D, _d: int): hit_bee = true)
	_blast.set_enabled(true)
	_blast_left = BLAST_SECONDS
	BeeCombatVFX.spawn(get_parent(), _to, &"bomb", Vector3.RIGHT, radius * 0.8)
	BeeAudio.play(get_parent(), &"tech_death", _to, 0.9)


## The boss died or Bee was defeated: no explosion.
func defuse() -> void:
	exploded = true
	if _blast != null:
		_blast.set_enabled(false)
	queue_free()


func freeze() -> void:
	set_physics_process(false)
