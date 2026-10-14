class_name TarantulaWebNet
extends Node3D
## LOTE 15 · ETAPA 5.3 — the tarantula's TRAPPING NET (inspired by the hanging spiders). The boss warns WARNING s with a silk line
## from its mouth to Bee (locked when the warning ends), then this net flies along the line. If it touches Bee she is STUCK for up
## to TRAP_SECONDS: she can shoot but not move, roll or lunge. She breaks free sooner by shooting (every tap or burst tears one
## piece: TEARS_NEEDED) or by pressing the movement keys repeatedly (STRUGGLES_NEEDED presses). After she is free the boss grants
## GRACE_SECONDS in which no net can trap her again (nothing chains the trap). The roll destroys a flying net (common shot rule).

const WARNING := 0.5
const SPEED := 7.5
const LIFETIME := 2.6
const HIT_RADIUS := 0.55
const TRAP_SECONDS := 2.0
const TEARS_NEEDED := 4 ## Normal; Easy needs one less.
const STRUGGLES_NEEDED := 8 ## Normal; Easy needs two less.
const GRACE_SECONDS := 1.5
const SILK := Color(0.96, 0.96, 0.9, 0.9)

var boss: Node
var bee: BeePlayer
var direction := Vector3.LEFT
var trapping := false
var trapped_seconds := 0.0
var freed_by := &"" # &"shots", &"struggle", &"time" (tests / report).
var _life := 0.0
var _tears_from := 0
var _struggles_from := 0
var _ball: Node3D


static func launch(parent: Node, owner_boss: Node, target: BeePlayer, origin: Vector3, dir: Vector3) -> TarantulaWebNet:
	var net := TarantulaWebNet.new()
	net.name = "TarantulaWebNet"
	net.boss = owner_boss
	net.bee = target
	net.direction = Vector3(dir.x, dir.y, 0.0).normalized()
	net.top_level = true
	net.add_to_group("tarantula_hazards")
	parent.add_child(net)
	net.global_position = Vector3(origin.x, origin.y, 0.0)
	net._build()
	return net


static func tears_needed() -> int:
	return TEARS_NEEDED - (1 if BeeGameSettings.difficulty == BeeGameSettings.EASY else 0)


static func struggles_needed() -> int:
	return STRUGGLES_NEEDED - (2 if BeeGameSettings.difficulty == BeeGameSettings.EASY else 0)


func _build() -> void:
	_ball = Node3D.new()
	add_child(_ball)
	var ring := BeeAttackVisuals.ring(_ball, global_position, 0.38, 0.22, SILK)
	ring.top_level = false
	ring.position = Vector3.ZERO
	for angle in [0.0, 60.0, 120.0]:
		var strand := BeeAttackVisuals.line(_ball, Vector3.ZERO, Vector3.ZERO, 0.04, SILK)
		strand.top_level = false
		strand.position = Vector3.ZERO
		strand.rotation = Vector3(0.0, 0.0, deg_to_rad(angle))
		strand.scale = Vector3(0.8, 1.0, 1.0)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(bee):
		queue_free()
		return
	if trapping:
		_hold(delta)
		return
	_life += delta
	global_position += direction * SPEED * delta
	_ball.rotation.z += delta * 5.0
	var gap := Vector2(bee.global_position.x - global_position.x, bee.global_position.y - global_position.y)
	if gap.length() <= HIT_RADIUS and not bee.is_defeated:
		if bee.is_rolling:
			bee.absorb_shot() # The roll tears a flying net like any common shot.
			_poof()
			return
		if bee.health.invulnerable or bee.web_locked or (boss != null and is_instance_valid(boss) and boss.has_method("web_immune") and bool(boss.call("web_immune"))):
			_poof()
			return
		_trap()
		return
	if _life >= LIFETIME:
		queue_free()


func _trap() -> void:
	trapping = true
	bee.web_locked = true
	_tears_from = bee.fire_triggers()
	_struggles_from = bee.web_struggles
	_ball.scale = Vector3.ONE * 1.9
	BeeAudio.play(get_parent(), &"spider_retract", global_position, 0.8)
	if boss != null and is_instance_valid(boss) and boss.has_method("on_web_trapped"):
		boss.call("on_web_trapped", self)


func progress() -> float:
	if not trapping or not is_instance_valid(bee):
		return 0.0
	var tears := float(bee.fire_triggers() - _tears_from) / float(tears_needed())
	var tugs := float(bee.web_struggles - _struggles_from) / float(struggles_needed())
	return tears + tugs


func _hold(delta: float) -> void:
	trapped_seconds += delta
	global_position = bee.global_position
	var done := progress()
	_ball.scale = Vector3.ONE * lerpf(1.9, 0.9, clampf(done, 0.0, 1.0))
	_ball.rotation.z = sin(trapped_seconds * 30.0) * 0.12 * float(bee.web_struggles - _struggles_from > 0)
	if done >= 1.0:
		freed_by = &"shots" if bee.fire_triggers() - _tears_from >= bee.web_struggles - _struggles_from else &"struggle"
		release()
	elif trapped_seconds >= TRAP_SECONDS or bee.is_defeated:
		freed_by = &"time"
		release()


## Bee is free (or the fight ended): unlock her, start the boss's grace window and vanish.
func release() -> void:
	if trapping and is_instance_valid(bee):
		bee.web_locked = false
		if boss != null and is_instance_valid(boss) and boss.has_method("on_web_released"):
			boss.call("on_web_released", self)
	trapping = false
	_poof()


func dismiss() -> void:
	release()


func _poof() -> void:
	BeeCombatVFX.spawn(get_parent(), global_position, &"impact", Vector3.UP, 0.8)
	set_physics_process(false)
	queue_free()


func _exit_tree() -> void:
	if trapping and is_instance_valid(bee):
		bee.web_locked = false
