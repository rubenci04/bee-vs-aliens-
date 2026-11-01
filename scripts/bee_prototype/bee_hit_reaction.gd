extends Node
## Tanda U · B y C — cómo reacciona Bee a un golpe (solo Nivel 1). No cambia la vida ni el daño de nada:
##   - HIT_INVULN_SECONDS de invulnerabilidad para TODO daño (HealthComponent.hit_protected; Bee parpadea en bee_visual);
##   - retroceso de KNOCKBACK_DISTANCE en KNOCKBACK_SECONDS, alejándose de lo que le pegó (dentro de los límites de vuelo);
##   - chispa cian del implante (la sacudida y el flash ya existen en BeeLevel01Juice y HitFlash3D);
##   - con poca vida el implante chisporrotea cada LOW_HP_SPARK_EVERY s, sin alarma sonora.
const S := preload("res://scripts/game/bee_expression_settings.gd")

signal hurt(first: bool) # Para las frases: el primer golpe de la partida.
signal low_health

var bee: BeePlayer
var protect_left := 0.0
var knock_left := 0.0
var knock_direction := Vector3.ZERO
var hits := 0
var spark_clock := 0.0
var _was_low := false


static func attach(stage: Node, player: BeePlayer) -> Node:
	if not S.HIT_REACTION_ENABLED or player == null:
		return null
	var reaction: Node = (load("res://scripts/bee_prototype/bee_hit_reaction.gd") as GDScript).new()
	reaction.name = "BeeHitReaction"
	reaction.set("bee", player)
	stage.add_child(reaction)
	return reaction


func _ready() -> void:
	bee.health.health_changed.connect(_on_health_changed)


func _on_health_changed(current: int, _maximum: int, change: int) -> void:
	if change >= 0 or current <= 0:
		return
	hits += 1
	hurt.emit(hits == 1)
	protect_left = S.HIT_INVULN_SECONDS
	bee.health.hit_protected = true
	var from: Vector3 = bee.get_meta("last_hit_from", bee.global_position + Vector3(1.0, 0.0, 0.0))
	knock_direction = Vector3(bee.global_position.x - from.x, bee.global_position.y - from.y, 0.0).normalized()
	if knock_direction == Vector3.ZERO:
		knock_direction = Vector3.LEFT
	knock_left = S.KNOCKBACK_SECONDS
	_spark(S.HIT_SPARK_SCALE)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(bee):
		return
	if protect_left > 0.0:
		protect_left -= delta
		if protect_left <= 0.0:
			bee.health.hit_protected = false
	if knock_left > 0.0 and not bee.is_defeated:
		var step := minf(delta, knock_left)
		knock_left -= step
		var moved := bee.global_position + knock_direction * (S.KNOCKBACK_DISTANCE / S.KNOCKBACK_SECONDS) * step
		bee.global_position = Vector3(clampf(moved.x, bee.flight_min.x, bee.flight_max.x), clampf(moved.y, bee.flight_min.y, bee.flight_max.y), moved.z)
	var low := bee.health.current_health > 0 and float(bee.health.current_health) < float(bee.health.max_health) * S.LOW_HP_RATIO
	if low and not _was_low:
		low_health.emit()
	_was_low = low
	if low and not bee.is_defeated:
		spark_clock -= delta
		if spark_clock <= 0.0:
			spark_clock = S.LOW_HP_SPARK_EVERY
			_spark(S.LOW_HP_SPARK_SCALE)
	else:
		spark_clock = 0.0


func _spark(size: float) -> void:
	var visual := bee.get_node_or_null("VisualRoot/BeeVisual")
	var socket: Node3D = visual.get("helmet_socket") if visual != null else null
	var at := socket.global_position if is_instance_valid(socket) else bee.global_position + Vector3(0.0, 0.3, 0.0)
	BeeCombatVFX.spawn(bee.get_parent(), at, &"tech_hit", Vector3.UP, size)
