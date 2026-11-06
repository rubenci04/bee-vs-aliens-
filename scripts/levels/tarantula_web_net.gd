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
const TEARS_NEEDED := 3 ## T7i: 3 shot triggers frees her (was 4); Easy needs one less. A roll (pirueta) frees her at once.

const STRUGGLES_NEEDED := 8 ## Normal; Easy needs two less.
const GRACE_SECONDS := 1.0 ## T7i: was 1.5, so nets chain more often
const SILK := Color(0.96, 0.96, 0.9, 0.9)
## Mejora visual: telaraña fija. Aparece de a poco (mientras no está armada no atrapa), queda un rato y se va sola.
const STICKY_WARNING := 0.9
const STICKY_SECONDS := 13.0
const STICKY_WARN_TONE := 0.42 ## Brillo mientras se arma (no atrapa todavía).
const STICKY_ARMED_TONE := 0.86
const STICKY_RADIUS := 1.5 ## Tamaño del dibujo.
const STICKY_HIT_RADIUS := 0.95
const STICKY_SPOKE_WIDTH := 0.038 ## Medio ancho de los rayos: tiene que verse bien de lejos.
const STICKY_RING_WIDTH := 0.026 ## Medio ancho de los anillos.
const STICKY_SPOKES := 9
const STICKY_RINGS := 4

var boss: Node
var bee: BeePlayer
var direction := Vector3.LEFT
var trapping := false
var trapped_seconds := 0.0
var freed_by := &"" # &"shots", &"struggle", &"time" (tests / report).
var _life := 0.0
var _tears_from := 0
var _struggles_from := 0
var _rolls_from := 0
var _ball: Node3D
var sticky := false
var _web_material: StandardMaterial3D


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


static func place_sticky(parent: Node, owner_boss: Node, target: BeePlayer, at: Vector3) -> TarantulaWebNet:
	var net := TarantulaWebNet.new()
	net.name = "TarantulaStickyWeb"
	net.boss = owner_boss
	net.bee = target
	net.sticky = true
	net.top_level = true
	net.add_to_group("tarantula_hazards")
	net.add_to_group("tarantula_sticky_webs")
	parent.add_child(net)
	net.global_position = at
	net._build_sticky()
	BeeAudio.play(parent, &"spider_retract", at, 0.6)
	return net


## El dibujo de la telaraña: rayos y anillos finos, un solo mesh. Es blanco y brilla: de noche se ve bien.
func _build_sticky() -> void:
	var kit := BeeMeshKit.new()
	var points: Array[Vector3] = []
	for i in STICKY_SPOKES:
		var angle := TAU * float(i) / float(STICKY_SPOKES) + sin(float(i) * 2.1) * 0.12
		points.append(Vector3(cos(angle), sin(angle), 0.0))
	for i in STICKY_SPOKES:
		_web_strand(kit, Vector3.ZERO, points[i] * STICKY_RADIUS, STICKY_SPOKE_WIDTH)
		for ring_index in range(1, STICKY_RINGS + 1):
			var r := STICKY_RADIUS * float(ring_index) / float(STICKY_RINGS)
			_web_strand(kit, points[i] * r, points[(i + 1) % STICKY_SPOKES] * r * 0.97, STICKY_RING_WIDTH)
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in kit.lv:
		builder.set_normal(Vector3.BACK)
		builder.set_uv(Vector2.ZERO)
		builder.add_vertex(vertex)
	var mesh := builder.commit()
	_web_material = StandardMaterial3D.new()
	_web_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_web_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_web_material.albedo_color = Color(SILK.r, SILK.g, SILK.b, 1.0)
	var web := MeshInstance3D.new()
	web.mesh = mesh
	web.material_override = _web_material
	add_child(web)
	_ball = web


static func _web_strand(kit: BeeMeshKit, a: Vector3, b: Vector3, half_width: float) -> void:
	var side := Vector3(-(b - a).y, (b - a).x, 0.0).normalized() * half_width
	kit._push_sheet(a - side, a + side, b + side, Color.WHITE, Color.WHITE, Color.WHITE)
	kit._push_sheet(a - side, b + side, b - side, Color.WHITE, Color.WHITE, Color.WHITE)


## Telaraña fija: se enciende de a poco, atrapa si la tocan y se va sola. Rodar la rompe sin quedar atrapada.
func _sticky_step(delta: float) -> void:
	_life += delta
	var armed := _life >= STICKY_WARNING
	var fade_out := clampf((STICKY_SECONDS - _life) / 0.5, 0.0, 1.0)
	# Crece mientras se arma y se encoge al irse. Durante el aviso se ve apagada: armada, blanca.
	var tone: float = STICKY_ARMED_TONE if armed else STICKY_WARN_TONE
	_web_material.albedo_color = Color(SILK.r * tone, SILK.g * tone, SILK.b * tone)
	_ball.scale = Vector3.ONE * maxf(0.001, (0.15 + 0.85 * smoothstep(0.0, STICKY_WARNING, _life)) * fade_out)
	_ball.rotation.z = sin(_life * 0.8) * 0.04
	if _life >= STICKY_SECONDS:
		queue_free()
		return
	if not armed or bee.is_defeated:
		return
	var gap := Vector2(bee.global_position.x - global_position.x, bee.global_position.y - global_position.y)
	if gap.length() > STICKY_HIT_RADIUS:
		return
	if bee.is_rolling:
		bee.absorb_shot()
		_poof()
	elif not (bee.health.invulnerable or bee.web_locked or (boss != null and is_instance_valid(boss) and boss.has_method("web_immune") and bool(boss.call("web_immune")))):
		_trap()


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
	if sticky:
		_sticky_step(delta)
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
	_rolls_from = bee.web_roll_presses
	_ball.scale = Vector3.ONE * 1.9
	BeeAudio.play(get_parent(), &"spider_retract", global_position, 0.8)
	if boss != null and is_instance_valid(boss) and boss.has_method("on_web_trapped"):
		boss.call("on_web_trapped", self)


func progress() -> float:
	if not trapping or not is_instance_valid(bee):
		return 0.0
	var tears := float(bee.fire_triggers() - _tears_from) / float(tears_needed())
	var tugs := float(bee.web_struggles - _struggles_from) / float(struggles_needed())
	var rolls := float(bee.web_roll_presses - _rolls_from) # T7i: the pirueta tears the whole net
	return tears + tugs + rolls


func _hold(delta: float) -> void:
	trapped_seconds += delta
	global_position = bee.global_position
	var done := progress()
	_ball.scale = Vector3.ONE * lerpf(1.9, 0.9, clampf(done, 0.0, 1.0))
	_ball.rotation.z = sin(trapped_seconds * 30.0) * 0.12 * float(bee.web_struggles - _struggles_from > 0)
	if done >= 1.0:
		if bee.web_roll_presses > _rolls_from:
			freed_by = &"roll"
		else:
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
